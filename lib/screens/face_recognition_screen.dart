import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_recog/Api/apiIntegration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FaceRecognitionScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> with TickerProviderStateMixin {
  late CameraController _controller;
  bool _isRecognizing = false;
  final Map<String, DateTime> _recognizedFaces = {};
  bool _isAttendanceStarted = false;
  DateTime? _sessionStartTime;
  final int _attendanceInterval = 1; // minutes
  List<Map<String, dynamic>> _currentFaces = [];
  Timer? _recognitionTimer;
  Timer? _sessionTimer;
  bool _isCameraInitialized = false;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(minutes: _attendanceInterval),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      await _controller.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  void _startAttendance() {
    if (!_isCameraInitialized) return;

    setState(() {
      _isAttendanceStarted = true;
      _sessionStartTime = DateTime.now();
      _recognizedFaces.clear();
      _currentFaces.clear();
    });

    // Reset and start the animation controller
    _timerController.reset();
    _timerController.forward();

    // Start periodic recognition every 2 seconds
    _recognitionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isAttendanceStarted) {
        _recognizeFaces();
      }
    });

    // Auto-stop after attendance interval
    _sessionTimer = Timer(Duration(minutes: _attendanceInterval), () {
      if (_isAttendanceStarted) {
        _stopAttendance();
      }
    });
  }

  Future<void> _recognizeFaces() async {
    if (!_controller.value.isInitialized || _isRecognizing || !_isAttendanceStarted) return;
    
    setState(() => _isRecognizing = true);
    
    try {
      final image = await _controller.takePicture();
      final response = await ApiService.recognizeFace(File(image.path));
      
      if (response.success && mounted) {
        List<Map<String, dynamic>> currentFrameFaces = [];
        
        for (var result in response.data?['results'] ?? []) {
          if (result['status'] == 'recognized' || result['status'] == 'detected') {
            final name = result['status'] == 'recognized' ? result['name'] : 'UNKNOWN';
            final now = DateTime.now();
            
            currentFrameFaces.add({
              'name': name,
              'position': result['position'],
              'isRecognized': result['status'] == 'recognized',
              'isNew': !_recognizedFaces.containsKey(name),
            });
            
            if (result['status'] == 'recognized' && 
                (!_recognizedFaces.containsKey(name) || 
                now.difference(_recognizedFaces[name]!) > const Duration(seconds: 30))) {
              
              final attendanceResponse = await ApiService.markAttendance(name, _sessionStartTime!);
              
              if (attendanceResponse.success && mounted) {
                _recognizedFaces[name] = now;
              }
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _currentFaces = currentFrameFaces;
          });
        }
      }
    } catch (e) {
      debugPrint('Face recognition error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRecognizing = false);
      }
    }
  }

  void _stopAttendance() {
    _recognitionTimer?.cancel();
    _sessionTimer?.cancel();
    _timerController.stop();
    
    if (mounted) {
      setState(() {
        _isAttendanceStarted = false;
        _isRecognizing = false;
      });
      _showAttendanceSummary();
    }
  }

  void _showAttendanceSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Session Time: ${DateFormat('hh:mm a').format(_sessionStartTime!)}'),
              const SizedBox(height: 10),
              Text('Total Present: ${_recognizedFaces.length}'),
              const SizedBox(height: 10),
              const Text('Recognized Faces:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._recognizedFaces.entries.map((entry) => 
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(entry.key),
                  subtitle: Text(DateFormat('hh:mm a').format(entry.value)),
                )
              ).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Option to export/save attendance
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceBoxes() {
    return Stack(
      children: _currentFaces.map((face) {
        final position = face['position'];
        final isRecognized = face['isRecognized'];
        final name = face['name'];
        final isNew = face['isNew'];
        
        final boxColor = isRecognized ? (isNew ? Colors.green : Colors.blue) : Colors.red;
        final labelColor = isRecognized ? Colors.white : Colors.black;
        final labelBackground = isRecognized ? boxColor.withOpacity(0.7) : Colors.yellow.withOpacity(0.7);
        
        return Positioned(
          left: position['left'] * MediaQuery.of(context).size.width,
          top: position['top'] * MediaQuery.of(context).size.height,
          width: position['width'] * MediaQuery.of(context).size.width,
          height: position['height'] * MediaQuery.of(context).size.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: boxColor,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: labelBackground,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isRecognized && isNew)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Chip(
                      label: Text('MARKED'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionTimer() {
    if (!_isAttendanceStarted || _sessionStartTime == null) {
      return const SizedBox();
    }

    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        final elapsed = Duration(milliseconds: (_timerController.value * _attendanceInterval * 60 * 1000).round());
        final remaining = Duration(minutes: _attendanceInterval) - elapsed;
        final seconds = remaining.inSeconds.clamp(0, _attendanceInterval * 60);
        final progressValue = _timerController.value;

        return Column(
          children: [
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining.inSeconds > 10 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time remaining: ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: remaining.inSeconds > 10 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recognized: ${_recognizedFaces.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Instructions'),
                content: const Text(
                  'The system will automatically detect and recognize faces.\n\n'
                  '1. Position yourself clearly in front of the camera\n'
                  '2. Ensure good lighting\n'
                  '3. Remove sunglasses or hats\n'
                  '4. Attendance will be automatically recorded\n\n'
                  'Session duration: 1 minute',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),
                      _buildFaceBoxes(),
                      if (_isRecognizing)
                        const CircularProgressIndicator(),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing camera...'),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSessionTimer(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isAttendanceStarted ? _stopAttendance : _startAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAttendanceStarted ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isAttendanceStarted ? 'STOP ATTENDANCE' : 'START ATTENDANCE',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    _sessionTimer?.cancel();
    _timerController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
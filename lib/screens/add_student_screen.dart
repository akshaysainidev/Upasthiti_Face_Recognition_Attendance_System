import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_recog/Api/face_embedding_service.dart';
import 'package:face_recog/Custom_Widget/custom_academic_info_widget.dart';
import 'package:face_recog/Custom_Widget/custom_appbar.dart';
import 'package:face_recog/Custom_Widget/custom_button.dart';
import 'package:face_recog/Custom_Widget/custom_toast.dart';
import 'package:face_recog/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_recog/Api/apiIntegration.dart';

class AddStudentScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AddStudentScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> with WidgetsBindingObserver {
  // Camera and Face Embedding
  CameraController? _controller;
  late FaceEmbeddingService _faceEmbeddingService;
  bool _isCameraReady = false;
  bool _isCameraError = false;
  bool _isEmbeddingReady = false;
  bool _isLoading = true;
  bool _hasCameraPermission = false;

  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // State
  bool _isCapturing = false;
  bool _isRegistering = false;
  File? _capturedImage;
  String? _sectionId;
  String? _courseId;
  String? _yearId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _nameController.dispose();
    _rollNoController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _faceEmbeddingService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // 1. Initialize Face Embedding Service
      _faceEmbeddingService = FaceEmbeddingService();
      await _faceEmbeddingService.initialize().then((_) {
        if (mounted) setState(() => _isEmbeddingReady = true);
      });

      // 2. Check and request camera permission
      await _checkCameraPermission();

      // 3. Initialize camera if permission granted
      if (_hasCameraPermission) {
        await _initializeCameraWithRetry(maxRetries: 3);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _isLoading = false;
        });
      }
      debugPrint('Initialization error: $e');
      showCustomToast(context, message: 'Initialization failed: $e');
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        setState(() => _hasCameraPermission = result.isGranted);
      } else {
        setState(() => _hasCameraPermission = true);
      }
    } catch (e) {
      debugPrint('Permission error: $e');
      setState(() => _hasCameraPermission = false);
    }
  }

  Future<void> _initializeCameraWithRetry({int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries && !_isCameraReady) {
      try {
        await _initializeCamera();
        if (_isCameraReady) break;
      } catch (e) {
        debugPrint('Camera initialization attempt ${attempt + 1} failed: $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
      attempt++;
    }

    if (!_isCameraReady && mounted) {
      setState(() {
        _isCameraError = true;
        _isLoading = false;
      });
      showCustomToast(context, message: 'Camera initialization failed');
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty || !_hasCameraPermission) {
      setState(() {
        _isCameraError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      if (_controller != null) {
        await _controller!.dispose();
      }

      _controller = CameraController(
        widget.cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _isCameraError = false;
        _isLoading = false;
      });
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.description}');
      setState(() {
        _isCameraReady = false;
        _isCameraError = true;
        _isLoading = false;
      });
      rethrow;
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraReady || _controller == null || _isCapturing) {
      showCustomToast(context, message: 'Camera is not ready');
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      setState(() => _capturedImage = File(image.path));
    } on CameraException catch (e) {
      debugPrint('Camera capture error: ${e.description}');
      showCustomToast(context, message: 'Error capturing image: ${e.description}');
    } catch (e) {
      debugPrint('Capture error: $e');
      showCustomToast(context, message: 'Error capturing image');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<List<double>> _extractFaceEmbedding(File imageFile) async {
    if (!_isEmbeddingReady) {
      throw Exception('Face embedding service not initialized');
    }

    try {
      // Validate image file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate image is readable
      final imageSize = await imageFile.length();
      if (imageSize <= 0) {
        throw Exception('Image file is empty or corrupted');
      }

      // Extract embedding
      final embedding = await _faceEmbeddingService.extractFaceEmbedding(imageFile);
      
      // Validate embedding
      if (embedding.isEmpty) {
        throw Exception('No face detected in the image');
      }

      debugPrint('Face embedding extracted successfully (length: ${embedding.length})');
      return embedding;
    } catch (e) {
      debugPrint('Face embedding error: $e');
      throw Exception('Failed to extract face features: ${e.toString()}');
    }
  }

  Future<void> _registerStudent() async {
    // Validate all required fields
    if (_nameController.text.isEmpty ||
        _rollNoController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _sectionId == null ||
        _courseId == null ||
        _yearId == null) {
      showCustomToast(context, message: 'Please fill all required fields');
      return;
    }

    if (_capturedImage == null) {
      showCustomToast(context, message: 'Please capture a photo first');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // 1. Extract face embedding
      final faceEmbedding = await _extractFaceEmbedding(_capturedImage!);
      debugPrint('Face embedding extracted successfully');

      // 2. Register with API
      final apiResponse = await ApiService.registerStudentWithFace(
        name: _nameController.text,
        rollNo: _rollNoController.text,
        dob: _dobController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        courseId: _courseId!,
        yearId: _yearId!,
        sectionId: _sectionId!,
        faceEmbedding: faceEmbedding,
        imagePath: _capturedImage!.path,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Registration failed');
      }

      // 3. Save locally to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final studentStrings = prefs.getStringList('students') ?? [];
      
      final newStudent = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'rollNo': _rollNoController.text,
        'dob': _dobController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'address': _addressController.text.isEmpty ? null : _addressController.text,
        'imagePath': _capturedImage!.path,
        'courseId': _courseId!,
        'yearId': _yearId!,
        'sectionId': _sectionId!,
        'faceEmbedding': faceEmbedding,
      };

      studentStrings.add(json.encode(newStudent));
      await prefs.setStringList('students', studentStrings);

      showCustomToast(context, message: 'Student registered successfully');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Registration error: $e');
      showCustomToast(context, message: 'Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Widget _buildCameraPreview() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (!_hasCameraPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text('Camera permission required'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                await _checkCameraPermission();
                if (_hasCameraPermission) {
                  await _initializeCameraWithRetry();
                }
              },
              child: Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_isCameraError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text('Camera initialization failed'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCameraWithRetry,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing camera...'),
          ],
        ),
      );
    }

    return CameraPreview(_controller!);
  }

  // ... (Keep all your existing UI building methods unchanged)
  // _buildTextField(), _buildDateField(), _selectDate(), etc.
  // ...

  void _onAcademicSelectionComplete(AcademicSelection selection) {
    setState(() {
      _sectionId = selection.sectionId;
      _courseId = selection.courseId;
      _yearId = selection.yearId;
    });
    
    if (_capturedImage != null) {
      _registerStudent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Add New Student"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Register New Student',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _capturedImage != null
                    ? Image.file(_capturedImage!, fit: BoxFit.cover)
                    : _buildCameraPreview(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CustomButton(
                text: "Capture Photo",
                onPressed: _isCameraReady ? _captureImage : null,
                isLoading: _isCapturing,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _rollNoController,
              label: 'Roll Number*',
              icon: Icons.confirmation_number,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name*',
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            _buildDateField(),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone (Optional)',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _addressController,
              label: 'Address (Optional)',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            AcademicSelectionWidget(
              buttonText: "Register Student",
              onSelectionComplete: _onAcademicSelectionComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kPrimaryColor),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
        prefixIcon: Icon(icon, color: kPrimaryColor),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: 'Date of Birth*',
        labelStyle: TextStyle(color: kPrimaryColor),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
        prefixIcon: Icon(Icons.calendar_today, color: kPrimaryColor),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_month, color: kPrimaryColor),
          onPressed: () => _selectDate(context),
        ),
      ),
    );
  }
}
// import 'package:camera/camera.dart';
// import 'package:face_recog/Custom_Widget/custom_academic_info_widget.dart';
// import 'package:face_recog/constants/constants.dart';
// import 'package:face_recog/screens/add_student_screen.dart';
// import 'package:flutter/material.dart';

// class StudentsTab extends StatefulWidget {
//   const StudentsTab({Key? key}) : super(key: key);

//   @override
//   _StudentsTabState createState() => _StudentsTabState();
// }

// class _StudentsTabState extends State<StudentsTab> {
//   List<String> _students = [];
//   List<String> _filteredStudents = [];
//   bool _isLoading = false;
//   bool _showPlaceholder = true;
//   final TextEditingController _searchController = TextEditingController();
//   Set<int> _expandedIndices = {};

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadStudents() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Simulate API call
//       await Future.delayed(Duration(seconds: 2));

//       final students = [
//         'John Doe',
//         'Jane Smith',
//         'Robert Johnson',
//         'Emily Davis',
//         'Michael Wilson',
//       ];

//       setState(() {
//         _students = List.from(students);
//         _filteredStudents = List.from(students);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load students: $e')),
//       );
//     }
//   }

//   void _filterStudents(String query) {
//     setState(() {
//       _filteredStudents = _students
//           .where((student) =>
//               student.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }

//   void _toggleExpand(int index) {
//     setState(() {
//       if (_expandedIndices.contains(index)) {
//         _expandedIndices.remove(index);
//       } else {
//         _expandedIndices.add(index);
//       }
//     });
//   }

//   Widget _buildStudentDetails(String student) {
//     final attendance = {
//       'Math': '85%',
//       'Science': '92%',
//       'English': '78%',
//       'History': '88%',
//     };

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
//           SizedBox(height: 8),
//           ...attendance.entries
//               .map(
//                 (subject) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(subject.key),
//                       Text(
//                         subject.value,
//                         style: TextStyle(color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//               .toList(),
//           Divider(),
//           Text(
//             'Overall Performance',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: 0.86,
//             backgroundColor: Colors.grey[200],
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//           ),
//           SizedBox(height: 8),
//           Text('86% Overall', textAlign: TextAlign.center),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Academic Selection Widget
//               Container(
//                 padding: EdgeInsets.all(20),
//                 // height: 400,
//                 child: AcademicSelectionWidget(
//                   onSelectionComplete: (selection) {
//                     // When selection is complete, hide placeholder and load students
//                     setState(() {
//                       _showPlaceholder = false;
//                     });
//                     _loadStudents();
//                   },
//                 ),
//               ),
              
//               // Main Content Area
//               Container(
//                 // color: Colors.blue,
//                 height: 600, // Adjust height
//                 child: Stack(
//                   alignment: Alignment.topCenter,
//                   children: [
//                     // Loading Indicator (shown when loading)
//                     if (_isLoading)
//                       CircularProgressIndicator(color: kPrimaryColor),

//                     // SVG Placeholder with fade animation
//                     AnimatedOpacity(
//                       opacity: _showPlaceholder ? 1.0 : 0.0,
//                       duration: Duration(milliseconds: 500),
//                       child: Image.asset(
//                         'assets/images/img4.png',
//                         width: MediaQuery.of(context).size.width * 0.8,
//                         fit: BoxFit.contain,
//                       ),
//                     ),

                   
//                     // Main Content (shown after data loads)
//                     if (!_showPlaceholder && !_isLoading)
//                       Column(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: TextField(
//                               controller: _searchController,
//                               decoration: InputDecoration(
//                                 hintText: 'Search students...',
//                                 prefixIcon: Icon(
//                                   Icons.search,
//                                   color: Colors.green[800],
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                   borderSide: BorderSide(color: Colors.green),
//                                 ),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                   borderSide: BorderSide(color: Colors.green),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                   borderSide: BorderSide(
//                                     color: Colors.green,
//                                     width: 2.0,
//                                   ),
//                                 ),
//                               ),
//                               onChanged: _filterStudents,
//                             ),
//                           ),
//                           Expanded(
//                             child: ListView.builder(
//                               padding: const EdgeInsets.symmetric(horizontal: 16),
//                               itemCount: _filteredStudents.length,
//                               itemBuilder: (context, index) {
//                                 final student = _filteredStudents[index];
//                                 final isExpanded = _expandedIndices.contains(index);

//                                 return Card(
//                                   color: const Color.fromARGB(228, 255, 255, 255),
//                                   margin: const EdgeInsets.only(bottom: 16),
//                                   elevation: 2,
//                                   child: Column(
//                                     children: [
//                                       ListTile(
//                                         onTap: () => _toggleExpand(index),
//                                         leading: CircleAvatar(
//                                           backgroundColor: Colors.green.shade100,
//                                           child: Text(
//                                             student[0],
//                                             style: TextStyle(
//                                               color: kPrimaryColor,
//                                             ),
//                                           ),
//                                         ),
//                                         title: Text(student),
//                                         trailing: Icon(
//                                           isExpanded
//                                               ? Icons.expand_less
//                                               : Icons.expand_more,
//                                           color: kPrimaryColor,
//                                         ),
//                                       ),
//                                       if (isExpanded) _buildStudentDetails(student),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       // In your StudentsTab class, update the floating action button:
// floatingActionButton: !_showPlaceholder && !_isLoading
//     ? FloatingActionButton(
//         onPressed: () async {
//           final cameras = await availableCameras();
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddStudentScreen(cameras: cameras),
//             ),
//           );
          
//           if (result == true) {
//             // Refresh the student list if a new student was added
//             _loadStudents();
//           }
//         },
//         backgroundColor: kPrimaryColor,
//         child: const Icon(Icons.person_add, color: Colors.white),
//       )
//     : null,
//     );
//   }
// }



import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_recog/Custom_Widget/custom_academic_info_widget.dart';
import 'package:face_recog/constants/constants.dart';
import 'package:face_recog/screens/add_student_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final String id;
  final String name;
  final String rollNo;
  final String dob;
  final String? email;
  final String? phone;
  final String? address;
  final String? imagePath;
  final String courseId;
  final String yearId;
  final String sectionId;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.dob,
    this.email,
    this.phone,
    this.address,
    this.imagePath,
    required this.courseId,
    required this.yearId,
    required this.sectionId,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      rollNo: map['rollNo'],
      dob: map['dob'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      imagePath: map['imagePath'],
      courseId: map['courseId'],
      yearId: map['yearId'],
      sectionId: map['sectionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'dob': dob,
      'email': email,
      'phone': phone,
      'address': address,
      'imagePath': imagePath,
      'courseId': courseId,
      'yearId': yearId,
      'sectionId': sectionId,
    };
  }
}

class StudentsTab extends StatefulWidget {
  const StudentsTab({Key? key}) : super(key: key);

  @override
  _StudentsTabState createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;
  bool _showPlaceholder = true;
  final TextEditingController _searchController = TextEditingController();
  Set<int> _expandedIndices = {};
  AcademicSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentStrings = prefs.getStringList('students') ?? [];
      
      setState(() {
        _students = studentStrings
            .map((str) => Student.fromMap(Map<String, dynamic>.from(json.decode(str))))
            .toList();
        _filterStudentsBySelection();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
  }

  void _filterStudentsBySelection() {
    if (_currentSelection == null) {
      _filteredStudents = [];
      return;
    }

    _filteredStudents = _students.where((student) {
      return student.courseId == _currentSelection!.courseId &&
          student.yearId == _currentSelection!.yearId &&
          student.sectionId == _currentSelection!.sectionId;
    }).toList();
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _filteredStudents
          .where((student) =>
              student.name.toLowerCase().contains(query.toLowerCase()) ||
              student.rollNo.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  Widget _buildStudentDetails(Student student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (student.imagePath != null)
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: FileImage(File(student.imagePath!)),
              ),
            ),
          SizedBox(height: 16),
          Text('Roll No: ${student.rollNo}'),
          if (student.dob.isNotEmpty) Text('DOB: ${student.dob}'),
          if (student.email != null) Text('Email: ${student.email}'),
          if (student.phone != null) Text('Phone: ${student.phone}'),
          if (student.address != null) Text('Address: ${student.address}'),
          Divider(),
          Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          // Add your attendance subjects here
          Divider(),
          Text(
            'Overall Performance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.86,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 8),
          Text('86% Overall', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Academic Selection Widget
              Container(
                padding: EdgeInsets.all(20),
                child: AcademicSelectionWidget(
                  onSelectionComplete: (selection) {
                    setState(() {
                      _currentSelection = selection;
                      _showPlaceholder = false;
                      _filterStudentsBySelection();
                    });
                  },
                ),
              ),
              
              // Main Content Area
              Container(
                height: 600,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (_isLoading)
                      Center(child: CircularProgressIndicator(color: kPrimaryColor)),

                    if (_showPlaceholder)
                      AnimatedOpacity(
                        opacity: _showPlaceholder ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 500),
                        child: Image.asset(
                          'assets/images/img4.png',
                          width: MediaQuery.of(context).size.width * 0.8,
                          fit: BoxFit.contain,
                        ),
                      ),

                    if (!_showPlaceholder && !_isLoading)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search students...',
                                prefixIcon: Icon(Icons.search, color: Colors.green[800]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.green,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              onChanged: _filterStudents,
                            ),
                          ),
                          Expanded(
                            child: _filteredStudents.isEmpty
                                ? Center(
                                    child: Text(
                                      'No students found',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _filteredStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _filteredStudents[index];
                                      final isExpanded = _expandedIndices.contains(index);

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        elevation: 2,
                                        child: Column(
                                          children: [
                                            ListTile(
                                              onTap: () => _toggleExpand(index),
                                              leading: student.imagePath != null
                                                  ? CircleAvatar(
                                                      backgroundImage: FileImage(File(student.imagePath!)),
                                                    )
                                                  : CircleAvatar(
                                                      backgroundColor: Colors.green.shade100,
                                                      child: Text(
                                                        student.name[0],
                                                        style: TextStyle(color: kPrimaryColor),
                                                      ),
                                                    ),
                                              title: Text(student.name),
                                              subtitle: Text('Roll No: ${student.rollNo}'),
                                              trailing: Icon(
                                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                                color: kPrimaryColor,
                                              ),
                                            ),
                                            if (isExpanded) _buildStudentDetails(student),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_showPlaceholder && !_isLoading
          ? FloatingActionButton(
              onPressed: () async {
                final cameras = await availableCameras();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStudentScreen(cameras: cameras,),
                  ),
                );
                
                if (result == true) {
                  _loadStudents();
                }
              },
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }
}


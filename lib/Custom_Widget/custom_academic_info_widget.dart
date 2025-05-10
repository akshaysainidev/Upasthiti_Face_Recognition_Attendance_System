// import 'package:flutter/material.dart';
// import 'package:face_recog/Api/apiIntegration.dart';
// import 'package:face_recog/Custom_Widget/custom_dropdown.dart';
// import 'package:face_recog/Custom_Widget/custom_button.dart';

// class AcademicSelection {
//   final String? courseId;
//   final String? courseName;
//   final String? yearId;
//   final String? yearName;
//   final String? sectionId;
//   final String? sectionName;

//   AcademicSelection({
//     this.courseId,
//     this.courseName,
//     this.yearId,
//     this.yearName,
//     this.sectionId,
//     this.sectionName,
//   });

//   bool get isComplete => courseId != null && yearId != null && sectionId != null;

//   AcademicSelection copyWith({
//     String? courseId,
//     String? courseName,
//     String? yearId,
//     String? yearName,
//     String? sectionId,
//     String? sectionName,
//   }) {
//     return AcademicSelection(
//       courseId: courseId ?? this.courseId,
//       courseName: courseName ?? this.courseName,
//       yearId: yearId ?? this.yearId,
//       yearName: yearName ?? this.yearName,
//       sectionId: sectionId ?? this.sectionId,
//       sectionName: sectionName ?? this.sectionName,
//     );
//   }
// }

// class AcademicSelectionWidget extends StatefulWidget {
//   final String schoolId;
//   final String buttonText;
//   final Function(AcademicSelection) onSelectionComplete;
//   final bool autoLoadInitialData;

//   const AcademicSelectionWidget({
//     required this.onSelectionComplete,
//     this.schoolId = "128b2f4a-25fd-4c8e-a797-aa2179292ef9",
//     this.buttonText = "Continue",
//     this.autoLoadInitialData = true,
//     Key? key,
//   }) : super(key: key);

//   @override
//   _AcademicSelectionWidgetState createState() => _AcademicSelectionWidgetState();
// }

// class _AcademicSelectionWidgetState extends State<AcademicSelectionWidget> {
//   late AcademicSelection _selection;
//   List<Map<String, dynamic>> _courses = [];
//   List<Map<String, dynamic>> _years = [];
//   List<Map<String, dynamic>> _sections = [];

//   @override
//   void initState() {
//     super.initState();
//     _selection = AcademicSelection();
//     if (widget.autoLoadInitialData) {
//       _loadCourses();
//     }
//   }

//   Future<void> _loadCourses() async {
//     _courses = await ApiService.getCoursesBySchool(widget.schoolId);
//     _years = [];
//     _sections = [];
//     if (mounted) setState(() {});
//   }

//   Future<void> _loadYears(String courseId) async {
//     _years = await ApiService.getYearsByCourse(courseId);
//     _sections = [];
//     if (mounted) setState(() {});
//   }

//   Future<void> _loadSections(String yearId) async {
//     _sections = await ApiService.getSectionsByYear(yearId);
//     if (mounted) setState(() {});
//   }

//   Map<String, dynamic>? _findMatch(List<Map<String, dynamic>> items, String? id, String? name) {
//     if (id == null || name == null) return null;
//     return items.firstWhere(
//       (item) => item['id'].toString() == id && item['name'].toString() == name,
//       orElse: () => {'id': null, 'name': null},
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 6,
//             offset: Offset(0, 2),
//           )
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Course Dropdown
//           CustomDropdown(
//             value: _findMatch(_courses, _selection.courseId, _selection.courseName),
//             items: _courses,
//             label: 'Course',
//             hint: 'Select Course',
//             onChanged: (value) async {
//               if (value != null) {
//                 await _loadYears(value['id'].toString());
//                 if (mounted) {
//                   setState(() {
//                     _selection = AcademicSelection(
//                       courseId: value['id'].toString(),
//                       courseName: value['name'].toString(),
//                     );
//                   });
//                 }
//               }
//             },
//           ),

//           // Year Dropdown
//           CustomDropdown(
//             value: _findMatch(_years, _selection.yearId, _selection.yearName),
//             items: _years,
//             label: 'Year',
//             hint: 'Select Year',
//             onChanged: (value) async {
//               if (value != null) {
//                 await _loadSections(value['id'].toString());
//                 if (mounted) {
//                   setState(() {
//                     _selection = _selection.copyWith(
//                       yearId: value['id'].toString(),
//                       yearName: value['name'].toString(),
//                       sectionId: null,
//                       sectionName: null,
//                     );
//                   });
//                 }
//               }
//             },
//           ),

//           // Section Dropdown
//           CustomDropdown(
//             value: _findMatch(_sections, _selection.sectionId, _selection.sectionName),
//             items: _sections,
//             label: 'Section',
//             hint: 'Select Section',
//             onChanged: (value) {
//               if (value != null && mounted) {
//                 setState(() {
//                   _selection = _selection.copyWith(
//                     sectionId: value['id'].toString(),
//                     sectionName: value['name'].toString(),
//                   );
//                 });
//               }
//             },
//           ),

//           // Submit Button
//           SizedBox(height:15),
//           CustomButton(
//             text: widget.buttonText,
//             onPressed: _selection.isComplete
//                 ? () => widget.onSelectionComplete(_selection)
//                 : null,
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:face_recog/Custom_Widget/custom_dropdown.dart';
import 'package:face_recog/Custom_Widget/custom_button.dart';

class AcademicSelection {
  final String? courseId;
  final String? courseName;
  final String? yearId;
  final String? yearName;
  final String? sectionId;
  final String? sectionName;

  AcademicSelection({
    this.courseId,
    this.courseName,
    this.yearId,
    this.yearName,
    this.sectionId,
    this.sectionName,
  });

  bool get isComplete => courseId != null && yearId != null && sectionId != null;

  AcademicSelection copyWith({
    String? courseId,
    String? courseName,
    String? yearId,
    String? yearName,
    String? sectionId,
    String? sectionName,
  }) {
    return AcademicSelection(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      yearId: yearId ?? this.yearId,
      yearName: yearName ?? this.yearName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
    );
  }
}

class AcademicSelectionWidget extends StatefulWidget {
  final String buttonText;
  final Function(AcademicSelection) onSelectionComplete;

  const AcademicSelectionWidget({
    required this.onSelectionComplete,
    this.buttonText = "Continue",
    Key? key,
  }) : super(key: key);

  @override
  _AcademicSelectionWidgetState createState() => _AcademicSelectionWidgetState();
}

class _AcademicSelectionWidgetState extends State<AcademicSelectionWidget> {
  late AcademicSelection _selection;
  
  // Static dummy data with explicit types
  final List<Map<String, dynamic>> _courses = [
    {'id': '1', 'name': 'Bachelor of Technology', 'duration': 4},
    {'id': '2', 'name': 'Master of Technology', 'duration': 2},
  ];

  final List<Map<String, dynamic>> _years = [
    {'id': '1', 'name': 'First Year', 'course_id': '1'},
    {'id': '2', 'name': 'Second Year', 'course_id': '1'},
    {'id': '3', 'name': 'First Year', 'course_id': '2'},
  ];

  final List<Map<String, dynamic>> _sections = [
    {'id': '1', 'name': 'Section A', 'year_id': '1', 'class_teacher': 'Dr. Smith'},
    {'id': '2', 'name': 'Section B', 'year_id': '1', 'class_teacher': 'Dr. Johnson'},
    {'id': '3', 'name': 'Section A', 'year_id': '2', 'class_teacher': 'Dr. Williams'},
  ];

  @override
  void initState() {
    super.initState();
    _selection = AcademicSelection();
  }

  List<Map<String, dynamic>> _getFilteredYears(String courseId) {
    return _years.where((year) => year['course_id'] == courseId).toList();
  }

  List<Map<String, dynamic>> _getFilteredSections(String yearId) {
    return _sections.where((section) => section['year_id'] == yearId).toList();
  }

  Map<String, dynamic>? _getSelectedItem(List<Map<String, dynamic>> items, String? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredYears = _selection.courseId != null 
        ? _getFilteredYears(_selection.courseId!)
        : <Map<String, dynamic>>[];
        
    final List<Map<String, dynamic>> filteredSections = _selection.yearId != null
        ? _getFilteredSections(_selection.yearId!)
        : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Course Dropdown
          CustomDropdown(
            value: _getSelectedItem(_courses, _selection.courseId),
            items: _courses,
            label: 'Course',
            hint: 'Select Course',
            onChanged: (value) {
              setState(() {
                _selection = AcademicSelection(
                  courseId: value?['id'],
                  courseName: value?['name'],
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Year Dropdown
          CustomDropdown(
            value: _getSelectedItem(filteredYears, _selection.yearId),
            items: filteredYears,
            label: 'Year',
            hint: _selection.courseId == null ? 'Select Course First' : 'Select Year',
            onChanged: (value) {
              setState(() {
                _selection = _selection.copyWith(
                  yearId: value?['id'],
                  yearName: value?['name'],
                  sectionId: null,
                  sectionName: null,
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Section Dropdown
          CustomDropdown(
            value: _getSelectedItem(filteredSections, _selection.sectionId),
            items: filteredSections,
            label: 'Section',
            hint: _selection.yearId == null ? 'Select Year First' : 'Select Section',
            onChanged: (value) {
              setState(() {
                _selection = _selection.copyWith(
                  sectionId: value?['id'],
                  sectionName: value?['name'],
                );
              });
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          CustomButton(
            text: widget.buttonText,
            onPressed: _selection.isComplete
                ? () => widget.onSelectionComplete(_selection)
                : null,
          ),
        ],
      ),
    );
  }
}



import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ApiResponse({required this.success, this.message = '', this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = "http://192.100.67.210:8000";
  static const int timeoutSeconds = 30;

  // Helper method for headers
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  // ======================
  // Face Recognition Endpoints
  // ======================

  static Future<Map<String, dynamic>> measureFacialFeatures(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/measure-face'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          imageFile.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw HttpException('Failed to measure facial features', statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Error measuring facial features: ${e.toString()}');
    }
  }

  static Future<ApiResponse> registerStudent({
    required String name,
    required String rollNo,
    required String dob,
    required String sectionId,
    required String courseId,
    required String yearId,
    required Map<String, dynamic> faceMeasurements,
    required File imageFile,
    String email = '',
    String phone = '',
    String address = '',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register-student'),
      );

      // Add text fields
      request.fields.addAll({
        'name': name,
        'roll_no': rollNo,
        'dob': dob,
        'email': email,
        'phone': phone,
        'address': address,
        'section_id': sectionId,
        'course_id': courseId,
        'year_id': yearId,
        'face_data': json.encode(faceMeasurements),
      });

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: basename(imageFile.path),
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(data);
      } else {
        return ApiResponse(success: false, message: data['message'] ?? 'Registration failed');
      }
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timed out');
    } on http.ClientException {
      return ApiResponse(success: false, message: 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> recognizeFace(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recognize-face'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          imageFile.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(json.decode(responseData));
      } else {
        return ApiResponse(success: false, message: 'Face recognition failed');
      }
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timed out');
    } on http.ClientException {
      return ApiResponse(success: false, message: 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // ======================
  // School Endpoints
  // ======================

  static Future<List<Map<String, dynamic>>> listSchools() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schools/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: timeoutSeconds));

      final data = json.decode(response.body);
      return (data['schools'] as List).map((school) {
        return {
          'name': school,
          'id': school,
        };
      }).toList();
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Failed to list schools: ${e.toString()}');
    }
  }

  // ======================
  // Course Endpoints
  // ======================

  static Future<List<Map<String, dynamic>>> getCoursesBySchool(String schoolId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schools/$schoolId/courses'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: timeoutSeconds));

      final data = json.decode(response.body);
      final courses = data['courses'] as List<dynamic>;

      return courses.map<Map<String, dynamic>>((course) {
        return {
          'name': course['name'],
          'id': course['id'],
          'duration': course['duration_years'],
        };
      }).toList();
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Failed to fetch courses: ${e.toString()}');
    }
  }

  // ======================
  // Year Endpoints
  // ======================

  static Future<List<Map<String, dynamic>>> getYearsByCourse(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId/years'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> years = data['years'];

        return years.map<Map<String, dynamic>>((year) {
          return {
            'name': year['year_name'].toString(),
            'id': year['id'].toString(),
          };
        }).toList();
      } else {
        throw HttpException('Failed to load years', statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Failed to fetch years: ${e.toString()}');
    }
  }

  // ======================
  // Section Endpoints
  // ======================

  static Future<List<Map<String, dynamic>>> getSectionsByYear(String yearId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/years/$yearId/sections'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: timeoutSeconds));

      final data = json.decode(response.body);
      final sections = data['sections'] as List;

      return sections.map<Map<String, dynamic>>((section) {
        return {
          'name': section['name'],
          'id': section['id'],
          'class_teacher': section['class_teacher'],
        };
      }).toList();
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Failed to fetch sections: ${e.toString()}');
    }
  }

  // ======================
  // Student Endpoints
  // ======================

  static Future<List<Map<String, dynamic>>> getStudentsBySection(String sectionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sections/$sectionId/students'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: timeoutSeconds));

      final data = json.decode(response.body);
      return (data['students'] as List).map((student) {
        return {
          'id': student['id'],
          'name': student['name'],
          'roll_no': student['roll_no'],
        };
      }).toList();
    } on TimeoutException {
      throw HttpException('Request timed out');
    } on http.ClientException {
      throw HttpException('Network error');
    } catch (e) {
      throw HttpException('Failed to fetch students: ${e.toString()}');
    }
  }

  // ======================
  // Attendance Endpoints
  // ======================

  static Future<ApiResponse> markAttendance(String name, DateTime sessionTime) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mark-attendance'),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'session_time': sessionTime.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: timeoutSeconds));

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timed out');
    } on http.ClientException {
      return ApiResponse(success: false, message: 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> registerStudentWithFace({
    required String name,
    required String rollNo,
    required String dob,
    required String? email,
    required String? phone,
    required String? address,
    required String courseId,
    required String yearId,
    required String sectionId,
    required List<double> faceEmbedding,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register_student_with_face/'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['roll_no'] = rollNo;
      request.fields['dob'] = dob;
      request.fields['course_id'] = courseId;
      request.fields['year_id'] = yearId;
      request.fields['section_id'] = sectionId;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['address'] = address;

      // Add image file
      var imageFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
      );
      request.files.add(imageFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['detail'] ?? 'Failed to register student',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Helper function to get basename of file
  static String basename(String path) {
    return path.split('/').last;
  }
}
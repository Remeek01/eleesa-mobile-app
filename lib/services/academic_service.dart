import 'dart:convert';
import 'package:http/http.dart' as http;

class AcademicService {
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api';

  Future<Map<String, dynamic>> fetchOverview({required String email, required String level}) async {
    final uri = Uri.parse(
      '$baseUrl/academic/overview?email=${Uri.encodeComponent(email)}&level=${Uri.encodeComponent(level)}',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Failed to load academic overview');
  }

  Future<List<Map<String, dynamic>>> fetchCourses() async {
    final res = await http
        .get(Uri.parse('$baseUrl/academic/courses'))
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(data['courses'] ?? []);
    }
    throw Exception(data['message'] ?? 'Failed to load courses');
  }

  Future<String> saveCourse(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/academic/courses'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data['message'] ?? 'Course saved.').toString();
    }
    throw Exception(data['message'] ?? 'Failed to save course');
  }

  Future<Map<String, dynamic>> fetchTimetableAndCalendar() async {
    final res = await http
        .get(Uri.parse('$baseUrl/academic/timetable'))
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Failed to load timetable');
  }

  Future<String> addTimetableSlot(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/academic/timetable'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data['message'] ?? 'Timetable updated.').toString();
    }
    throw Exception(data['message'] ?? 'Failed to add timetable slot');
  }

  Future<String> addCalendarEvent(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/academic/calendar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data['message'] ?? 'Calendar updated.').toString();
    }
    throw Exception(data['message'] ?? 'Failed to add calendar milestone');
  }

  Future<String> updateDepartmentInfo(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/academic/department-info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data['message'] ?? 'Department info updated.').toString();
    }
    throw Exception(data['message'] ?? 'Failed to update department info');
  }

  Future<String> updateStaffProfile(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/academic/staff-update'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data['message'] ?? 'Faculty card updated.').toString();
    }
    throw Exception(data['message'] ?? 'Failed to update faculty profile');
  }
}
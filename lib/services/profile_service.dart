import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api';

  Future<Map<String, dynamic>> fetchProfile(String email) async {
    final uri = Uri.parse('$baseUrl/profile?email=${Uri.encodeComponent(email)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  Future<String> saveProfile({
    required Map<String, dynamic> payload,
    void Function(String status)? onStatusChange,
  }) async {
    Timer? wakeupTimer;
    if (onStatusChange != null) {
      wakeupTimer = Timer(const Duration(seconds: 3), () {
        onStatusChange('Waking up ELEESA server & encrypting fields...');
      });
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/profile/save'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data['message'] ?? 'Profile saved.';
      }
      throw Exception(data['message'] ?? 'Failed to save profile');
    } finally {
      wakeupTimer?.cancel();
    }
  }

  Future<Map<String, dynamic>> fetchStudentsByLevel(String requesterEmail) async {
    final uri = Uri.parse(
      '$baseUrl/hub/students-by-level?requester_email=${Uri.encodeComponent(requesterEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load 4-level student database');
  }

  Future<List<Map<String, dynamic>>> fetchStaffDirectory(String requesterEmail) async {
    final uri = Uri.parse(
      '$baseUrl/hub/staff-directory?requester_email=${Uri.encodeComponent(requesterEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<Map<String, dynamic>>.from(data['staff'] ?? []);
    }
    throw Exception(data['message'] ?? 'Failed to load staff directory');
  }
}
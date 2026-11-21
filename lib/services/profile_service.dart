import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api';

  Future> fetchProfile(String email) async {
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

  Future<String> uploadAvatar({
    required String email,
    required String avatarData,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/profile/avatar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'avatar_data': avatarData,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['avatar_data'] ?? avatarData).toString();
    }
    throw Exception(data['message'] ?? 'Failed to update profile picture');
  }

  Future> fetchVisitorHub() async {
    final uri = Uri.parse('$baseUrl/public/visitor-hub');
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load visitor portal');
  }

  Future> fetchStudentsByLevel(String requesterEmail) async {
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

  Future<List>> fetchStaffDirectory(String requesterEmail) async {
    final uri = Uri.parse(
      '$baseUrl/hub/staff-directory?requester_email=${Uri.encodeComponent(requesterEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List>.from(data['staff'] ?? []);
    }
    throw Exception(data['message'] ?? 'Failed to load staff directory');
  }
}
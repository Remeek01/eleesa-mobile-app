import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef JsonMap = Map<String, dynamic>;
typedef JsonMapList = List<JsonMap>;

class ProfileService {
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api';

  Future<JsonMap> fetchProfile(String email) async {
    final uri = Uri.parse('$baseUrl/profile?email=${Uri.encodeComponent(email)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as JsonMap;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  Future<String> saveProfile({
    required JsonMap payload,
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

      final data = jsonDecode(response.body) as JsonMap;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (data['message'] ?? 'Profile saved.').toString();
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

    final data = jsonDecode(response.body) as JsonMap;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['avatar_data'] ?? avatarData).toString();
    }
    throw Exception(data['message'] ?? 'Failed to update profile picture');
  }

  Future<JsonMap> fetchVisitorHub() async {
    final uri = Uri.parse('$baseUrl/public/visitor-hub');
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as JsonMap;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load visitor portal');
  }

  Future<JsonMap> fetchStudentsByLevel(String requesterEmail) async {
    final uri = Uri.parse(
      '$baseUrl/hub/students-by-level?requester_email=${Uri.encodeComponent(requesterEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as JsonMap;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load 4-level student database');
  }

  Future<JsonMapList> fetchStaffDirectory(String requesterEmail) async {
    final uri = Uri.parse(
      '$baseUrl/hub/staff-directory?requester_email=${Uri.encodeComponent(requesterEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body) as JsonMap;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final rawStaff = data['staff'];
      final staffList = <JsonMap>[];
      if (rawStaff is Iterable) {
        for (final item in rawStaff) {
          if (item is Map) {
            staffList.add(JsonMap.from(item));
          }
        }
      }
      return staffList;
    }
    throw Exception(data['message'] ?? 'Failed to load staff directory');
  }
}
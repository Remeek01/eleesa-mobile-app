import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api/auth';

  String _serializeRole(UserRole role) {
    final name = role.name;
    if (name == 'hodAdmin' || name == 'hod_admin') {
      return 'hod_admin';
    }
    return name;
  }

  Future<Map<String, dynamic>> _postWithWakeupFeedback({
    required String endpoint,
    required Map<String, dynamic> payload,
    void Function(String status)? onStatusChange,
  }) async {
    Timer? wakeupTimer;
    Timer? slowWakeupTimer;

    if (onStatusChange != null) {
      wakeupTimer = Timer(const Duration(seconds: 3), () {
        onStatusChange('Waking up ELEESA server...');
      });
      slowWakeupTimer = Timer(const Duration(seconds: 12), () {
        onStatusChange('Energizing Render instance & database link...');
      });
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw Exception(data['message'] ?? 'Request failed');
    } on TimeoutException {
      throw Exception('Server took too long to wake up. Please tap again.');
    } finally {
      wakeupTimer?.cancel();
      slowWakeupTimer?.cancel();
    }
  }

  Future<EleesaUser> login({
    required String email,
    required String password,
    void Function(String status)? onStatusChange,
  }) async {
    final data = await _postWithWakeupFeedback(
      endpoint: 'login',
      payload: {
        'email': email.trim(),
        'password': password,
      },
      onStatusChange: onStatusChange,
    );
    return EleesaUser.fromJson(data['user'] ?? data);
  }

  Future<EleesaUser> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? indexOrStaffId,
    String? level,
    void Function(String status)? onStatusChange,
  }) async {
    final data = await _postWithWakeupFeedback(
      endpoint: 'signup',
      payload: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': _serializeRole(role),
        if (indexOrStaffId != null && indexOrStaffId.trim().isNotEmpty)
          'index_or_staff_id': indexOrStaffId.trim(),
        if (level != null && level.trim().isNotEmpty) 'level': level.trim(),
      },
      onStatusChange: onStatusChange,
    );
    return EleesaUser.fromJson(data['user'] ?? data);
  }

  Future<String> requestPasswordReset({
    required String email,
    void Function(String status)? onStatusChange,
  }) async {
    final data = await _postWithWakeupFeedback(
      endpoint: 'forgot-password',
      payload: {'email': email.trim()},
      onStatusChange: onStatusChange,
    );
    return data['message'] ?? 'Recovery code sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
    void Function(String status)? onStatusChange,
  }) async {
    final data = await _postWithWakeupFeedback(
      endpoint: 'reset-password',
      payload: {
        'email': email.trim(),
        'reset_code': resetCode.trim(),
        'new_password': newPassword,
      },
      onStatusChange: onStatusChange,
    );
    return data['message'] ?? 'Password updated successfully.';
  }
}
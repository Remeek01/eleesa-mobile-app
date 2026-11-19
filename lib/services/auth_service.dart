import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Replace with your live Render URL (e.g., https://eleesa-api.onrender.com/api/auth)
  static const String baseUrl = 'https://eleesa-backend.onrender.com/api/auth';
  Future<EleesaUser> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return EleesaUser.fromJson(data['user'] ?? data);
    }
    throw Exception(data['message'] ?? 'Invalid email or password');
  }

  Future<EleesaUser> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.name, // 'student', 'lecturer', or 'hod'
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return EleesaUser.fromJson(data['user'] ?? data);
    }
    throw Exception(data['message'] ?? 'Registration failed');
  }

  Future<String> requestPasswordReset({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Password recovery instructions sent to your email.';
    }
    throw Exception(data['message'] ?? 'Could not process recovery request');
  }
  Future<String> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'reset_code': resetCode.trim(),
        'new_password': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Password updated successfully.';
    }
    throw Exception(data['message'] ?? 'Failed to reset password');
  }
}
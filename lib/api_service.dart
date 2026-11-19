import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl => 'https://eleesa-backend.onrender.com';
  static Future<Map<String, dynamic>> checkConnection() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/health'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
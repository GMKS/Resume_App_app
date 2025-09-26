import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // One workable base URL for all platforms (LAN IP), with optional override.
  // Update the IP to your machine's LAN address if needed, and ensure the
  // backend listens on 0.0.0.0:3000. You can still override via --dart-define.
  // Example override:
  //   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultBaseUrl = 'http://192.168.29.90:3000/api';
  static String get baseUrl =>
      _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl;

  static const Duration requestTimeout = Duration(seconds: 10);
  // For localhost testing: 'http://localhost:3000/api'
  // For production, change to your deployed backend URL
  // static const String baseUrl = 'https://your-backend.herokuapp.com/api';

  static String? _token;

  // Headers for authenticated requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Initialize service and restore token
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token from storage
  static Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
            }),
          )
          .timeout(requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String identifier, // email or phone
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': identifier, 'password': password}),
          )
          .timeout(requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOTP({
    required String identifier,
    String type = 'login',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'type': type}),
          )
          .timeout(requestTimeout);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Failed to send OTP',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify OTP with generic identifier (email or phone)
  static Future<Map<String, dynamic>> verifyOTPByIdentifier({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'otp': otp}),
          )
          .timeout(requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user's resumes
  static Future<Map<String, dynamic>> getResumes({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resumes?page=$page&limit=$limit'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'data': data['data'],
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create new resume
  static Future<Map<String, dynamic>> createResume({
    required String title,
    required String template,
    required Map<String, dynamic> personalInfo,
    String? summary,
    List<Map<String, dynamic>>? workExperience,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? skills,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resumes'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'template': template,
          'personalInfo': personalInfo,
          if (summary != null) 'summary': summary,
          if (workExperience != null) 'workExperience': workExperience,
          if (education != null) 'education': education,
          if (skills != null) 'skills': skills,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'data': data['data'],
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update resume
  static Future<Map<String, dynamic>> updateResume({
    required String resumeId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/resumes/$resumeId'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'data': data['data'],
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete resume
  static Future<Map<String, dynamic>> deleteResume(String resumeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/resumes/$resumeId'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Export resume as PDF
  static Future<Map<String, dynamic>> exportToPDF(String resumeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resumes/$resumeId/export/pdf'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'data': data['data'],
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify token validity
  static Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _clearToken();
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _token != null;
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // Uses ApiConfig for automatic platform detection
  static String get baseUrl => ApiConfig.baseUrl;
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',  // Ensure REST Framework returns JSON, not HTML
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }
    
    return headers;
  }

  // Auth APIs
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Backend returned HTML instead of JSON. Status: ${response.statusCode}. Make sure the backend is running and the URL is correct.');
      }
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error message
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Login failed: ${response.statusCode}');
        } catch (e) {
          throw Exception('Login failed: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Backend returned invalid JSON. Make sure the backend server is running at $baseUrl');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );
      
      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Backend returned HTML instead of JSON. Status: ${response.statusCode}. Make sure the backend is running and the URL is correct.');
      }
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error message
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Registration failed: ${response.statusCode}');
        } catch (e) {
          throw Exception('Registration failed: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Backend returned invalid JSON. Make sure the backend server is running at $baseUrl');
      }
      rethrow;
    }
  }

  // Quiz APIs
  static Future<List<dynamic>> getQuizzes({String? category}) async {
    String url = '$baseUrl/quizzes/';
    if (category != null) {
      url += '?category=$category';
    }
    final response = await http.get(Uri.parse(url), headers: await getHeaders(includeAuth: false));
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getQuizQuestions(int quizId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId/questions/'),
      headers: await getHeaders(includeAuth: false),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> submitQuiz(int quizId, Map<String, int> answers) async {
    // Convert answers to string keys as backend expects
    final answersMap = answers.map((k, v) => MapEntry(k.toString(), v));
    
    final response = await http.post(
      Uri.parse('$baseUrl/results/submit/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'quiz_id': quizId,
        'answers': answersMap,
      }),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit quiz: ${response.body}');
    }
  }

  // Study Materials APIs
  static Future<List<dynamic>> getStudyMaterials({String? category}) async {
    String url = '$baseUrl/study-materials/';
    if (category != null) {
      url += '?category=$category';
    }
    final response = await http.get(Uri.parse(url), headers: await getHeaders(includeAuth: false));
    return jsonDecode(response.body);
  }

  static Future<void> incrementDownload(int materialId) async {
    await http.post(
      Uri.parse('$baseUrl/study-materials/$materialId/increment_download/'),
      headers: await getHeaders(),
    );
  }

  // Notifications APIs
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: await getHeaders(includeAuth: false),
    );
    return jsonDecode(response.body);
  }

  // Profile APIs
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: await getHeaders(),
    );
    final data = jsonDecode(response.body);
    return data.isNotEmpty ? data[0] : {};
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final currentProfile = await getProfile();
    final method = currentProfile.isEmpty ? 'POST' : 'PUT';
    final url = currentProfile.isEmpty 
        ? '$baseUrl/profile/' 
        : '$baseUrl/profile/${currentProfile['id']}/';
    
    final response = method == 'POST'
        ? await http.post(Uri.parse(url), headers: await getHeaders(), body: jsonEncode(profileData))
        : await http.put(Uri.parse(url), headers: await getHeaders(), body: jsonEncode(profileData));
    
    return jsonDecode(response.body);
  }

  // Bookmarks APIs
  static Future<List<dynamic>> getBookmarks([String? token]) async {
    // Accepts optional positional token for compatibility with callers
    Map<String, String> headers;
    if (token != null) {
      headers = await getHeaders(includeAuth: false);
      headers['Authorization'] = 'Token $token';
    } else {
      headers = await getHeaders();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookmarks/'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> toggleBookmark(dynamic arg1, [int? arg2]) async {
    // Support two call signatures used across the app:
    // 1) toggleBookmark(questionId)
    // 2) toggleBookmark(token, questionId)
    String? token;
    late int questionId;

    if (arg1 is int) {
      questionId = arg1;
    } else if (arg1 is String && arg2 != null) {
      token = arg1;
      questionId = arg2;
    } else {
      throw ArgumentError('toggleBookmark requires (questionId) or (token, questionId)');
    }

    Map<String, String> headers;
    if (token != null) {
      headers = await getHeaders(includeAuth: false);
      headers['Authorization'] = 'Token $token';
    } else {
      headers = await getHeaders();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookmarks/toggle/'),
      headers: headers,
      body: jsonEncode({'question_id': questionId}),
    );
    return jsonDecode(response.body);
  }

  // Results APIs (compatibility wrappers)
  static Future<List<dynamic>> getResults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/results/'),
      headers: await getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getResultDetails(int resultId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/results/$resultId/'),
      headers: await getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // Analytics API (compatibility wrapper)
  static Future<dynamic> getAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/'),
      headers: await getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // Reports APIs
  static Future<Map<String, dynamic>> reportQuestion({
    required int questionId,
    required String issueType,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'question': questionId,
        'issue_type': issueType,
        'description': description,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getMyReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/'),
      headers: await getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> googleLogin(String email, String? name, String? photoUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'token': 'dummy_token', // In real app, send ID token
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login with Google: ${response.body}');
    }
  }

  static Future<List<dynamic>> getLeaderboard({String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard/'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }
}


import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Change this to your server IP when testing on a real device ──────────────
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // Use 10.0.2.2 for Android emulator (maps to localhost on your PC)
  // Use your actual IP (e.g. http://192.168.1.x:8080/api/v1) for physical device

  static String? _accessToken;
  static String? _refreshToken;

  // ── Token management ──────────────────────────────────────────────────────────

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken  = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    _accessToken  = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static bool get isLoggedIn => _accessToken != null;

  // ── Headers ───────────────────────────────────────────────────────────────────

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ── Core request with auto-refresh ────────────────────────────────────────────

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool retry = true,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null) uri = uri.replace(queryParameters: queryParams);

    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Unsupported method: $method');
      }
    } catch (e) {
      throw ApiException('Network error: Could not connect to server. Check your internet connection.');
    }

    // Auto-refresh on 401
    if (response.statusCode == 401 && retry && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _request(method, path, body: body, queryParams: queryParams, retry: false);
      } else {
        await clearTokens();
        throw ApiException('Session expired. Please log in again.', code: 401);
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        data['message'] ?? 'Something went wrong',
        code: response.statusCode,
        errors: data['errors'],
      );
    }

    return data;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        await saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _request('POST', '/auth/register', body: {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
    });
    final d = res['data'];
    await saveTokens(d['access_token'], d['refresh_token']);
    return d['user'];
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _request('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    final d = res['data'];
    await saveTokens(d['access_token'], d['refresh_token']);
    return d['user'];
  }

  static Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout', body: {'refresh_token': _refreshToken});
    } catch (_) {}
    await clearTokens();
  }

  // ── Users ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _request('GET', '/users/me');
    return res['data'];
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? statusMessage,
    String? avatarUrl,
  }) async {
    final res = await _request('PUT', '/users/me', body: {
      if (name != null) 'name': name,
      if (statusMessage != null) 'status_message': statusMessage,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return res['data'];
  }

  static Future<void> updateStatus(String status) async {
    await _request('PUT', '/users/me/status', body: {'status': status});
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final res = await _request('GET', '/users/search', queryParams: {'q': query});
    return res['data'];
  }

  // ── Contacts ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getContactRequests() async {
    final res = await _request('GET', '/contacts/requests');
    return res['data'];
  }

  static Future<List<dynamic>> getContacts() async {
    final res = await _request('GET', '/contacts');
    return res['data'];
  }

  static Future<void> sendContactRequest(int userId) async {
    await _request('POST', '/contacts', body: {'user_id': userId});
  }

  static Future<void> acceptContact(int userId) async {
    await _request('PUT', '/contacts/$userId/accept');
  }

  static Future<void> removeContact(int contactId) async {
    await _request('DELETE', '/contacts/$contactId');
  }

  // ── Conversations ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getConversations() async {
    final res = await _request('GET', '/conversations');
    return res['data'];
  }

  static Future<Map<String, dynamic>> getOrCreateDirect(int userId) async {
    final res = await _request('POST', '/conversations/direct', body: {'user_id': userId});
    return res['data'];
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<int> participantIds,
  }) async {
    final res = await _request('POST', '/conversations', body: {
      'name': name,
      'participant_ids': participantIds,
    });
    return res['data'];
  }

  // ── Messages ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMessages(int convoId, {int page = 1}) async {
    final res = await _request('GET', '/conversations/$convoId/messages',
        queryParams: {'page': '$page', 'limit': '50'});
    return res['data'];
  }

  static Future<Map<String, dynamic>> sendMessage(int convoId, String content, {String type = 'text'}) async {
    final res = await _request('POST', '/conversations/$convoId/messages',
        body: {'content': content, 'type': type});
    return res['data'];
  }

  static Future<void> markAllRead(int convoId) async {
    await _request('POST', '/conversations/$convoId/read-all');
  }

  static Future<void> deleteMessage(int messageId) async {
    await _request('DELETE', '/messages/$messageId');
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  static Future<String> uploadImageBytes(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/upload/image');
    final ext = filename.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png'
        : ext == 'gif' ? 'image/gif'
        : ext == 'webp' ? 'image/webp'
        : 'image/jpeg';

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      })
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw ApiException(data['message'] ?? 'Upload failed', code: response.statusCode);
    }
    return data['data']['url'] as String;
  }

  // ── Stories ───────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getStories() async {
    final res = await _request('GET', '/stories');
    return res['data'];
  }

  static Future<void> createStory({
    required String type,
    String? content,
    String? mediaUrl,
    String bgColor = '#6C63FF',
  }) async {
    await _request('POST', '/stories', body: {
      'type': type,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      'bg_color': bgColor,
    });
  }

  static Future<void> viewStory(int storyId) async {
    await _request('POST', '/stories/$storyId/view');
  }
}

// ── Exception class ───────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? code;
  final dynamic errors;

  ApiException(this.message, {this.code, this.errors});

  @override
  String toString() => message;

  Map<String, String> get fieldErrors {
    if (errors is Map) {
      return Map<String, String>.from(
        (errors as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    return {};
  }
}

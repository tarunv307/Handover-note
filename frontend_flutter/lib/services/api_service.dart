import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/task.dart';
import '../models/submission.dart';
import '../models/handover_note.dart';

class ApiService {
  final String baseUrl;
  Map<String, String> _cookies = {};

  ApiService({this.baseUrl = 'http://localhost:5050'});

  void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final parts = rawCookie.split(';');
      for (var part in parts) {
        if (part.contains('=')) {
          final kv = part.trim().split('=');
          if (kv.length == 2) {
            _cookies[kv[0]] = kv[1];
          }
        }
      }
    }
  }

  Map<String, String> _getHeaders({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) headers['Content-Type'] = 'application/json';
    if (_cookies.isNotEmpty) {
      headers['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    return headers;
  }

  // Authentication
  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    _updateCookies(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/api/logout'), headers: _getHeaders());
    _cookies.clear();
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/me'), headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['authenticated'] == true && data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Users
  Future<List<User>> getUsers({String query = ''}) async {
    final url = query.isEmpty ? '$baseUrl/api/users' : '$baseUrl/api/users?q=${Uri.encodeComponent(query)}';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((u) => User.fromJson(u)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: _getHeaders(),
      body: jsonEncode(userData),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Failed to create user');
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/users/$id'), headers: _getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // Tasks
  Future<List<TaskItem>> getTasks({String? status}) async {
    final url = status != null ? '$baseUrl/api/tasks?status=$status' : '$baseUrl/api/tasks';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((t) => TaskItem.fromJson(t)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  Future<TaskItem> createTask(String title, String description, int? assignedTo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _getHeaders(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
      }),
    );
    if (response.statusCode == 201) {
      return TaskItem.fromJson(jsonDecode(response.body));
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Failed to create task');
  }

  Future<void> submitTaskWork(int taskId, {String? link, File? zipFile}) async {
    final uri = Uri.parse('$baseUrl/api/tasks/$taskId/submit');
    if (zipFile != null) {
      final request = http.MultipartRequest('POST', uri);
      if (_cookies.isNotEmpty) {
        request.headers['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      }
      if (link != null && link.isNotEmpty) {
        request.fields['link'] = link;
      }
      request.files.add(await http.MultipartFile.fromPath('file', zipFile.path));
      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode != 200) {
        final err = jsonDecode(res.body);
        throw Exception(err['error'] ?? 'Upload failed');
      }
    } else {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({'link': link}),
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Submission failed');
      }
    }
  }

  Future<void> reviewSubmission(int subId, String status, String? adminNotes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/submissions/$subId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'status': status,
        'admin_notes': adminNotes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to review submission');
    }
  }

  // Global Search
  Future<Map<String, dynamic>> search(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/search?q=${Uri.encodeComponent(query)}'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = (data['users'] as List).map((u) => User.fromJson(u)).toList();
      final tasks = (data['tasks'] as List).map((t) => TaskItem.fromJson(t)).toList();
      return {'users': users, 'tasks': tasks};
    }
    return {'users': <User>[], 'tasks': <TaskItem>[]};
  }

  // Shift Handover Generator
  Future<HandoverNote> generateShiftNote(String start, String end, String timezone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: _getHeaders(),
      body: jsonEncode({
        'shift_start': start,
        'shift_end': end,
        'timezone': timezone,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return HandoverNote.fromJson(data, downloadUrl: '$baseUrl${data['download_url']}');
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Generation failed');
  }
}

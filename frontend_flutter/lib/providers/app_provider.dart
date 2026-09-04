import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/handover_note.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  List<User> _users = [];
  List<TaskItem> _tasks = [];
  HandoverNote? _currentHandoverNote;

  Map<String, dynamic> _searchResults = {'users': <User>[], 'tasks': <TaskItem>[]};

  String get serverUrl => _api.baseUrl;
  void setServerUrl(String url) {
    _api.setBaseUrl(url);
    notifyListeners();
  }

  Future<bool> pingServer() => _api.pingServer();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<User> get users => _users;
  List<TaskItem> get tasks => _tasks;
  HandoverNote? get currentHandoverNote => _currentHandoverNote;
  Map<String, dynamic> get searchResults => _searchResults;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    _errorMessage = err;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _setLoading(true);
    _currentUser = await _api.getCurrentUser();
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _api.login(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _api.logout();
    _currentUser = null;
    _users = [];
    _tasks = [];
    _currentHandoverNote = null;
    _setLoading(false);
  }

  Future<void> fetchUsers({String query = ''}) async {
    try {
      _users = await _api.getUsers(query: query);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      await _api.createUser(userData);
      await fetchUsers();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _api.deleteUser(id);
      await fetchUsers();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> fetchTasks({String? status}) async {
    try {
      _tasks = await _api.getTasks(status: status);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createTask(String title, String description, int? assignedTo) async {
    try {
      await _api.createTask(title, description, assignedTo);
      await fetchTasks();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> submitTask(int taskId, {String? link, File? zipFile}) async {
    _setLoading(true);
    try {
      await _api.submitTaskWork(taskId, link: link, zipFile: zipFile);
      await fetchTasks();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> reviewSubmission(int subId, String status, String? adminNotes) async {
    try {
      await _api.reviewSubmission(subId, status, adminNotes);
      await fetchTasks();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      _searchResults = {'users': <User>[], 'tasks': <TaskItem>[]};
      notifyListeners();
      return;
    }
    _searchResults = await _api.search(query);
    notifyListeners();
  }

  Future<bool> generateShiftNote(String start, String end, String timezone) async {
    _setLoading(true);
    try {
      _currentHandoverNote = await _api.generateShiftNote(start, end, timezone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }
}

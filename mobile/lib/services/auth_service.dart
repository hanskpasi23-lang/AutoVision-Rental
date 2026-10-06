import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {

  static const String baseUrl = 'http://10.0.2.2:8000';
  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<String?> getToken() async {
    if (_token != null) return _token;

    _token = await _storage.read(key: 'jwt_token');
    return _token;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        await _storage.write(key: 'jwt_token', value: _token);

        await fetchUserProfile();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _token = await _storage.read(key: 'jwt_token');
    if (_token != null) {
      await fetchUserProfile();
    }
  }
}

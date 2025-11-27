import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isLoading => _isLoading;

  final String baseUrl = 'https://projet-chretien.onrender.com';

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;

    try {
      final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      _token = extractedUserData['token'];
      _currentUser = extractedUserData['user'];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = data['user'];
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = data['user'];
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        _currentUser = json.decode(response.body);
        await _saveAuthData(); // Mettre à jour les données locales
        notifyListeners();
      }
    } catch (e) {
      print('Fetch profile error: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'token': _token,
      'user': _currentUser,
    });
    await prefs.setString('userData', userData);
  }

  Map<String, String> getAuthHeaders() {
    if (_token == null) return {};
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

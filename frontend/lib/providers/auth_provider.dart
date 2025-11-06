import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profile => _profile;

  Future<void> login(String username, String password) async {
    try {
      final data = await ApiService.login(username, password);
      _token = data['token'];
      _user = data['user'];
      _profile = data['profile'];
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final data = await ApiService.register(username, email, password);
      _token = data['token'];
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      // Auto login after register
      await login(username, password);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _isLoggedIn = false;
    _user = null;
    _profile = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _isLoggedIn = _token != null;
    
    if (_isLoggedIn) {
      try {
        _profile = await ApiService.getProfile();
      } catch (e) {
        // Profile might not exist yet
      }
    }
    
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  String get username => _user?['username'] ?? _profile?['user']?['username'] ?? 'Student';

  Future<void> login(String username, String password) async {
    try {
      final data = await ApiService.login(username, password);
      _handleLoginSuccess(data);
    } catch (e) {
      _isLoggedIn = false;
      throw Exception('Login failed: $e');
    }
  }

  Future<void> googleLogin(String email, String? name, String? photoUrl) async {
    try {
      final data = await ApiService.googleLogin(email, name, photoUrl);
      _handleLoginSuccess(data);
    } catch (e) {
      _isLoggedIn = false;
      throw Exception('Google Login failed: $e');
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    _token = data['token'];
    _user = data['user'];
    _profile = data['profile'];
    _isLoggedIn = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', jsonEncode(_user));
    if (_profile != null) {
      await prefs.setString('profile', jsonEncode(_profile));
    }
    
    notifyListeners();
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
    await prefs.clear();
    
    notifyListeners();
  }

  Future<void> loadToken() async {
    if (_isLoading) return; // prevent re-entrancy
    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token != null) {
        final userStr = prefs.getString('user');
        final profileStr = prefs.getString('profile');
        if (userStr != null) {
          _user = jsonDecode(userStr);
        }
        if (profileStr != null) {
          _profile = jsonDecode(profileStr);
        }

        try {
          final profileData = await ApiService.getProfile().timeout(const Duration(seconds: 5));
          _profile = profileData;
          _user = profileData['user'];
          _isLoggedIn = true;
          await prefs.setString('user', jsonEncode(_user));
          await prefs.setString('profile', jsonEncode(_profile));
        } catch (e) {
          print('Token verification failed: $e');
          _token = null;
          _user = null;
          _profile = null;
          _isLoggedIn = false;
          await prefs.clear();
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      print('Load token error: $e');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

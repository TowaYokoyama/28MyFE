import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _username;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  bool get isAuthenticated => _token != null;

  final String baseUrl = 'https://my-flashcard-api.onrender.com';

  AuthService() {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<void> _saveTokens(String accessToken, String refreshToken, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('username', username);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('username');
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['access_token'];
      _refreshToken = data['refresh_token'];
      _username = username;
      await _saveTokens(_token!, _refreshToken!, _username!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/refresh_token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $_refreshToken',
      },
      body: {'refresh_token': _refreshToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['access_token'];
      _refreshToken = data['refresh_token'];
      await _saveTokens(_token!, _refreshToken!, _username!);
      notifyListeners();
      return true;
    } else {
      logout();
      return false;
    }
  }

  void logout() {
    _token = null;
    _refreshToken = null;
    _username = null;
    _clearTokens();
    notifyListeners();
  }
}
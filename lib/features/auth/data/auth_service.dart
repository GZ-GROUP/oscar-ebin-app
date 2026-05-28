import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile/data/profile_model.dart';
import '../../leaderboard/data/ranking_model.dart';

class AuthService {
  static const _baseUrl = 'https://oscar.gzgroup.dev/api';

  final http.Client client;

  AuthService({http.Client? client}) : client = client ?? http.Client();

  Future<bool> signup({
    required String username,
    required String name,
    required String email,
    required String password,
    bool isCompany = false,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');
    final resp = await client.post(url,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json'
        },
        body: jsonEncode({
          'username': username,
          'name': name,
          'email': email,
          'password': password,
          'is_company': isCompany,
        }));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final map = jsonDecode(resp.body) as Map<String, dynamic>?;
      return map?['success'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    final resp = await client.post(url,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json'
        },
        body: jsonEncode({'email': email, 'password': password}));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> profile(String accessToken) async {
    final url = Uri.parse('$_baseUrl/profile');
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer $accessToken',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<ProfileStats?> profileStats(String accessToken) async {
    final url = Uri.parse('$_baseUrl/profile');
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer $accessToken',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return ProfileStats.fromJson(json);
    }
    return null;
  }

  Future<RankingResponse?> ranking(String accessToken) async {
    final url = Uri.parse('$_baseUrl/ranking');
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer $accessToken',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return RankingResponse.fromJson(json);
    }
    return null;
  }

  // Token persistence
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  Future<void> persistTokens({required String access, String? refresh}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    if (refresh != null) await prefs.setString(_kRefresh, refresh);
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }
}

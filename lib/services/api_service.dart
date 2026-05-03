import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://apinofudev.bengkelfajarjaya.com/api/mynofu';

  static Future<http.Response> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 401) {
      debugPrint('Access token expired, attempting refresh...');
      final newAccessToken = await _refreshToken();
      
      if (newAccessToken != null) {
        debugPrint('Token refreshed successfully, retrying request...');
        // Retry the request with the new token
        response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $newAccessToken',
          },
        );
      }
    }

    return response;
  }

  static Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/private/introspect'),
        headers: {
          'x-refresh-token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final newAccessToken = data['data']['access_token'];
          await prefs.setString('access_token', newAccessToken);
          return newAccessToken;
        }
      } else {
        debugPrint('Refresh token failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    return null;
  }
}

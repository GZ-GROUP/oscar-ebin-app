import 'dart:convert';

import 'package:http/http.dart' as http;

import 'history_model.dart';

class HistoryService {
  static const _baseUrl = 'https://oscar.gzgroup.dev/api';

  final http.Client client;

  HistoryService({http.Client? client}) : client = client ?? http.Client();

  Future<List<HistoryEntry>> getRecentHistory(
    String accessToken, {
    int page = 1,
    int limit = 3,
    String? type,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) {
      queryParameters['type'] = type;
    }
    final url = Uri.parse('$_baseUrl/history')
        .replace(queryParameters: queryParameters);
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer $accessToken',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? <dynamic>[];
      return data
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/oscar.dart';

class MapsService {
  static const _baseUrl = 'https://oscar.gzgroup.dev/api';

  final http.Client client;

  MapsService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Oscar>> getOscarLocations(String accessToken) async {
    final url = Uri.parse('$_baseUrl/oscar/location');
    final resp = await client.get(
      url,
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'Bearer $accessToken',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final oscarsData = data['data'] as List<dynamic>?;

      if (oscarsData != null) {
        return oscarsData
            .map((e) => Oscar.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}

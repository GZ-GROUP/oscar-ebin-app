import 'dart:convert';

import 'package:http/http.dart' as http;

class ScannerService {
  static const _baseUrl = 'https://oscar.gzgroup.dev/api';

  final http.Client client;

  ScannerService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> claimOscar(
    String accessToken,
    String oscarCode,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/oscar/claim');
      final resp = await client.post(
        url,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
          'authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'oscar_code': oscarCode}),
      );

      final body = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (body.containsKey('error')) {
          return {'error': body['error'] as String? ?? 'Oscar no encontrado'};
        }

        final itemCount = body['item_count'];
        final data = body['data'];
        if (data == null || (itemCount is int && itemCount == 0)) {
          return {'error': 'Oscar no encontrado'};
        }

        return body;
      }

      return {'error': body['error'] as String? ?? 'Oscar no encontrado'};
    } catch (_) {
      return {'error': 'Oscar no encontrado'};
    }
  }
}

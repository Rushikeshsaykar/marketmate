import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'config.dart';

Future<Map<String, dynamic>> query(
  String q, {
  Map<String, dynamic>? variables,
}) async {
  try {
    final Map<String, dynamic>? cleanVariables = variables != null
        ? (Map<String, dynamic>.from(variables)..removeWhere((_, v) => v == null))
        : null;

    final response = await http
        .post(
          Uri.parse(graphqlUrl),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': q,
            'variables': ?cleanVariables,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response received from server');
    }

    if (decoded.containsKey('errors') &&
        decoded['errors'] is List &&
        (decoded['errors'] as List).isNotEmpty) {
      final firstError = (decoded['errors'] as List).first;
      final message = firstError is Map
          ? (firstError['message']?.toString() ?? 'GraphQL error occurred')
          : 'GraphQL error occurred';
      throw Exception(message);
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  } on SocketException {
    throw Exception('Cannot reach the server. Check Wi-Fi and the server address.');
  } on TimeoutException {
    throw Exception('Cannot reach the server. Check Wi-Fi and the server address.');
  } on http.ClientException {
    throw Exception('Cannot reach the server. Check Wi-Fi and the server address.');
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }
    throw Exception(e.toString());
  }
}

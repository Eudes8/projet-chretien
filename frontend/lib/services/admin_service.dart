import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  final String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> getStats(Map<String, String> headers) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stats');
    }
  }
}

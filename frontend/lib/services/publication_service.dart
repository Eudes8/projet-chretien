import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // For XFile
import '../models/publication.dart';

class PublicationService {
  // ... (baseUrl)
  final String baseUrl = 'https://projet-chretien.onrender.com';

  // ... (getPublications)
  Future<List<Publication>> getPublications() async {
    final response = await http.get(Uri.parse('$baseUrl/publications'));

    if (response.statusCode == 200) {
      final List<dynamic> publicationsData = json.decode(response.body);
      return publicationsData.map((json) => Publication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load publications');
    }
  }

  Future<void> createPublication(Map<String, dynamic> data, Map<String, String> authHeaders, {XFile? imageFile}) async {
    var uri = Uri.parse('$baseUrl/publications');
    
    if (imageFile != null) {
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders);
      
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Use bytes for cross-platform compatibility (Web & Mobile)
      var bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'coverImage', 
        bytes, 
        filename: imageFile.name
      ));

      var response = await request.send();
      if (response.statusCode != 201) {
        throw Exception('Failed to create publication');
      }
    } else {
      final response = await http.post(
        uri,
        headers: authHeaders..addAll({'Content-Type': 'application/json'}),
        body: json.encode(data),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create publication');
      }
    }
  }

  Future<void> updatePublication(int id, Map<String, dynamic> data, Map<String, String> authHeaders, {XFile? imageFile}) async {
    var uri = Uri.parse('$baseUrl/publications/$id');
    
    if (imageFile != null) {
      var request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(authHeaders);
      
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      var bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'coverImage', 
        bytes, 
        filename: imageFile.name
      ));

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to update publication');
      }
    } else {
      final response = await http.put(
        uri,
        headers: authHeaders..addAll({'Content-Type': 'application/json'}),
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update publication');
      }
    }
  }
// ... (deletePublication)

  Future<void> deletePublication(int id, Map<String, String> authHeaders) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/publications/$id'),
      headers: authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete publication');
    }
  }
}
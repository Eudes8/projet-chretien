import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class ImageCacheService {
  Future<String?> cacheImage(String url) async {
    try {
      final filename = md5.convert(utf8.encode(url)).toString();
      
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/images/$filename.jpg';
      
      if (await File(imagePath).exists()) {
        return imagePath;
      }
      
      await Directory('${directory.path}/images').create(recursive: true);
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);
        return imagePath;
      }
      
      return null;
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }
  
  Future<ImageProvider> getImage(String? url) async {
    if (url == null || url.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }
    
    if (url.startsWith('/')) {
      return FileImage(File(url));
    }
    
    final cachedPath = await cacheImage(url);
    
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }
    
    return NetworkImage(url);
  }
}

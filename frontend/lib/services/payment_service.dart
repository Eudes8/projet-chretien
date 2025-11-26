import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class PaymentService {
  final Dio _dio = Dio(BaseOptions(
    baseURL: 'http://192.168.1.8:3000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  
  final AuthService _authService = AuthService();

  Future<bool> subscribe({required String plan}) async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        debugPrint('No token found');
        return false;
      }

      final response = await _dio.post(
        '/payments/subscribe',
        data: {'plan': plan},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200) {
        // Update local user data
        await _authService.fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }
}

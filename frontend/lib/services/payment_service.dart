import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../theme/premium_components.dart';

class PaymentService {
  final AuthService _auth = AuthService();

  Future<bool> subscribe({required String plan}) async {
    try {
      final response = await _auth._dio.post('/payments/subscribe', data: {'plan': plan});
      if (response.statusCode == 200) {
        // Update local user data
        await _auth.fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }
}

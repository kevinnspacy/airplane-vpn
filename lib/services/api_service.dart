import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription_status.dart';

/// Service for communicating with FreedomVPN backend API
class ApiService {
  // VPS server URL (webhook server)
  static const String baseUrl = 'http://107.189.23.38:8080';
  
  // API key for authentication (same as FLUTTER_API_KEY in bot's .env)
  static const String apiKey = '502e5080ae5f22b2df92dcf4a431186f8837fb73483bc97eac2ab3fa42ad64e4';
  
  /// Timeout for API requests
  static const Duration timeout = Duration(seconds: 10);

  /// Get subscription status for a user
  /// 
  /// [telegramId] - The user's Telegram ID
  /// Returns [SubscriptionStatus] or null if request fails
  static Future<SubscriptionStatus?> getSubscriptionStatus(int telegramId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/subscription/$telegramId')
          .replace(queryParameters: {'api_key': apiKey});
      
      final response = await http.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SubscriptionStatus.fromJson(json);
      } else if (response.statusCode == 403) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 404) {
        return SubscriptionStatus(active: false, message: 'User not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('ApiService.getSubscriptionStatus error: $e');
      return null;
    }
  }

  /// Check if the API server is healthy
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:async';
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
  /// Fetch subscription status by Telegram ID
  static Future<SubscriptionStatus?> getSubscriptionStatus(int telegramId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/subscription/$telegramId?api_key=$apiKey');
      final response = await http.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SubscriptionStatus.fromJson(json);
      } else if (response.statusCode == 403) {
        print('ApiService: Invalid API key');
        return null;
      }
      return null;
    } on TimeoutException {
      print('ApiService: Request timeout');
      return null;
    } catch (e) {
      print('ApiService.getSubscriptionStatus error: $e');
      return null;
    }
  }

  /// Fetch subscription status by Marzban username (auto-detected from VLESS config)
  /// This is the preferred method - no need for user to enter Telegram ID!
  static Future<SubscriptionStatus?> getSubscriptionByUsername(String marzbanUsername) async {
    try {
      // URL encode the username just in case
      final encodedUsername = Uri.encodeComponent(marzbanUsername);
      final uri = Uri.parse('$baseUrl/api/subscription/by-username/$encodedUsername?api_key=$apiKey');
      final response = await http.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SubscriptionStatus.fromJson(json);
      } else if (response.statusCode == 403) {
        print('ApiService: Invalid API key');
        return null;
      } else if (response.statusCode == 404) {
        print('ApiService: Subscription not found for username: $marzbanUsername');
        return null;
      }
      return null;
    } on TimeoutException {
      print('ApiService: Request timeout');
      return null;
    } catch (e) {
      print('ApiService.getSubscriptionByUsername error: $e');
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

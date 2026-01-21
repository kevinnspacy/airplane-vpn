import 'package:flutter/foundation.dart';
import '../models/subscription_status.dart';
import '../services/api_service.dart';

/// Provider for managing subscription status state
/// Automatically detects subscription from added servers (by marzban_username)
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionStatus? _subscription;
  bool _isLoading = false;
  String? _error;
  String? _currentUsername;

  SubscriptionStatus? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSubscription => _subscription?.active == true;
  bool get isExpiringSoon => _subscription?.isExpiringSoon == true;
  bool get hasLinkedServer => _currentUsername != null;

  /// Fetch subscription by marzban username (extracted from VLESS config)
  /// Call this when user adds a server - username is in the server name like "FreedomVPN_ivan_abc1"
  Future<void> fetchByUsername(String marzbanUsername) async {
    if (marzbanUsername.isEmpty) return;
    
    _currentUsername = marzbanUsername;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await ApiService.getSubscriptionByUsername(marzbanUsername);
      _subscription = status;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('SubscriptionProvider.fetchByUsername error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh subscription status using previously saved username
  Future<void> refresh() async {
    if (_currentUsername != null) {
      await fetchByUsername(_currentUsername!);
    }
  }

  /// Extract marzban username from server name or subscription URL
  /// Example: "FreedomVPN_ivan_abc1" from server name  
  static String? extractUsername(String serverName) {
    // Marzban usernames typically look like: FreedomVPN_name_xxxx
    final regex = RegExp(r'FreedomVPN_\w+_\w+');
    final match = regex.firstMatch(serverName);
    return match?.group(0);
  }

  /// Clear subscription data
  void clear() {
    _subscription = null;
    _currentUsername = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

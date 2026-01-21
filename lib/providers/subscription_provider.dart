import 'package:flutter/foundation.dart';
import '../models/subscription_status.dart';
import '../services/api_service.dart';

/// Provider for managing subscription status state
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionStatus? _subscription;
  bool _isLoading = false;
  String? _error;
  int? _telegramId;

  SubscriptionStatus? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSubscription => _subscription?.active == true;
  bool get isExpiringSoon => _subscription?.isExpiringSoon == true;

  /// Set the user's Telegram ID (call after authentication or from config)
  void setTelegramId(int telegramId) {
    _telegramId = telegramId;
    fetchSubscription();
  }

  /// Fetch subscription status from API
  Future<void> fetchSubscription() async {
    if (_telegramId == null) {
      _error = 'Telegram ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await ApiService.getSubscriptionStatus(_telegramId!);
      _subscription = status;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('SubscriptionProvider.fetchSubscription error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear subscription data (e.g., on logout)
  void clear() {
    _subscription = null;
    _telegramId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

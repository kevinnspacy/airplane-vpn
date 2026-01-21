/// Subscription status model for API response
class SubscriptionStatus {
  final bool active;
  final String? planType;
  final DateTime? expiresAt;
  final int? daysLeft;
  final int? hoursLeft;
  final String? subscriptionUrl;
  final String? marzbanUsername;
  final String? message;

  SubscriptionStatus({
    required this.active,
    this.planType,
    this.expiresAt,
    this.daysLeft,
    this.hoursLeft,
    this.subscriptionUrl,
    this.marzbanUsername,
    this.message,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      active: json['active'] ?? false,
      planType: json['plan_type'],
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      daysLeft: json['days_left'],
      hoursLeft: json['hours_left'],
      subscriptionUrl: json['subscription_url'],
      marzbanUsername: json['marzban_username'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'plan_type': planType,
      'expires_at': expiresAt?.toIso8601String(),
      'days_left': daysLeft,
      'hours_left': hoursLeft,
      'subscription_url': subscriptionUrl,
      'marzban_username': marzbanUsername,
      'message': message,
    };
  }

  /// Get human-readable plan name
  String get planName {
    switch (planType) {
      case 'trial':
        return 'Тестовый (72 часа)';
      case 'day':
        return '1 день';
      case 'week':
        return '1 неделя';
      case 'month':
        return '1 месяц';
      case '3month':
        return '3 месяца';
      case 'year':
        return '1 год';
      default:
        return planType ?? 'Неизвестно';
    }
  }

  /// Get formatted expiry string
  String get expiryString {
    if (!active || expiresAt == null) {
      return 'Нет активной подписки';
    }
    
    if (daysLeft != null && daysLeft! > 0) {
      return 'Осталось $daysLeft дней';
    } else if (hoursLeft != null && hoursLeft! > 0) {
      return 'Осталось $hoursLeft часов';
    } else {
      return 'Истекает сегодня';
    }
  }

  /// Check if subscription is expiring soon (less than 3 days)
  bool get isExpiringSoon {
    if (!active || daysLeft == null) return false;
    return daysLeft! <= 3;
  }
}

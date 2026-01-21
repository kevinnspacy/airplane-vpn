import 'package:flutter/material.dart';
import '../models/subscription_status.dart';
import '../theme/app_theme.dart';

/// Widget to display subscription status on HomeScreen
class SubscriptionCard extends StatelessWidget {
  final SubscriptionStatus? subscription;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onTapLogin;
  final bool hasTelegramId;

  const SubscriptionCard({
    super.key,
    this.subscription,
    this.isLoading = false,
    this.onRefresh,
    this.onTapLogin,
    this.hasTelegramId = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: _getIconColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Подписка',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                )
              else if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && subscription == null) {
      return const Text(
        'Загрузка...',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      );
    }

    // No Telegram ID linked - show login prompt
    if (!hasTelegramId) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Привяжите Telegram для просмотра подписки',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTapLogin,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Ввести Telegram ID'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    if (subscription == null || !subscription!.active) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Нет активной подписки',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Активируйте в @freeddomm_bot',
            style: TextStyle(
              color: AppTheme.primaryColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // Active subscription
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subscription!.planName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Активна',
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: _getExpiryColor(),
            ),
            const SizedBox(width: 6),
            Text(
              subscription!.expiryString,
              style: TextStyle(
                color: _getExpiryColor(),
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (subscription!.expiresAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'До ${_formatDate(subscription!.expiresAt!)}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIcon() {
    if (subscription?.active == true) {
      return Icons.verified;
    }
    return Icons.remove_circle_outline;
  }

  Color _getIconColor() {
    if (subscription?.active == true) {
      if (subscription!.isExpiringSoon) {
        return AppTheme.warningColor;
      }
      return AppTheme.successColor;
    }
    return AppTheme.textSecondary;
  }

  Color _getBorderColor() {
    if (subscription?.active == true) {
      if (subscription!.isExpiringSoon) {
        return AppTheme.warningColor.withOpacity(0.3);
      }
      return AppTheme.successColor.withOpacity(0.3);
    }
    return AppTheme.cardColor;
  }

  Color _getStatusColor() {
    if (subscription?.isExpiringSoon == true) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  Color _getExpiryColor() {
    if (subscription?.isExpiringSoon == true) {
      return AppTheme.warningColor;
    }
    return AppTheme.textSecondary;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

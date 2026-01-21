import 'package:flutter/material.dart';
import '../models/connection_state.dart';
import '../theme/app_theme.dart';

class ConnectionStatsCard extends StatelessWidget {
  final ConnectionStats stats;
  
  const ConnectionStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Время',
            value: stats.durationFormatted,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.arrow_downward,
            label: 'Скачано',
            value: stats.downloadFormatted,
            color: AppTheme.successColor,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.arrow_upward,
            label: 'Отправлено',
            value: stats.uploadFormatted,
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color ?? AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppTheme.textMuted.withOpacity(0.2),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'Настройки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // VPN Settings
        _buildSectionTitle('VPN'),
        _buildSettingsCard([
          _buildSwitchTile(
            icon: Icons.security,
            title: 'Kill Switch',
            subtitle: 'Блокировать интернет при разрыве VPN',
            value: settings.killSwitch,
            onChanged: settings.setKillSwitch,
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.play_circle_outline,
            title: 'Автоподключение',
            subtitle: 'Подключаться при запуске приложения',
            value: settings.autoConnect,
            onChanged: settings.setAutoConnect,
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.call_split,
            title: 'Split Tunneling',
            subtitle: 'Выбор приложений для VPN',
            value: settings.splitTunneling,
            onChanged: settings.setSplitTunneling,
          ),
        ]),
        
        const SizedBox(height: 24),
        
        // Notifications
        _buildSectionTitle('Уведомления'),
        _buildSettingsCard([
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Показывать уведомление',
            subtitle: 'Статус VPN в панели уведомлений',
            value: settings.showNotification,
            onChanged: settings.setShowNotification,
          ),
        ]),
        
        const SizedBox(height: 24),
        
        // About
        _buildSectionTitle('О приложении'),
        _buildSettingsCard([
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: 'Политика конфиденциальности',
            onTap: () => _openUrl('https://example.com/privacy'),
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.article_outlined,
            title: 'Условия использования',
            onTap: () => _openUrl('https://example.com/terms'),
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: 'Поддержка',
            onTap: () => _openUrl('https://t.me/your_support_bot'),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Версия',
            value: '1.0.0',
          ),
        ]),
        
        const SizedBox(height: 32),
        
        // Made with love
        Center(
          child: Column(
            children: [
              Text(
                'Airplane VPN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Сделано с ❤️',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
  
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: AppTheme.surfaceColor,
      ),
    );
  }
  
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

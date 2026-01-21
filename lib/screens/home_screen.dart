import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/servers_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/connection_state.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_button.dart';
import '../widgets/connection_stats_card.dart';
import '../widgets/server_selector.dart';
import '../widgets/subscription_card.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';
import 'add_server_screen.dart';
import 'telegram_id_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _didAutoLoadSubscription = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Auto-load subscription after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoLoadSubscription());
  }

  void _autoLoadSubscription() {
    if (_didAutoLoadSubscription) return;
    _didAutoLoadSubscription = true;

    final settings = context.read<SettingsProvider>();
    final subscription = context.read<SubscriptionProvider>();
    
    if (settings.telegramId != null) {
      subscription.setTelegramId(settings.telegramId!);
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.airplanemode_active,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Airplane',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          // Settings button
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    final servers = context.watch<ServersProvider>();
    final vpn = context.watch<VPNProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    
    if (servers.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }
    
    if (!servers.hasServers) {
      return _buildEmptyState(context);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Status text
          _buildStatusText(vpn.state),
          
          const SizedBox(height: 40),
          
          // Connection button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: vpn.state.isConnected ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: ConnectionButton(
              state: vpn.state,
              onPressed: vpn.toggle,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Stats card (visible when connected)
          AnimatedOpacity(
            opacity: vpn.state.isConnected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ConnectionStatsCard(stats: vpn.stats),
          ),
          
          const SizedBox(height: 30),
          
          // Server selector
          ServerSelector(
            server: servers.selectedServer,
            onTap: () => _openServersList(context),
          ),
          
          const SizedBox(height: 20),
          
          // Subscription status card
          SubscriptionCard(
            subscription: subscription.subscription,
            isLoading: subscription.isLoading,
            hasTelegramId: context.watch<SettingsProvider>().hasTelegramId,
            onRefresh: subscription.fetchSubscription,
            onTapLogin: () => _openTelegramIdScreen(context),
          ),
          
          const SizedBox(height: 20),
          
          // Error message
          if (vpn.errorMessage != null)
            _buildErrorMessage(vpn.errorMessage!),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Добавьте сервер',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Импортируйте VLESS-ключ из вашего\nтелеграм-бота, чтобы начать',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _openAddServer(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить сервер'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusText(VpnConnectionState state) {
    Color textColor;
    String statusText;
    
    switch (state) {
      case VpnConnectionState.connected:
        textColor = AppTheme.successColor;
        statusText = 'Защищено';
      case VpnConnectionState.connecting:
        textColor = AppTheme.warningColor;
        statusText = 'Подключение...';
      case VpnConnectionState.disconnecting:
        textColor = AppTheme.warningColor;
        statusText = 'Отключение...';
      case VpnConnectionState.error:
        textColor = AppTheme.errorColor;
        statusText = 'Ошибка подключения';
      case VpnConnectionState.disconnected:
        textColor = AppTheme.textSecondary;
        statusText = 'Не защищено';
    }
    
    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.isConnected 
              ? 'Ваш трафик зашифрован'
              : 'Нажмите для подключения',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _openServersList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServersScreen()),
    );
  }
  
  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
  
  void _openAddServer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServerScreen()),
    );
  }

  Future<void> _openTelegramIdScreen(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelegramIdScreen()),
    );
    
    // Reload subscription if ID was set
    if (result == true && mounted) {
      final settings = context.read<SettingsProvider>();
      if (settings.telegramId != null) {
        context.read<SubscriptionProvider>().setTelegramId(settings.telegramId!);
      }
    }
  }
}

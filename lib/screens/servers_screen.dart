import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/servers_provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/server_selector.dart';
import 'add_server_screen.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key});

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
                child: _buildServersList(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddServer(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
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
              'Серверы',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showImportDialog(context),
            icon: const Icon(
              Icons.download_outlined,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Импортировать',
          ),
        ],
      ),
    );
  }
  
  Widget _buildServersList(BuildContext context) {
    final servers = context.watch<ServersProvider>();
    final vpn = context.watch<VPNProvider>();
    
    if (servers.servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dns_outlined,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет серверов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте сервер для подключения',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddServer(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: servers.servers.length,
      itemBuilder: (context, index) {
        final server = servers.servers[index];
        final isSelected = server.id == servers.selectedServer?.id;
        
        return ServerListItem(
          server: server,
          isSelected: isSelected,
          onTap: () {
            servers.selectServer(server);
            // Если VPN подключен, показываем предупреждение
            if (vpn.state == vpn_state.ConnectionState.connected) {
              _showReconnectDialog(context);
            }
          },
          onDelete: () => _confirmDelete(context, server.id, server.displayName),
        );
      },
    );
  }
  
  void _openAddServer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServerScreen()),
    );
  }
  
  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Импорт серверов',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вставьте VLESS-ссылки (каждая на новой строке):',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                hintText: 'vless://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final servers = context.read<ServersProvider>();
              final count = await servers.importServersFromText(controller.text);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Добавлено серверов: $count'),
                  ),
                );
              }
            },
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Удалить сервер?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Сервер "$name" будет удалён.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ServersProvider>().removeServer(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
  
  void _showReconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Переподключиться?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Для смены сервера нужно переподключиться к VPN.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            onPressed: () async {
              final vpn = context.read<VPNProvider>();
              Navigator.pop(context);
              await vpn.disconnect();
              await Future.delayed(const Duration(milliseconds: 500));
              await vpn.connect();
            },
            child: const Text('Переподключиться'),
          ),
        ],
      ),
    );
  }
}

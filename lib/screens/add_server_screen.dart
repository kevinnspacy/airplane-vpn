import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/servers_provider.dart';
import '../theme/app_theme.dart';

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _controller.dispose();
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructions(),
                      const SizedBox(height: 24),
                      _buildInputField(),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildError(),
                      ],
                      const SizedBox(height: 24),
                      _buildActions(),
                      const SizedBox(height: 32),
                      _buildHelp(),
                    ],
                  ),
                ),
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
              'Добавить сервер',
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
  
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Как получить ключ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Скопируйте VLESS-ссылку из вашего телеграм-бота',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VLESS-ссылка',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 4,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'vless://...',
            hintStyle: TextStyle(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            suffixIcon: IconButton(
              onPressed: _pasteFromClipboard,
              icon: const Icon(
                Icons.content_paste,
                color: AppTheme.primaryColor,
              ),
              tooltip: 'Вставить',
            ),
          ),
          onChanged: (_) {
            if (_error != null) {
              setState(() => _error = null);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _scanQrCode,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.textMuted),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 20),
                SizedBox(width: 8),
                Text('Сканировать QR'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addServer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Добавить'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHelp() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Поддерживаемые протоколы',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildProtocolItem('VLESS + Reality', 'Рекомендуется'),
          _buildProtocolItem('VLESS + TLS', 'Поддерживается'),
          _buildProtocolItem('VLESS + WebSocket', 'Поддерживается'),
        ],
      ),
    );
  }
  
  Widget _buildProtocolItem(String name, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }
  
  Future<void> _addServer() async {
    final uri = _controller.text.trim();
    
    if (uri.isEmpty) {
      setState(() => _error = 'Введите VLESS-ссылку');
      return;
    }
    
    if (!uri.startsWith('vless://')) {
      setState(() => _error = 'Неверный формат. Ссылка должна начинаться с vless://');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final servers = context.read<ServersProvider>();
      final success = await servers.addServerFromUri(uri);
      
      if (!mounted) return;
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сервер успешно добавлен'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        setState(() {
          _error = 'Не удалось добавить сервер. Проверьте ссылку или сервер уже существует.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _scanQrCode() {
    // TODO: Реализовать сканирование QR-кода
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Сканирование QR будет доступно в следующей версии'),
      ),
    );
  }
}

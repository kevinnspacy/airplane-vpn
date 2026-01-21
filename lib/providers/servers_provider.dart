import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vless_config.dart';

class ServersProvider extends ChangeNotifier {
  List<VlessConfig> _servers = [];
  VlessConfig? _selectedServer;
  bool _isLoading = true;
  
  List<VlessConfig> get servers => _servers;
  VlessConfig? get selectedServer => _selectedServer;
  bool get isLoading => _isLoading;
  bool get hasServers => _servers.isNotEmpty;
  
  ServersProvider() {
    _loadServers();
  }
  
  Future<void> _loadServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serversJson = prefs.getString('servers');
      final selectedId = prefs.getString('selectedServerId');
      
      if (serversJson != null) {
        final List<dynamic> decoded = jsonDecode(serversJson);
        _servers = decoded
            .map((json) => VlessConfig.fromJson(json))
            .toList();
        
        if (selectedId != null && _servers.isNotEmpty) {
          _selectedServer = _servers.firstWhere(
            (s) => s.id == selectedId,
            orElse: () => _servers.first,
          );
        } else if (_servers.isNotEmpty) {
          _selectedServer = _servers.first;
        }
      }
    } catch (e) {
      print('Error loading servers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serversJson = jsonEncode(_servers.map((s) => s.toJson()).toList());
      await prefs.setString('servers', serversJson);
      
      if (_selectedServer != null) {
        await prefs.setString('selectedServerId', _selectedServer!.id);
      }
    } catch (e) {
      print('Error saving servers: $e');
    }
  }
  
  /// Добавляет сервер из VLESS ссылки
  Future<bool> addServerFromUri(String uri) async {
    final config = VlessConfig.fromUri(uri);
    if (config == null) return false;
    
    // Проверяем на дубликаты по адресу и UUID
    final exists = _servers.any(
      (s) => s.address == config.address && s.uuid == config.uuid,
    );
    
    if (exists) return false;
    
    _servers.add(config);
    
    // Если это первый сервер, выбираем его
    if (_servers.length == 1) {
      _selectedServer = config;
    }
    
    await _saveServers();
    notifyListeners();
    return true;
  }
  
  /// Удаляет сервер
  Future<void> removeServer(String id) async {
    _servers.removeWhere((s) => s.id == id);
    
    // Если удалили выбранный сервер
    if (_selectedServer?.id == id) {
      _selectedServer = _servers.isNotEmpty ? _servers.first : null;
    }
    
    await _saveServers();
    notifyListeners();
  }
  
  /// Выбирает сервер для подключения
  Future<void> selectServer(VlessConfig server) async {
    _selectedServer = server;
    await _saveServers();
    notifyListeners();
  }
  
  /// Обновляет порядок серверов (для drag & drop)
  Future<void> reorderServers(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final server = _servers.removeAt(oldIndex);
    _servers.insert(newIndex, server);
    await _saveServers();
    notifyListeners();
  }
  
  /// Импортирует несколько серверов из текста (каждая ссылка на новой строке)
  Future<int> importServersFromText(String text) async {
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('vless://'))
        .toList();
    
    int added = 0;
    for (final line in lines) {
      if (await addServerFromUri(line)) {
        added++;
      }
    }
    
    return added;
  }
  
  /// Экспортирует все серверы в текст
  String exportServersToText() {
    // Для экспорта нужно было бы сохранять оригинальные URI
    // Пока просто возвращаем информацию о серверах
    return _servers.map((s) => '${s.name}: ${s.shortAddress}').join('\n');
  }
}

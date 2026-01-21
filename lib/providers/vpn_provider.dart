import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/vless_config.dart';
import '../models/connection_state.dart';
import 'servers_provider.dart';

class VPNProvider extends ChangeNotifier {
  // Platform channel для связи с нативным кодом
  static const _channel = MethodChannel('com.airplane.vpn/vpn');
  static const _eventChannel = EventChannel('com.airplane.vpn/vpn_events');
  
  VpnConnectionState _state = VpnConnectionState.disconnected;
  ConnectionStats _stats = const ConnectionStats();
  String? _errorMessage;
  ServersProvider? _serversProvider;
  
  Timer? _statsTimer;
  StreamSubscription? _eventSubscription;
  
  VpnConnectionState get state => _state;
  ConnectionStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  VlessConfig? get currentServer => _serversProvider?.selectedServer;
  
  VPNProvider() {
    _initEventListener();
  }
  
  void _initEventListener() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleVpnEvent, onError: _handleVpnError);
  }
  
  void _handleVpnEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'] as String?;
      
      switch (type) {
        case 'state_changed':
          final stateStr = event['state'] as String;
          _updateState(_parseState(stateStr));
          break;
          
        case 'stats_updated':
          _stats = _stats.copyWith(
            bytesIn: event['bytesIn'] as int? ?? _stats.bytesIn,
            bytesOut: event['bytesOut'] as int? ?? _stats.bytesOut,
          );
          notifyListeners();
          break;
          
        case 'error':
          _errorMessage = event['message'] as String?;
          _updateState(VpnConnectionState.error);
          break;
      }
    }
  }
  
  void _handleVpnError(dynamic error) {
    print('VPN Event Error: $error');
    _errorMessage = error.toString();
    _updateState(VpnConnectionState.error);
  }
  
  VpnConnectionState _parseState(String state) {
    switch (state) {
      case 'connected':
        return VpnConnectionState.connected;
      case 'connecting':
        return VpnConnectionState.connecting;
      case 'disconnecting':
        return VpnConnectionState.disconnecting;
      case 'error':
        return VpnConnectionState.error;
      default:
        return VpnConnectionState.disconnected;
    }
  }
  
  void _updateState(VpnConnectionState newState) {
    if (_state == newState) return;
    
    final wasConnected = _state.isConnected;
    _state = newState;
    
    if (newState.isConnected && !wasConnected) {
      _startStatsTimer();
      _stats = ConnectionStats(connectedAt: DateTime.now());
    } else if (!newState.isConnected && wasConnected) {
      _stopStatsTimer();
    }
    
    if (newState != VpnConnectionState.error) {
      _errorMessage = null;
    }
    
    notifyListeners();
  }
  
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isConnected && _stats.connectedAt != null) {
        _stats = _stats.copyWith(
          duration: DateTime.now().difference(_stats.connectedAt!),
        );
        notifyListeners();
      }
    });
  }
  
  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }
  
  void updateServers(ServersProvider servers) {
    _serversProvider = servers;
  }
  
  /// Подключается к VPN
  Future<void> connect() async {
    if (_state.isTransitioning) return;
    
    final server = currentServer;
    if (server == null) {
      _errorMessage = 'Сервер не выбран';
      _updateState(VpnConnectionState.error);
      return;
    }
    
    _updateState(VpnConnectionState.connecting);
    _errorMessage = null;
    
    try {
      final config = server.toSingboxConfig();
      
      final result = await _channel.invokeMethod('connect', {
        'config': config,
        'serverName': server.name,
      });
      
      if (result != true) {
        throw Exception('Не удалось запустить VPN');
      }
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Ошибка платформы';
      _updateState(VpnConnectionState.error);
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(VpnConnectionState.error);
    }
  }
  
  /// Отключается от VPN
  Future<void> disconnect() async {
    if (_state.isDisconnected || _state.isTransitioning) return;
    
    _updateState(VpnConnectionState.disconnecting);
    
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Ошибка отключения';
      _updateState(VpnConnectionState.error);
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(VpnConnectionState.error);
    }
  }
  
  /// Переключает состояние VPN
  Future<void> toggle() async {
    if (_state.isConnected) {
      await disconnect();
    } else if (_state.isDisconnected || _state == VpnConnectionState.error) {
      await connect();
    }
  }
  
  /// Проверяет статус VPN
  Future<void> checkStatus() async {
    try {
      final result = await _channel.invokeMethod('getStatus');
      if (result is Map) {
        final stateStr = result['state'] as String? ?? 'disconnected';
        _updateState(_parseState(stateStr));
      }
    } catch (e) {
      print('Error checking status: $e');
    }
  }
  
  @override
  void dispose() {
    _statsTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:convert';

class VlessConfig {
  final String id;
  final String uuid;
  final String address;
  final int port;
  final String security;
  final String type;
  final String? flow;
  final String? sni;
  final String? fingerprint;
  final String? publicKey;
  final String? shortId;
  final String? path;
  final String? host;
  final String name;
  final DateTime addedAt;
  
  VlessConfig({
    required this.id,
    required this.uuid,
    required this.address,
    required this.port,
    required this.security,
    required this.type,
    this.flow,
    this.sni,
    this.fingerprint,
    this.publicKey,
    this.shortId,
    this.path,
    this.host,
    required this.name,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();
  
  /// Парсит VLESS ссылку и создаёт конфигурацию
  /// Формат: vless://uuid@server:port?params#name
  static VlessConfig? fromUri(String uri) {
    try {
      if (!uri.startsWith('vless://')) {
        return null;
      }
      
      // Remove vless:// prefix
      String data = uri.substring(8);
      
      // Extract name from fragment
      String name = 'Unnamed Server';
      if (data.contains('#')) {
        final parts = data.split('#');
        data = parts[0];
        name = Uri.decodeComponent(parts[1]);
      }
      
      // Extract query parameters
      Map<String, String> params = {};
      if (data.contains('?')) {
        final parts = data.split('?');
        data = parts[0];
        final queryString = parts[1];
        
        for (final param in queryString.split('&')) {
          final kv = param.split('=');
          if (kv.length == 2) {
            params[kv[0]] = Uri.decodeComponent(kv[1]);
          }
        }
      }
      
      // Extract uuid@address:port
      final atIndex = data.indexOf('@');
      if (atIndex == -1) return null;
      
      final uuid = data.substring(0, atIndex);
      final serverPart = data.substring(atIndex + 1);
      
      // Parse address and port (handle IPv6)
      String address;
      int port;
      
      if (serverPart.contains('[')) {
        // IPv6
        final bracketEnd = serverPart.indexOf(']');
        address = serverPart.substring(1, bracketEnd);
        port = int.parse(serverPart.substring(bracketEnd + 2));
      } else {
        final colonIndex = serverPart.lastIndexOf(':');
        address = serverPart.substring(0, colonIndex);
        port = int.parse(serverPart.substring(colonIndex + 1));
      }
      
      return VlessConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uuid: uuid,
        address: address,
        port: port,
        security: params['security'] ?? 'none',
        type: params['type'] ?? 'tcp',
        flow: params['flow']?.isNotEmpty == true ? params['flow'] : null,
        sni: params['sni']?.isNotEmpty == true ? params['sni'] : null,
        fingerprint: params['fp']?.isNotEmpty == true ? params['fp'] : null,
        publicKey: params['pbk']?.isNotEmpty == true ? params['pbk'] : null,
        shortId: params['sid']?.isNotEmpty == true ? params['sid'] : null,
        path: params['path']?.isNotEmpty == true ? params['path'] : null,
        host: params['host']?.isNotEmpty == true ? params['host'] : null,
        name: name,
      );
    } catch (e) {
      print('Error parsing VLESS URI: $e');
      return null;
    }
  }
  
  /// Конвертирует в формат конфигурации sing-box
  Map<String, dynamic> toSingboxOutbound() {
    final outbound = <String, dynamic>{
      'type': 'vless',
      'tag': 'proxy',
      'server': address,
      'server_port': port,
      'uuid': uuid,
    };
    
    if (flow != null) {
      outbound['flow'] = flow;
    }
    
    // TLS settings
    if (security == 'reality') {
      outbound['tls'] = {
        'enabled': true,
        'server_name': sni ?? address,
        'utls': {
          'enabled': true,
          'fingerprint': fingerprint ?? 'chrome',
        },
        'reality': {
          'enabled': true,
          'public_key': publicKey,
          'short_id': shortId ?? '',
        },
      };
    } else if (security == 'tls') {
      outbound['tls'] = {
        'enabled': true,
        'server_name': sni ?? address,
        'utls': {
          'enabled': true,
          'fingerprint': fingerprint ?? 'chrome',
        },
      };
    }
    
    // Transport settings
    if (type == 'ws') {
      outbound['transport'] = {
        'type': 'ws',
        'path': path ?? '/',
        'headers': host != null ? {'Host': host} : null,
      };
    } else if (type == 'grpc') {
      outbound['transport'] = {
        'type': 'grpc',
        'service_name': path ?? '',
      };
    }
    
    return outbound;
  }
  
  /// Генерирует полную конфигурацию sing-box
  String toSingboxConfig() {
    final config = {
      'log': {
        'level': 'debug',
        'timestamp': true,
      },
      'dns': {
        'servers': [
          {
            'tag': 'dns-remote',
            'address': '1.1.1.1',
            'detour': 'proxy',
          },
          {
            'tag': 'dns-local',
            'address': 'local',
          },
          {
            'tag': 'dns-block',
            'address': 'rcode://success',
          },
        ],
        'rules': [
          {
            'outbound': ['any'],
            'server': 'dns-local',
          },
        ],
        'final': 'dns-remote',
        'strategy': 'prefer_ipv4',
        'independent_cache': true,
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'inet4_address': '172.19.0.1/30',
          'inet6_address': 'fdfe:dcba:9876::1/126',
          'mtu': 9000,
          'auto_route': true,
          'strict_route': false,
          'endpoint_independent_nat': true,
          'stack': 'mixed',  // 'mixed' is best for Android
          'platform': {
            'http_proxy': {
              'enabled': false,
            },
          },
          'sniff': true,
          'sniff_override_destination': false,
        },
      ],
      'outbounds': [
        toSingboxOutbound(),
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        },
        {
          'type': 'dns',
          'tag': 'dns-out',
        },
      ],
      'route': {
        'auto_detect_interface': true,
        'override_android_vpn': true,
        'final': 'proxy',
        'rules': [
          {
            'protocol': 'dns',
            'outbound': 'dns-out',
          },
          {
            'ip_is_private': true,
            'outbound': 'direct',
          },
          {
            'domain_suffix': ['.local', '.lan'],
            'outbound': 'direct',
          },
        ],
      },
    };
    
    return const JsonEncoder.withIndent('  ').convert(config);
  }
  
  /// Конвертация в JSON для хранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'address': address,
      'port': port,
      'security': security,
      'type': type,
      'flow': flow,
      'sni': sni,
      'fingerprint': fingerprint,
      'publicKey': publicKey,
      'shortId': shortId,
      'path': path,
      'host': host,
      'name': name,
      'addedAt': addedAt.toIso8601String(),
    };
  }
  
  /// Создание из JSON
  factory VlessConfig.fromJson(Map<String, dynamic> json) {
    return VlessConfig(
      id: json['id'],
      uuid: json['uuid'],
      address: json['address'],
      port: json['port'],
      security: json['security'],
      type: json['type'],
      flow: json['flow'],
      sni: json['sni'],
      fingerprint: json['fingerprint'],
      publicKey: json['publicKey'],
      shortId: json['shortId'],
      path: json['path'],
      host: json['host'],
      name: json['name'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
  
  /// Отображаемое имя сервера
  String get displayName {
    // Очищаем имя от emoji и лишних символов для отображения
    return name
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();
  }
  
  /// Короткий адрес для отображения
  String get shortAddress => '$address:$port';
  
  /// Тип протокола для отображения
  String get protocolDisplay {
    if (security == 'reality') {
      return 'VLESS + Reality';
    } else if (security == 'tls') {
      return 'VLESS + TLS';
    }
    return 'VLESS';
  }
  
  @override
  String toString() => 'VlessConfig($name @ $address:$port)';
}

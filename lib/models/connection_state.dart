enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

extension ConnectionStateExtension on ConnectionState {
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Отключено';
      case ConnectionState.connecting:
        return 'Подключение...';
      case ConnectionState.connected:
        return 'Подключено';
      case ConnectionState.disconnecting:
        return 'Отключение...';
      case ConnectionState.error:
        return 'Ошибка';
    }
  }
  
  bool get isConnected => this == ConnectionState.connected;
  bool get isDisconnected => this == ConnectionState.disconnected;
  bool get isTransitioning => 
      this == ConnectionState.connecting || 
      this == ConnectionState.disconnecting;
}

class ConnectionStats {
  final int bytesIn;
  final int bytesOut;
  final Duration duration;
  final DateTime? connectedAt;
  
  const ConnectionStats({
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.duration = Duration.zero,
    this.connectedAt,
  });
  
  ConnectionStats copyWith({
    int? bytesIn,
    int? bytesOut,
    Duration? duration,
    DateTime? connectedAt,
  }) {
    return ConnectionStats(
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      duration: duration ?? this.duration,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
  
  String get downloadFormatted => _formatBytes(bytesIn);
  String get uploadFormatted => _formatBytes(bytesOut);
  String get durationFormatted => _formatDuration(duration);
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

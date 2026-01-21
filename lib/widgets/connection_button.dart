import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/connection_state.dart';
import '../theme/app_theme.dart';

class ConnectionButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onPressed;
  
  const ConnectionButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  @override
  State<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<ConnectionButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _updateAnimation();
  }
  
  @override
  void didUpdateWidget(ConnectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }
  
  void _updateAnimation() {
    if (widget.state.isTransitioning) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: _buildButton(),
      ),
    );
  }
  
  Widget _buildButton() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          _buildGlow(),
          
          // Rotating ring (when connecting/disconnecting)
          if (widget.state.isTransitioning)
            _buildRotatingRing(),
          
          // Main button
          _buildMainCircle(),
          
          // Inner content
          _buildInnerContent(),
        ],
      ),
    );
  }
  
  Widget _buildGlow() {
    final Color glowColor = switch (widget.state) {
      VpnConnectionState.connected => AppTheme.successColor,
      VpnConnectionState.connecting || VpnConnectionState.disconnecting => AppTheme.warningColor,
      VpnConnectionState.error => AppTheme.errorColor,
      _ => AppTheme.primaryColor,
    };
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(widget.state.isConnected ? 0.4 : 0.2),
            blurRadius: widget.state.isConnected ? 40 : 20,
            spreadRadius: widget.state.isConnected ? 10 : 5,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRotatingRing() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.transparent,
            width: 3,
          ),
          gradient: SweepGradient(
            colors: [
              AppTheme.warningColor.withOpacity(0),
              AppTheme.warningColor,
              AppTheme.warningColor.withOpacity(0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainCircle() {
    final Gradient gradient = switch (widget.state) {
      VpnConnectionState.connected => AppTheme.connectedGradient,
      VpnConnectionState.error => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
      _ => AppTheme.primaryGradient,
    };
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
  
  Widget _buildInnerContent() {
    final IconData icon = switch (widget.state) {
      VpnConnectionState.connected => Icons.power_settings_new,
      VpnConnectionState.connecting || VpnConnectionState.disconnecting => Icons.sync,
      VpnConnectionState.error => Icons.error_outline,
      _ => Icons.power_settings_new,
    };
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: widget.state.isTransitioning
          ? const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Icon(
              icon,
              key: ValueKey(icon),
              size: 60,
              color: Colors.white,
            ),
    );
  }
}

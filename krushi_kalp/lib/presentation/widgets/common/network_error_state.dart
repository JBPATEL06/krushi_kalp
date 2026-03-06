import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../providers/network_provider.dart';
import '../../../core/theme/app_spacing.dart';

/// A premium, animated network error state widget.
/// Supports both full-page and compact inline variants.
class NetworkErrorState extends StatefulWidget {
  final VoidCallback? onRetry;
  final String? message;
  final bool compact;

  const NetworkErrorState({
    super.key,
    this.onRetry,
    this.message,
    this.compact = false,
  });

  @override
  State<NetworkErrorState> createState() => _NetworkErrorStateState();
}

class _NetworkErrorStateState extends State<NetworkErrorState>
    with TickerProviderStateMixin {
  bool _isRetrying = false;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  // Pulse animation for the icon
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Signal wave animations
  late final AnimationController _waveController;
  late final List<Animation<double>> _waveOpacities;
  late final List<Animation<double>> _waveScales;

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn =
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOutCubic));

    // Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Signal waves (3 concentric rings)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _waveOpacities = List.generate(3, (i) {
      final delay = i * 0.25;
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 80),
      ]).animate(CurvedAnimation(
        parent: _waveController,
        curve: Interval(delay.clamp(0, 1), 1.0, curve: Curves.easeOut),
      ));
    });

    _waveScales = List.generate(3, (i) {
      final delay = i * 0.25;
      return Tween<double>(begin: 1.0, end: 2.4).animate(CurvedAnimation(
        parent: _waveController,
        curve: Interval(delay.clamp(0, 1), 1.0, curve: Curves.easeOut),
      ));
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying || widget.onRetry == null) return;
    setState(() => _isRetrying = true);

    final isConnected = await NetworkProvider().checkConnectivity();
    if (isConnected && widget.onRetry != null) {
      widget.onRetry!();
    }

    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact(context);
    return _buildFull(context);
  }

  // ── Compact variant ─────────────────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 18, color: theme.colorScheme.error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.message ?? 'No internet connection',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _isRetrying ? null : _handleRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: _isRetrying
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Full-page variant ───────────────────────────────────────────────────────

  Widget _buildFull(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedIcon(),
                const SizedBox(height: AppSpacing.xl),
                _buildTextBlock(),
                const SizedBox(height: AppSpacing.xl),
                if (widget.onRetry != null) _buildRetryButton(),
                const SizedBox(height: AppSpacing.lg),
                _buildTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric signal waves
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => Transform.scale(
                scale: _waveScales[i].value,
                child: Opacity(
                  opacity: _waveOpacities[i].value,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Centre icon bubble
          ScaleTransition(
            scale: _pulseScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withOpacity(0.20),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error.withOpacity(0.15),
                      theme.colorScheme.error.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.wifi_off_rounded,
                    size: 34, color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'No Internet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          widget.message ?? 'Check your Wi-Fi or mobile data\nand try again.',
          style: TextStyle(
            fontSize: 14.5,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation:
          _isRetrying ? const AlwaysStoppedAnimation(0) : _pulseController,
      builder: (_, child) {
        final glow = _isRetrying
            ? 0.0
            : math.sin(_pulseController.value * math.pi) * 0.12;
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.28 + glow),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isRetrying ? null : _handleRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor:
                  theme.colorScheme.primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _isRetrying
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Connecting...',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Try Again',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTips() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try these steps:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            'Toggle airplane mode off and on',
            'Switch between Wi-Fi and mobile data',
            'Move to an area with better signal',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: theme.colorScheme.outlineVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to check if an error is network-related
bool isNetworkError(dynamic error) {
  if (error == null) return false;
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('handshakeexception') ||
      s.contains('connection timed out') ||
      s.contains('network is unreachable') ||
      s.contains('no internet') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('connection closed') ||
      s.contains('check your connection') ||
      s.contains('failed to load') ||
      s.contains('network error') ||
      s.contains('unable to load');
}

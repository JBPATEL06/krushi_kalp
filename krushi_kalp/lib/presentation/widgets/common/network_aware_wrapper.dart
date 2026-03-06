import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/network_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../utils/navigator_key.dart';

/// Route name used to identify the No-Internet gate on the navigator stack.
const String _kNoInternetRoute = '/no-internet';

/// Global network-aware wrapper.
///
/// Sits inside MaterialApp.builder so it has access to the navigator.
/// When connectivity is lost → pushes [NoInternetScreen] on top of everything.
/// When connectivity returns → pops [NoInternetScreen] automatically.
/// Back-button on [NoInternetScreen] → exits the app.
class NetworkAwareWrapper extends StatefulWidget {
  final Widget child;

  const NetworkAwareWrapper({super.key, required this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> {
  bool _isNoInternetVisible = false;

  @override
  void initState() {
    super.initState();
    // Listen after the first frame so navigatorKey.currentState is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = NetworkProvider();
      networkProvider.addListener(_onConnectivityChanged);
      // Check current state immediately
      if (networkProvider.isInitialized && !networkProvider.isConnected) {
        _showGate();
      }
    });
  }

  @override
  void dispose() {
    NetworkProvider().removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    final isConnected = NetworkProvider().isConnected;
    if (!isConnected && !_isNoInternetVisible) {
      _showGate();
    } else if (isConnected && _isNoInternetVisible) {
      _hideGate();
    }
  }

  void _showGate() {
    if (_isNoInternetVisible) return;
    _isNoInternetVisible = true;

    navigatorKey.currentState?.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: _kNoInternetRoute),
        pageBuilder: (_, __, ___) => const NoInternetScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
        barrierDismissible: false,
      ),
    );
  }

  void _hideGate() {
    if (!_isNoInternetVisible) return;
    _isNoInternetVisible = false;

    // Pop only the NoInternet route — leave everything below intact.
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.settings.name != _kNoInternetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also provide NetworkProvider to the widget tree for other consumers.
    return ChangeNotifierProvider<NetworkProvider>.value(
      value: NetworkProvider(),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Full-screen No Internet gate
// ═══════════════════════════════════════════════════════════════════════════

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  bool _isRetrying = false;

  // Entrance
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Icon pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Ripple waves
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    await NetworkProvider().checkConnectivity();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(theme),
                    const SizedBox(height: 32),
                    _buildText(theme),
                    const SizedBox(height: 32),
                    _buildRetryButton(theme),
                    const SizedBox(height: 20),
                    _buildExitButton(theme),
                    const SizedBox(height: 28),
                    _buildTipsCard(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 ripple rings
          ...List.generate(3, (i) {
            final delay = i * 0.28;
            final waveScale = Tween<double>(begin: 1.0, end: 2.6).animate(
              CurvedAnimation(
                parent: _waveCtrl,
                curve: Interval(delay.clamp(0, 1), 1.0, curve: Curves.easeOut),
              ),
            );
            final waveOpacity = TweenSequence<double>([
              TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: 0.35), weight: 15),
              TweenSequenceItem(
                  tween: Tween(begin: 0.35, end: 0.0), weight: 85),
            ]).animate(CurvedAnimation(
              parent: _waveCtrl,
              curve: Interval(delay.clamp(0, 1), 1.0, curve: Curves.easeOut),
            ));

            return AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => Transform.scale(
                scale: waveScale.value,
                child: Opacity(
                  opacity: waveOpacity.value,
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

          // Centre bubble
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.error.withValues(alpha: 0.18),
                      theme.colorScheme.error.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 38,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(ThemeData theme) {
    return Column(
      children: [
        Text(
          'No Internet',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'You are offline. Please restore your\nconnection to continue.',
          style: TextStyle(
            fontSize: 14.5,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRetryButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final glow =
            _isRetrying ? 0.0 : math.sin(_pulseCtrl.value * math.pi) * 0.14;
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.26 + glow),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isRetrying ? null : _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _isRetrying
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Checking...',
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

  Widget _buildExitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => SystemNavigator.pop(),
        icon: Icon(Icons.exit_to_app_rounded,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        label: Text(
          'Exit App',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Try these:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            'Toggle airplane mode off and back on',
            'Switch between Wi-Fi and mobile data',
            'Move to an area with better signal',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: theme.colorScheme.outline),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4)),
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

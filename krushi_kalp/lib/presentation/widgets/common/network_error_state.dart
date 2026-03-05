import 'package:flutter/material.dart';
import '../../providers/network_provider.dart';

/// A reusable widget that displays a network error state inline.
/// Used when StreamBuilder or FutureBuilder encounters a network error.
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

class _NetworkErrorStateState extends State<NetworkErrorState> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying || widget.onRetry == null) return;

    setState(() => _isRetrying = true);

    // Check connectivity first
    final isConnected = await NetworkProvider().checkConnectivity();

    if (isConnected && widget.onRetry != null) {
      widget.onRetry!();
    }

    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactVersion(context);
    }
    return _buildFullVersion(context);
  }

  Widget _buildCompactVersion(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 32,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            widget.message ?? 'No connection',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isRetrying ? null : _handleRetry,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullVersion(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.error.withValues(alpha: 0.15),
                    theme.colorScheme.error.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Connection Error',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              widget.message ??
                  'Unable to load data. Please check your internet connection.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Retry button
            if (widget.onRetry != null)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(_isRetrying ? 'Retrying...' : 'Try Again'),
                ),
              ),
          ],
        ),
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

import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// A mixin for [State] objects that perform file picking.
///
/// On MIUI devices, a running foreground service causes
/// `fail in deliverResultsIfNeeded` (ActivityThread NPE) when the OS tries
/// to pass the picker result back to the app. The fix is to demote the
/// service from foreground → background BEFORE opening the picker, then
/// re-promote it AFTER the app resumes.
///
/// All admin screens should call [safePickFiles] instead of
/// `FilePicker.platform.pickFiles` directly.
mixin PickerLifecycleMixin<T extends StatefulWidget> on State<T> {
  bool _isPicking = false;
  _PickerObserver? _observer;

  /// Returns true if a picking operation is currently in progress.
  bool get isPicking => _isPicking;

  /// Sets the picking status and triggers a rebuild.
  set isPicking(bool value) {
    if (_isPicking != value) {
      if (mounted) {
        setState(() => _isPicking = value);
      } else {
        _isPicking = value;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _observer = _PickerObserver(this);
    WidgetsBinding.instance.addObserver(_observer!);
  }

  @override
  void dispose() {
    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
    }
    super.dispose();
  }

  /// MIUI-safe file picker.
  ///
  /// Stops the foreground service before opening the native
  /// picker activity. This prevents the MIUI `ActivityThread` NPE crash
  /// (`fail in deliverResultsIfNeeded`) that happens when a foreground
  /// service is active during Activity result delivery.
  ///
  /// Restarts the service once the picker result has been received (or
  /// the user cancels). The [isPicking] flag is managed automatically.
  Future<FilePickerResult?> safePickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (isPicking) return null;
    isPicking = true;

    bool serviceWasRunning = false;
    final service = FlutterBackgroundService();

    try {
      // ── MIUI fix: stop foreground service before opening picker ────────
      serviceWasRunning = await service.isRunning();
      if (serviceWasRunning) {
        service.invoke('stopService');
        // Small delay to allow the service state to settle before the picker
        // activity is launched on top of MainActivity.
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false, // Zero-memory: always use path, never bytes
      );

      return result;
    } catch (e) {
      debugPrint('[PickerLifecycleMixin] Picker error: $e');
      return null;
    } finally {
      // Restart service
      if (serviceWasRunning) {
         try {
           await service.startService();
         } catch (_) {}
      }
      isPicking = false;
    }
  }
}

/// Private helper that extends [WidgetsBindingObserver] to avoid
/// having to implement every single method in the mixin itself.
class _PickerObserver extends WidgetsBindingObserver {
  final PickerLifecycleMixin _state;

  _PickerObserver(this._state);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_state.isPicking) {
        debugPrint('[PickerLifecycleMixin] App resumed while picking. Force resetting flag.');
        // We do NOT unconditionally startService here, because it causes ghost 
        // Foreground notifications on every app reboot/resume!
        _state.isPicking = false;
      }
    }
  }
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Thin wrapper around the native Google Play In-App Update flow.
///
/// - Android + installed from Play  -> shows Play's native update UI.
/// - Anything else (iOS, sideload, debug) -> silently no-ops.
///
/// Strategy: prefer an *immediate* (blocking, full-screen) update when Play
/// allows it, otherwise fall back to a *flexible* (background download) update
/// and install it as soon as the download finishes.
class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  bool _checkInProgress = false;
  StreamSubscription<InstallStatus>? _installSub;

  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid || _checkInProgress) return;
    _checkInProgress = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await _runFlexibleUpdate();
      }
    } catch (e) {
      // Not on Play, offline, debug build, user dismissed, etc. Never crash.
      debugPrint('InAppUpdate check skipped: $e');
    } finally {
      _checkInProgress = false;
    }
  }

  Future<void> _runFlexibleUpdate() async {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((status) async {
      if (status == InstallStatus.downloaded) {
        try {
          await InAppUpdate.completeFlexibleUpdate();
        } catch (e) {
          debugPrint('completeFlexibleUpdate failed: $e');
        }
      }
    });

    final result = await InAppUpdate.startFlexibleUpdate();
    if (result == AppUpdateResult.success) {
      // Some Play versions don't emit `downloaded` reliably; try to finish.
      try {
        await InAppUpdate.completeFlexibleUpdate();
      } catch (_) {}
    }
  }

  void dispose() {
    _installSub?.cancel();
    _installSub = null;
  }
}

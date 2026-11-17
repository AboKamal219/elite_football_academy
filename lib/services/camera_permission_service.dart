// lib/services/camera_permission_service.dart
//
// One place that decides "may I open the camera?".
//  * iOS  : needs NSCameraUsageDescription (already in Info.plist) AND the
//           PERMISSION_CAMERA=1 flag in ios/Podfile — without the flag
//           permission_handler answers "denied" without ever showing the prompt.
//  * Android: needs <uses-permission CAMERA> (already in the manifest).
//  * Web  : the browser asks by itself when the stream opens.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

enum CameraAccess {
  /// Camera can be opened.
  granted,

  /// Not allowed (yet). Asking again may show the system prompt.
  denied,

  /// The system will not show the prompt again (or a policy blocks it).
  /// The only way out is the app settings page.
  blocked,
}

class CameraPermissionService {
  const CameraPermissionService._();

  static CameraAccess _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return CameraAccess.granted;
    if (s.isPermanentlyDenied || s.isRestricted) return CameraAccess.blocked;
    return CameraAccess.denied;
  }

  /// Current state, never shows a prompt.
  static Future<CameraAccess> check() async {
    if (kIsWeb) return CameraAccess.granted;
    return _map(await Permission.camera.status);
  }

  /// Shows the system prompt when it is still allowed to.
  static Future<CameraAccess> request() async {
    if (kIsWeb) return CameraAccess.granted;
    final current = await Permission.camera.status;
    if (current.isGranted || current.isLimited) return CameraAccess.granted;
    if (current.isPermanentlyDenied || current.isRestricted) {
      return CameraAccess.blocked;
    }
    return _map(await Permission.camera.request());
  }

  /// Opens the OS settings page of this app.
  static Future<bool> openSettings() => openAppSettings();
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission management for Smart Cricket Bat app
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  /// Request all necessary permissions for the app
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      // Camera permissions
      Permission.camera,

      // Storage permissions
      Permission.storage,
      Permission.manageExternalStorage,

      // Bluetooth permissions
      Permission.bluetoothScan,
      Permission.bluetoothConnect,

      // Location permissions (required for BLE)
      Permission.location,
      Permission.locationWhenInUse,

      // Microphone permissions (for video recording)
      Permission.microphone,
    ];

    final results = <Permission, PermissionStatus>{};

    for (final permission in permissions) {
      final status = await permission.request();
      results[permission] = status;

      if (status.isDenied || status.isPermanentlyDenied) {
        print('Permission denied: $permission - $status');
      }
    }

    return results;
  }

  /// Check if all critical permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final permissions = [
      Permission.camera,
      Permission.storage,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }

    return true;
  }

  /// Get permission status for specific permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Show permission rationale dialog
  Future<bool?> showPermissionDialog(
    BuildContext context,
    Permission permission,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${permission.toString().split('.').last} Permission Required',
        ),
        content: Text(
          'This app needs ${permission.toString().split('.').last} permission to function properly. '
          'Please grant the permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

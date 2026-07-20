import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      bool allGranted = await _requestRequiredPermissions();

      if (allGranted && mounted) {
        // Automatically check if Bluetooth adapter is strictly ON
        final state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.on && mounted) {
          context.go('/ble-scan');
        } else {
             // Let user turn it on
             if (Platform.isAndroid) FlutterBluePlus.turnOn();
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestRequiredPermissions() async {
    // Basic structural request for permissions based on flutter_blue_plus rules
    if (Platform.isAndroid) {
      if (await Permission.bluetoothScan.isGranted && 
          await Permission.bluetoothConnect.isGranted) {
            return true;
      }
      
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();

      // In Android 12+ location is strictly optional if neverForLocation is used, but we request it for fallback
      return scanStatus.isGranted && connectStatus.isGranted;
    }
    
    // iOS auto-prompts on first BLE action but we can gate it
    if (Platform.isIOS) {
       final status = await Permission.bluetooth.request();
       return status.isGranted;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.bluetooth_searching, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Bluetooth Required',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'KnoQ needs Bluetooth access to connect to your bat sensor and record your shots.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              KnoqButton(
                text: 'Grant Permissions',
                isLoading: _isLoading,
                onPressed: _checkPermissions,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings Manually'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Cancel & Return Home', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

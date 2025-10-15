import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../providers/providers.dart';
import '../../services/ble_service.dart';
import '../../services/error_handler.dart';
import '../dashboard/dashboard_screen.dart';

/// Screen for scanning and connecting to Smart Bat devices
class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen> {
  bool _isScanning = false;
  BLEException? _lastError;
  final ErrorHandler _errorHandler = ErrorHandler();

  @override
  void initState() {
    super.initState();
    _initializeBLE();
    _listenToErrors();
  }

  @override
  void dispose() {
    _errorHandler.dispose();
    super.dispose();
  }

  /// Listen to BLE errors
  void _listenToErrors() {
    _errorHandler.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _lastError = error;
        });
      }
    });
  }

  /// Initialize BLE service with enhanced error handling
  Future<void> _initializeBLE() async {
    try {
      final bleService = ref.read(bleServiceProvider);
      final initialized = await bleService.initialize();

      if (!initialized) {
        _errorHandler.handleBLEError(
          BLEException(
            'Failed to initialize Bluetooth',
            BLEErrorType.permission,
          ),
          context: 'BLE Initialization',
        );
      }
    } catch (e) {
      _errorHandler.handleError(e, context: 'BLE Initialization');
    }
  }

  /// Start scanning for Smart Bat devices with enhanced error handling
  Future<void> _startScan() async {
    try {
      setState(() {
        _isScanning = true;
        _lastError = null;
      });

      final bleService = ref.read(bleServiceProvider);
      await bleService.scanForDevice(timeout: const Duration(seconds: 15));
    } catch (e) {
      _errorHandler.handleError(e, context: 'Device Scanning');
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Connect to a specific device with enhanced error handling
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _lastError = null;
      });

      final bleService = ref.read(bleServiceProvider);
      await bleService.connectToDevice(device);

      // Navigate to dashboard on successful connection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      _errorHandler.handleError(e, context: 'Device Connection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleConnection = ref.watch(bleConnectionProvider);
    final scannedDevices = ref.watch(bleScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Smart Bat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Bat Connection',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    bleConnection.when(
                      data: (isConnected) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : Icons.cancel,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error checking connection'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scan button
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Scanning...' : 'Scan for Smart Bat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Error message with enhanced display
            if (_lastError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorHandler.getUserFriendlyMessage(_lastError!),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorHandler.getRetrySuggestion(_lastError!.type),
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _lastError = null;
                            });
                            _startScan();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _lastError = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Dismiss'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Scanned devices
            Expanded(
              child: scannedDevices.when(
                data: (devices) {
                  if (devices.isEmpty && !_isScanning) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Smart Bat devices found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Make sure your Smart Bat is powered on and nearby',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.sports_cricket,
                            color: Colors.orange,
                          ),
                          title: Text(device.platformName),
                          subtitle: Text('RSSI: ${device.rssi} dBm'),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(device),
                            child: const Text('Connect'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Scanning for devices...'),
                    ],
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error scanning devices',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Connection Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure your Smart Bat is powered on\n'
                      '2. Ensure Bluetooth is enabled on your device\n'
                      '3. Tap "Scan for Smart Bat" to find nearby devices\n'
                      '4. Tap "Connect" next to your Smart Bat device\n'
                      '5. Wait for successful connection confirmation',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop scanning when leaving the screen
    if (_isScanning) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }
}

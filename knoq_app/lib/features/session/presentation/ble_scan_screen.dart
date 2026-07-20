import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/features/ble/providers/ble_provider.dart';
import 'package:knoq_app/features/ble/domain/ble_state.dart';

class BleScanScreen extends ConsumerStatefulWidget {
  const BleScanScreen({super.key});

  @override
  ConsumerState<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends ConsumerState<BleScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  
  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat();
    
    // Auto-start scan on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(bleProvider.notifier).scan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bleState = ref.watch(bleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bat'),
        leading: BackButton(onPressed: () async {
            await ref.read(bleProvider.notifier).stopScan();
            if (mounted) Navigator.pop(context);
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                 child: Stack(
                   alignment: Alignment.center,
                   children: [
                      // Radar ripple (only when scanning)
                      if (bleState.phase == BleConnectionPhase.scanning)
                         FadeTransition(
                            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_radarController),
                            child: ScaleTransition(
                               scale: Tween<double>(begin: 1.0, end: 3.0).animate(_radarController),
                               child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     color: theme.colorScheme.primary.withOpacity(0.3)
                                  ),
                               )
                            )
                         ),
                      // Core Icon
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: bleState.phase == BleConnectionPhase.connected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(Icons.bluetooth, size: 50, color: bleState.phase == BleConnectionPhase.connected ? Colors.white : theme.colorScheme.onSurfaceVariant),
                      )
                   ],
                 )
              ),
              const SizedBox(height: 32),
              
              if (bleState.phase == BleConnectionPhase.scanning || bleState.phase == BleConnectionPhase.disconnected)
                Expanded(child: _buildScanList(theme))
              else if (bleState.phase == BleConnectionPhase.connecting)
                 Expanded(child: Center(child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const CircularProgressIndicator(),
                     const SizedBox(height: 16),
                     Text('Connecting to KnoQ-Bat-V1...', style: theme.textTheme.bodyLarge),
                   ]
                 )))
              else if (bleState.phase == BleConnectionPhase.error)
                 Expanded(child: _buildError(theme, bleState.errorMessage))
              else if (bleState.phase == BleConnectionPhase.connected)
                 Expanded(child: Center(child: Text('Connected!', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary))))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanList(ThemeData theme) {
     return Column(
        children: [
           Text('Searching for KnoQ bats...', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
           const SizedBox(height: 24),
           Expanded(
             child: StreamBuilder<List<ScanResult>>(
               stream: FlutterBluePlus.scanResults,
               builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const Center(child: Text('No devices found yet. Make sure your bat is ON.'));
                  }
                  
                  return ListView.builder(
                     itemCount: snapshot.data!.length,
                     itemBuilder: (context, index) {
                        final result = snapshot.data![index];
                        return Card(
                           child: ListTile(
                              leading: const Icon(Icons.sports_cricket),
                              title: Text(result.device.platformName.isEmpty ? 'Unknown Device' : result.device.platformName),
                              subtitle: Text(result.device.remoteId.str),
                              trailing: KnoqButton(
                                text: 'Connect',
                                onPressed: () {
                                   ref.read(bleProvider.notifier).connect(result.device);
                                }
                              ),
                           )
                        );
                     }
                  );
               }
             )
           )
        ]
     );
  }

  Widget _buildError(ThemeData theme, String? errorMessage) {
     return Center(
        child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Connection failed', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(errorMessage ?? 'Unknown error occurred.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 24),
              KnoqButton(text: 'Retry Scan', onPressed: () => ref.read(bleProvider.notifier).scan())
           ]
        )
     );
  }
}

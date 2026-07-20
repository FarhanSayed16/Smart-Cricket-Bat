import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/core/widgets/bat_zone_diagram.dart';
import 'package:knoq_app/core/widgets/power_arc.dart';
import 'package:knoq_app/core/widgets/swing_speed_display.dart';
import 'package:knoq_app/core/widgets/zone_badge.dart';
import 'package:knoq_app/features/session/providers/session_provider.dart';
import 'package:knoq_app/features/ble/providers/ble_provider.dart';
import 'package:knoq_app/features/ble/domain/ble_state.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:knoq_app/features/session/services/video_sync_service.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // Keep screen awake during live session
    WakelockPlus.enable();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Select back camera
      final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      
      // Use high resolution for better pose extraction (user config can override this later)
      _cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      
      if (mounted) setState(() {});
      
      // Start recording immediately
      await _startRecording();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      await _cameraController!.startVideoRecording();
      ref.read(videoSyncServiceProvider).startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Error starting video: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    try {
      final file = await _cameraController!.stopVideoRecording();
      ref.read(videoSyncServiceProvider).stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      
      // Save video path to session meta so SessionSummaryScreen can upload it
      ref.read(liveSessionProvider.notifier).setVideoPath(file.path);
    } catch (e) {
      debugPrint('Error stopping video: $e');
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _confirmEndSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Are you sure you want to end this recording session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dContext, true), child: const Text('End', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldEnd == true && mounted) {
       await _stopRecording();
       await ref.read(liveSessionProvider.notifier).endSession();
       context.go('/session-summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bleState = ref.watch(bleProvider);
    final sessionState = ref.watch(liveSessionProvider);

    // Provide haptic feedback trigger on each new shot
    ref.listen(liveSessionProvider, (previous, next) {
        if ((previous?.liveStats.totalHits ?? 0) < next.liveStats.totalHits) {
            HapticFeedback.mediumImpact();
        }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _confirmEndSession();
      },
      child: Scaffold(
        appBar: AppBar(
           automaticallyImplyLeading: false,
           title: Row(
             children: [
               _buildConnectionDot(bleState),
               const SizedBox(width: 8),
               Expanded(
                 child: Text(
                   _getStatusText(bleState),
                   style: theme.textTheme.titleLarge,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
           actions: [
             IconButton(
               icon: const Icon(Icons.close),
               onPressed: _confirmEndSession,
             )
           ],
        ),
        body: Column(
          children: [
             // BLE status banner
             if (bleState.phase == BleConnectionPhase.disconnected || bleState.phase == BleConnectionPhase.reconnecting)
                Container(
                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                   width: double.infinity,
                   color: bleState.isReconnecting ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.15),
                   child: Text(
                     bleState.isReconnecting 
                       ? 'Reconnecting to Bat...'
                       : 'Device disconnected. Data is saved locally.',
                     textAlign: TextAlign.center, 
                     style: TextStyle(
                       color: bleState.isReconnecting ? Colors.orangeAccent : Colors.redAccent,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                ),
             
             // Top Dashboard stats
             Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('Hits', sessionState.liveStats.totalHits.toString(), theme),
                    _buildStatCol('Sweet', '${sessionState.liveStats.sweetSpotPct}%', theme),
                    _buildStatCol('Avg Pwr', sessionState.liveStats.avgPower.toString(), theme),
                    _buildStatCol('Peak', sessionState.liveStats.peakPower.toString(), theme),
                  ],
                ),
             ),

             Expanded(
               flex: 3,
               child: Stack(
                 children: [
                   // Camera Preview behind the gauges
                   if (_cameraController != null && _cameraController!.value.isInitialized)
                     Positioned.fill(
                       child: Opacity(
                         opacity: 0.3, // Keep it subtle so it doesn't distract from gauges
                         child: CameraPreview(_cameraController!),
                       ),
                     ),
                     
                   // Recording indicator
                   if (_isRecording)
                     Positioned(
                       top: 8,
                       right: 16,
                       child: Row(
                         children: [
                           Icon(Icons.circle, color: Colors.red, size: 12),
                           const SizedBox(width: 4),
                           const Text('REC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ),

                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       // Bat render diagram dynamically receiving zone hits
                       BatZoneDiagram(activeZone: sessionState.lastShotZone),
                       Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            PowerArc(value: sessionState.shots.isNotEmpty ? sessionState.shots.last.power : 0),
                            const SizedBox(height: 16),
                            SwingSpeedDisplay(swing: sessionState.shots.isNotEmpty ? sessionState.shots.last.swing : null),
                         ],
                       )
                     ],
                   ),
                 ],
               )
             ),

             // History List Tail — last 5 shots, newest first
             Expanded(
               flex: 2,
               child: Container(
                 decoration: BoxDecoration(
                   color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                 ),
                 child: sessionState.shots.isEmpty
                   ? const Center(child: Text('Waiting for shots...', style: TextStyle(color: Colors.grey)))
                   : ListView.builder(
                       padding: const EdgeInsets.only(top: 16, bottom: 80),
                       itemCount: sessionState.shots.length > 5 ? 5 : sessionState.shots.length,
                       itemBuilder: (context, i) {
                         final reversedList = sessionState.shots.reversed.toList();
                         final shot = reversedList[i];
                         return ListTile(
                           leading: ZoneBadge(zone: shot.zone),
                           title: Text('Shot #${shot.hit} — Power: ${shot.power}'),
                           trailing: shot.swing != null ? Text('${shot.swing!.toStringAsFixed(1)}°/s') : null,
                         );
                       },
                     ),
               )
             ),
          ],
        ),
        bottomSheet: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: KnoqButton(
               text: 'End Session',
               type: KnoqButtonType.danger,
               onPressed: _confirmEndSession,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionDot(BleState bleState) {
    Color color;
    switch (bleState.phase) {
      case BleConnectionPhase.connected:
        color = Colors.green;
        break;
      case BleConnectionPhase.reconnecting:
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }
    return Icon(Icons.circle, size: 12, color: color);
  }

  String _getStatusText(BleState bleState) {
    switch (bleState.phase) {
      case BleConnectionPhase.connected:
        return 'Live Session';
      case BleConnectionPhase.reconnecting:
        return 'Reconnecting...';
      case BleConnectionPhase.disconnected:
        return 'Disconnected';
      default:
        return 'Session Active';
    }
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
     return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
     );
  }
}

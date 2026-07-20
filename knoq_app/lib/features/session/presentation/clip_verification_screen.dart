import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:knoq_app/core/constants/api_endpoints.dart';
import 'package:knoq_app/core/widgets/zone_badge.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

/// A screen that shows extracted clips for each shot in a session,
/// allowing the user to verify alignment and adjust the offset.
class ClipVerificationScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ClipVerificationScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ClipVerificationScreen> createState() => _ClipVerificationScreenState();
}

class _ClipVerificationScreenState extends ConsumerState<ClipVerificationScreen> {
  List<Map<String, dynamic>> _clips = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  double _offsetAdjustment = 0; // ms adjustment from current offset

  @override
  void initState() {
    super.initState();
    _loadClips();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadClips() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(ApiEndpoints.sessionClips(widget.sessionId));
      final data = response.data['data'] as List;

      setState(() {
        _clips = data.where((c) => c['clip_url'] != null).map((c) => Map<String, dynamic>.from(c)).toList();
        _isLoading = false;
      });

      if (_clips.isNotEmpty) {
        _initializeVideo(0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load clips: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initializeVideo(int index) async {
    _videoController?.dispose();

    final clip = _clips[index];
    final url = clip['clip_url'] as String;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    await _videoController!.play();

    setState(() {
      _currentIndex = index;
      _offsetAdjustment = 0;
    });
  }

  Future<void> _saveAdjustment() async {
    if (_offsetAdjustment == 0) return;

    final clip = _clips[_currentIndex];
    final currentOffset = (clip['video_offset_ms'] as int?) ?? 0;
    final newOffset = currentOffset + _offsetAdjustment.round();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.put(
        ApiEndpoints.shotOffset(widget.sessionId, clip['shot_number'] as int),
        data: {'video_offset_ms': newOffset},
      );

      setState(() {
        _clips[_currentIndex]['video_offset_ms'] = newOffset;
        _offsetAdjustment = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offset saved ✓'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Clips (${_clips.length})'),
        actions: [
          if (_clips.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1} / ${_clips.length}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No clips available yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Clips are being processed in the background.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Video Player
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black,
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),

                    // Shot Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
                      ),
                      child: Row(
                        children: [
                          ZoneBadge(zone: _clips[_currentIndex]['zone'] ?? 'Sweet'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shot #${_clips[_currentIndex]['shot_number']} — Power: ${_clips[_currentIndex]['power']}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Offset: ${_clips[_currentIndex]['video_offset_ms']}ms',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alignment Adjustment Slider
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Adjust Impact Alignment',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'If the impact is not centered in the clip, drag the slider to adjust.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Earlier', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Expanded(
                                  child: Slider(
                                    value: _offsetAdjustment,
                                    min: -2000,
                                    max: 2000,
                                    divisions: 40,
                                    label: '${_offsetAdjustment > 0 ? '+' : ''}${_offsetAdjustment.round()}ms',
                                    onChanged: (val) => setState(() => _offsetAdjustment = val),
                                  ),
                                ),
                                const Text('Later', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Text(
                              _offsetAdjustment == 0
                                  ? 'No adjustment'
                                  : 'Adjust: ${_offsetAdjustment > 0 ? '+' : ''}${_offsetAdjustment.round()}ms',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _offsetAdjustment == 0 ? Colors.grey : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Navigation & Save
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton.filled(
                                  onPressed: _currentIndex > 0 ? () => _initializeVideo(_currentIndex - 1) : null,
                                  icon: const Icon(Icons.skip_previous),
                                ),
                                FilledButton.icon(
                                  onPressed: _offsetAdjustment != 0 ? _saveAdjustment : null,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Save Adjustment'),
                                ),
                                IconButton.filled(
                                  onPressed: _currentIndex < _clips.length - 1 ? () => _initializeVideo(_currentIndex + 1) : null,
                                  icon: const Icon(Icons.skip_next),
                                ),
                              ],
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

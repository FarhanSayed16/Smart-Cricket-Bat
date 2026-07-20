import 'package:flutter_riverpod/flutter_riverpod.dart';

final videoSyncServiceProvider = Provider((ref) => VideoSyncService());

class VideoSyncService {
  DateTime? _videoStartTimestamp;

  void startVideoRecording() {
    _videoStartTimestamp = DateTime.now();
  }

  void stopVideoRecording() {
    _videoStartTimestamp = null;
  }

  /// Calculates the offset in milliseconds from the start of the video
  /// to the current moment (when a BLE shot is received).
  int? getShotOffsetMs(DateTime shotTimestamp) {
    if (_videoStartTimestamp == null) return null;
    
    // offset = shotTimestamp - videoStartTimestamp
    final offsetMs = shotTimestamp.difference(_videoStartTimestamp!).inMilliseconds;
    return offsetMs > 0 ? offsetMs : 0;
  }

  bool get isRecording => _videoStartTimestamp != null;
}

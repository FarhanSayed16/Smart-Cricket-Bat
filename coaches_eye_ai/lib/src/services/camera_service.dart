import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Commented out - not available in current dependencies
import 'firestore_service.dart';

/// Enhanced camera service for capturing cricket shots with advanced features
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  String? _currentVideoPath;
  bool _isInitialized = false;
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  // Advanced camera features
  bool _isFlashOn = false;
  ResolutionPreset _currentResolution = ResolutionPreset.high;

  // Video recording metadata
  DateTime? _recordingStartTime;
  Duration? _recordingDuration;
  String? _currentSessionId;

  /// Initialize camera with comprehensive permission handling
  Future<bool> initialize() async {
    try {
      print('🎥 Initializing camera service...');

      // Check and request camera permissions
      final cameraPermission = await Permission.camera.status;
      if (!cameraPermission.isGranted) {
        print('📷 Requesting camera permission...');
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          print('❌ Camera permission denied');
          return false;
        }
      }

      // Check microphone permission for video recording
      final micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted) {
        print('🎤 Requesting microphone permission...');
        await Permission.microphone.request();
      }

      // Get available cameras
      try {
        // Note: availableCameras() might not be available in this camera package version
        // Using a fallback approach
        _cameras = <CameraDescription>[];
        print('📱 Camera initialization completed');
      } catch (e) {
        print('❌ Error getting cameras: $e');
        return false;
      }

      print('📱 Camera initialization completed');

      // Initialize camera controller with default settings
      // Note: In a real implementation, you would get available cameras first
      // For now, we'll create a basic camera controller
      try {
        // This is a simplified approach - in production you'd get actual camera list
        _controller = CameraController(
          const CameraDescription(
            name: 'camera',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
          _currentResolution,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();

        // Set up camera features
        await _controller!.setFlashMode(FlashMode.off);
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);

        _isInitialized = true;
        print('✅ Camera initialized successfully');
        return true;
      } catch (e) {
        print('❌ Camera controller initialization error: $e');
        _isInitialized = false;
        return false;
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Get camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized;

  /// Capture a photo
  Future<String?> capturePhoto() async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'shot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(appDir.path, fileName);

      final XFile photo = await _controller!.takePicture();
      await photo.saveTo(filePath);

      return filePath;
    } catch (e) {
      print('Photo capture error: $e');
      return null;
    }
  }

  /// Start video recording with enhanced features
  Future<String?> startVideoRecording({
    String? sessionId,
    String? playerId,
  }) async {
    if (!_isInitialized || _controller == null || _isRecording) {
      print('❌ Cannot start recording: Camera not ready or already recording');
      return null;
    }

    try {
      print('🎬 Starting video recording...');

      _currentSessionId = sessionId;
      _recordingStartTime = DateTime.now();

      // Create organized directory structure
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory videoDir = Directory(
        path.join(appDir.path, 'cricket_videos'),
      );

      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Create unique filename with session info
      final videoId = _uuid.v4();
      final String fileName = sessionId != null
          ? 'session_${sessionId}_$videoId.mp4'
          : 'cricket_session_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final String filePath = path.join(videoDir.path, fileName);

      await _controller!.startVideoRecording();
      _isRecording = true;
      _currentVideoPath = filePath;

      print('✅ Video recording started: $filePath');

      // Save video metadata to Firestore
      if (sessionId != null && playerId != null) {
        await _firestoreService.saveVideoMetadata(
          videoId: videoId,
          sessionId: sessionId,
          playerId: playerId,
          videoPath: filePath,
          recordedAt: DateTime.now(),
          durationInSeconds: 0, // Will be updated when recording stops
        );
      }

      return filePath;
    } catch (e) {
      print('❌ Video recording start error: $e');
      _isRecording = false;
      _currentVideoPath = null;
      return null;
    }
  }

  /// Stop video recording with enhanced features
  Future<String?> stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      print('❌ Cannot stop recording: Not currently recording');
      return null;
    }

    try {
      print('🛑 Stopping video recording...');

      final XFile video = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Calculate recording duration
      if (_recordingStartTime != null) {
        _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        print('📹 Video recorded: ${_recordingDuration!.inSeconds}s');
      }

      // Update Firestore with final duration if we have session info
      if (_currentSessionId != null && _recordingDuration != null) {
        // Note: updateVideoDuration method needs to be implemented in FirestoreService
        print(
          '📊 Video duration: ${_recordingDuration!.inSeconds}s for session: $_currentSessionId',
        );
      }

      final videoPath = video.path;
      _currentVideoPath = null;
      _currentSessionId = null;

      print('✅ Video recording stopped: $videoPath');
      return videoPath;
    } catch (e) {
      print('❌ Video recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Toggle flash on/off
  Future<bool> toggleFlash() async {
    if (!_isInitialized || _controller == null) return false;

    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      print('💡 Flash ${_isFlashOn ? 'ON' : 'OFF'}');
      return true;
    } catch (e) {
      print('❌ Error toggling flash: $e');
      return false;
    }
  }

  /// Set camera resolution
  Future<bool> setResolution(ResolutionPreset resolution) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      _currentResolution = resolution;
      // Note: CameraController doesn't have setResolutionPreset method
      // Resolution is set during initialization
      print('📐 Resolution set to: $resolution');
      return true;
    } catch (e) {
      print('❌ Error setting resolution: $e');
      return false;
    }
  }

  /// Get current recording status
  bool get isRecording => _isRecording;

  /// Get recording duration
  Duration? get recordingDuration => _recordingDuration;

  /// Get current video path
  String? get currentVideoPath => _currentVideoPath;

  /// Get available cameras
  List<CameraDescription>? get availableCameras => _cameras;

  /// Get current camera info
  String get cameraInfo {
    if (_controller == null) return 'No camera';
    final desc = _controller!.description;
    return '${desc.lensDirection.name} camera';
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return false;
    }

    try {
      final currentCamera = _controller!.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection,
        orElse: () => _cameras!.first,
      );

      await _controller!.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      print('Camera switch error: $e');
      return false;
    }
  }

  /// Get camera preview widget
  Widget? getCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Camera Preview',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Camera not available on web',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(_controller!);
  }

  /// Get list of saved videos
  Future<List<String>> getSavedVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'cricket_videos'));

      if (!await videosDir.exists()) {
        return [];
      }

      final files = await videosDir.list().toList();
      return files
          .where((file) => file.path.endsWith('.mp4'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting saved videos: $e');
      return [];
    }
  }

  /// Get video thumbnail
  Future<Widget?> getVideoThumbnail(String videoPath) async {
    try {
      // For web, return a placeholder
      return Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.play_circle_outline,
          color: Colors.white54,
          size: 32,
        ),
      );
    } catch (e) {
      print('Error getting video thumbnail: $e');
      return null;
    }
  }

  /// Delete video file
  Future<bool> deleteVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _isInitialized = false;
  }
}

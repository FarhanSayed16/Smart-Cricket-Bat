import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'firestore_service.dart';

/// Camera service for capturing cricket shots
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  String? _currentVideoPath;
  bool _isInitialized = false;
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  /// Initialize camera
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Initialize camera controller
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Camera initialization error: $e');
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

  /// Start video recording
  Future<String?> startVideoRecording({String? sessionId, String? playerId}) async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'session_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = path.join(appDir.path, fileName);

      await _controller!.startVideoRecording();
      _isRecording = true;
      _currentVideoPath = filePath;

      // Save video metadata to Firestore
      if (sessionId != null && playerId != null) {
        final videoId = _uuid.v4();
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
      print('Video recording start error: $e');
      return null;
    }
  }

  /// Stop video recording
  Future<String?> stopVideoRecording() async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      return video.path;
    } catch (e) {
      print('Video recording stop error: $e');
      return null;
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

}

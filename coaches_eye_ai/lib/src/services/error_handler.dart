import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'ble_service.dart';

/// Comprehensive error handling and logging service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final StreamController<BLEException> _errorController =
      StreamController<BLEException>.broadcast();

  Stream<BLEException> get errorStream => _errorController.stream;

  /// Handle BLE errors with proper logging and user feedback
  void handleBLEError(BLEException error, {String? context}) {
    // Log error with context
    final logMessage = context != null
        ? 'BLE Error in $context: ${error.message}'
        : 'BLE Error: ${error.message}';

    if (kDebugMode) {
      developer.log(logMessage, error: error);
    } else {
      // In production, log to crash reporting service
      _logToCrashReporting(error, context);
    }

    // Add to error stream for UI handling (only if not closed)
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  /// Handle generic errors
  void handleError(dynamic error, {String? context}) {
    final bleError = error is BLEException
        ? error
        : BLEException(error.toString(), BLEErrorType.unknown);

    handleBLEError(bleError, context: context);
  }

  /// Log to crash reporting service (Firebase Crashlytics)
  void _logToCrashReporting(BLEException error, String? context) {
    // TODO: Implement Firebase Crashlytics logging
    // FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(BLEException error) {
    switch (error.type) {
      case BLEErrorType.connection:
        return 'Connection failed. Please check if your Smart Bat is nearby and try again.';
      case BLEErrorType.permission:
        if (error.message.contains('LOCATION')) {
          return 'Location permission required for Bluetooth scanning. Please enable Location access in Settings > Apps > Coach\'s Eye AI > Permissions.';
        }
        return 'Bluetooth permission required. Please enable Bluetooth and Location access in settings.';
      case BLEErrorType.data:
        return 'Data transmission error. Please reconnect your Smart Bat.';
      case BLEErrorType.timeout:
        return 'Connection timeout. Please ensure your Smart Bat is powered on.';
      case BLEErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get retry suggestion based on error type
  String getRetrySuggestion(BLEErrorType type) {
    switch (type) {
      case BLEErrorType.connection:
        return 'Try moving closer to your Smart Bat and ensure it\'s powered on.';
      case BLEErrorType.permission:
        return 'Go to Settings > Apps > Coach\'s Eye AI > Permissions and enable Bluetooth.';
      case BLEErrorType.data:
        return 'Disconnect and reconnect your Smart Bat.';
      case BLEErrorType.timeout:
        return 'Check that your Smart Bat is charged and within range.';
      case BLEErrorType.unknown:
        return 'Restart the app and try again.';
    }
  }

  void dispose() {
    _errorController.close();
  }
}

/// Performance monitoring service
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End timing an operation
  void endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations.putIfAbsent(operationName, () => []).add(duration);

      if (kDebugMode) {
        developer.log(
          'Operation $operationName took ${duration.inMilliseconds}ms',
        );
      }
    }
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};

    for (final operation in _operationDurations.keys) {
      final avgDuration = getAverageDuration(operation);
      if (avgDuration != null) {
        metrics[operation] = {
          'averageMs': avgDuration.inMilliseconds,
          'sampleCount': _operationDurations[operation]!.length,
        };
      }
    }

    return metrics;
  }

  /// Clear old metrics
  void clearMetrics() {
    _operationDurations.clear();
  }
}

/// Data validation utilities
class DataValidator {
  /// Validate sensor data format
  static bool isValidSensorData(String data) {
    try {
      final parts = data.split(',');
      if (parts.length != 6) return false;

      for (final part in parts) {
        final value = double.tryParse(part.trim());
        if (value == null) return false;

        // Check for reasonable ranges
        if (value.isNaN || value.isInfinite) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate acceleration values
  static bool isValidAcceleration(double value) {
    return value >= -50.0 && value <= 50.0; // m/s²
  }

  /// Validate gyroscope values
  static bool isValidGyroscope(double value) {
    return value >= -1000.0 && value <= 1000.0; // degrees/s
  }

  /// Sanitize sensor data
  static Map<String, double> sanitizeSensorData(Map<String, double> data) {
    final sanitized = <String, double>{};

    for (final entry in data.entries) {
      final value = entry.value;
      if (!value.isNaN && !value.isInfinite) {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }
}

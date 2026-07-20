import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/core/errors/app_exceptions.dart';

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return CrashReportingService();
});

class CrashReportingService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  void initialize() {
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> setUserIdentifier(String? userId) async {
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    } else {
      await _crashlytics.setUserIdentifier('');
    }
  }

  /// Logs error and provides a user-friendly string
  String handleException(dynamic exception, [StackTrace? stacktrace]) {
    _crashlytics.log('CrashReportingService caught: $exception');
    
    if (exception is AppExceptions) {
      return exception.message;
    }
    
    // Log non-custom exceptions to crashlytics manually if not fatal bounds
    _crashlytics.recordError(exception, stacktrace);

    return 'An unexpected error occurred. Please try again.';
  }

  void log(String message) {
    _crashlytics.log(message);
  }
}

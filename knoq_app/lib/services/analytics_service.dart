import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // --- Auth Events ---
  Future<void> logLogin() async => await _analytics.logLogin(loginMethod: 'email');
  Future<void> logSignUp() async => await _analytics.logSignUp(signUpMethod: 'email');
  Future<void> logOnboardingComplete() async => await _analytics.logTutorialComplete();
  Future<void> logLogout() async => await _analytics.logEvent(name: 'logout');

  // --- Session Events ---
  Future<void> logSessionStarted() async => await _analytics.logEvent(name: 'session_started');
  Future<void> logShotReceived() async => await _analytics.logEvent(name: 'shot_received');
  Future<void> logSessionEnded(int totalShots) async {
    await _analytics.logEvent(
      name: 'session_ended',
      parameters: {'total_shots': totalShots},
    );
  }
  Future<void> logSessionSaved(String sessionId) async {
    await _analytics.logEvent(
      name: 'session_saved',
      parameters: {'session_id': sessionId},
    );
  }

  // --- BLE Events ---
  Future<void> logBleScanStarted() async => await _analytics.logEvent(name: 'ble_scan_started');
  Future<void> logBleConnected() async => await _analytics.logEvent(name: 'ble_connected');
  Future<void> logBleDisconnected() async => await _analytics.logEvent(name: 'ble_disconnected');

  // --- Feature Events ---
  Future<void> logAnalyticsViewed() async => await _analytics.logEvent(name: 'analytics_viewed');
  Future<void> logInsightViewed() async => await _analytics.logEvent(name: 'insight_viewed');
  Future<void> logProfileEdited() async => await _analytics.logEvent(name: 'profile_edited');

  // --- Coach Events ---
  Future<void> logPlayerViewed(String playerId) async {
    await _analytics.logEvent(
      name: 'player_viewed',
      parameters: {'player_id': playerId},
    );
  }
  Future<void> logNoteAdded(String sessionId) async {
    await _analytics.logEvent(
      name: 'note_added',
      parameters: {'session_id': sessionId},
    );
  }
  Future<void> logPlayersCompared() async => await _analytics.logEvent(name: 'players_compared');
  Future<void> logReportExported(String playerId) async {
    await _analytics.logEvent(
      name: 'report_exported',
      parameters: {'player_id': playerId},
    );
  }
}

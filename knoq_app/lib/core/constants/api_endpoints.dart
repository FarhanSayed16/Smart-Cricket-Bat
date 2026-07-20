/// All backend REST API endpoint paths.
/// Base URL is resolved by [EnvConfig.apiBaseUrl].
class ApiEndpoints {
  // Auth
  static const String authRegister = '/auth/register';

  // Users
  static const String usersMe = '/users/me';

  // Sessions
  static const String sessions = '/sessions';
  static String sessionById(String id) => '/sessions/$id';
  static String sessionShots(String id) => '/sessions/$id/shots';
  static String sessionClips(String id) => '/sessions/$id/clips';
  static String shotOffset(String sessionId, int shotNumber) => '/sessions/$sessionId/shots/$shotNumber/offset';

  // Academy
  static const String academyLookup = '/academy/lookup';
  static const String academyJoin = '/academy/join';

  // Devices
  static const String devices = '/devices';
  static String deviceById(String id) => '/devices/$id';

  // Coach
  static String coachNotes(String sessionId) => '/sessions/$sessionId/notes';

  // Analytics
  static const String analytics = '/analytics';
  static String playerAnalytics(String id) => '/analytics/player/$id';

  // Video Settings
  static String videoSettings(String academyId) => '/academy/$academyId/video-settings';

  // Health
  static const String health = '/health';
}

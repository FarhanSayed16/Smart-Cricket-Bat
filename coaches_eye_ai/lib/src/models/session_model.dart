/// Session model for Coach's Eye AI app
/// Represents a cricket practice session
class SessionModel {
  final String sessionId;
  final String playerId;
  final DateTime date;
  final int durationInMinutes;
  final int totalShots;
  final double averageBatSpeed;

  const SessionModel({
    required this.sessionId,
    required this.playerId,
    required this.date,
    required this.durationInMinutes,
    required this.totalShots,
    required this.averageBatSpeed,
  });

  /// Create SessionModel from Firestore document
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'] as String,
      playerId: json['playerId'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      durationInMinutes: json['durationInMinutes'] as int,
      totalShots: json['totalShots'] as int,
      averageBatSpeed: (json['averageBatSpeed'] as num).toDouble(),
    );
  }

  /// Convert SessionModel to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'playerId': playerId,
      'date': date.millisecondsSinceEpoch,
      'durationInMinutes': durationInMinutes,
      'totalShots': totalShots,
      'averageBatSpeed': averageBatSpeed,
    };
  }

  /// Create a copy of SessionModel with updated fields
  SessionModel copyWith({
    String? sessionId,
    String? playerId,
    DateTime? date,
    int? durationInMinutes,
    int? totalShots,
    double? averageBatSpeed,
  }) {
    return SessionModel(
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      date: date ?? this.date,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      totalShots: totalShots ?? this.totalShots,
      averageBatSpeed: averageBatSpeed ?? this.averageBatSpeed,
    );
  }

  @override
  String toString() {
    return 'SessionModel(sessionId: $sessionId, playerId: $playerId, date: $date, durationInMinutes: $durationInMinutes, totalShots: $totalShots, averageBatSpeed: $averageBatSpeed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel &&
        other.sessionId == sessionId &&
        other.playerId == playerId &&
        other.date == date &&
        other.durationInMinutes == durationInMinutes &&
        other.totalShots == totalShots &&
        other.averageBatSpeed == averageBatSpeed;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^
        playerId.hashCode ^
        date.hashCode ^
        durationInMinutes.hashCode ^
        totalShots.hashCode ^
        averageBatSpeed.hashCode;
  }
}

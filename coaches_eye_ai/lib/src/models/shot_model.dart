/// Shot model for Coach's Eye AI app
/// Represents a single cricket shot with sensor data
class ShotModel {
  final String shotId;
  final String sessionId;
  final DateTime timestamp;
  final double batSpeed; // in km/h
  final int powerIndex; // 0-100
  final double timingScore; // -50.0ms to +50.0ms
  final double sweetSpotAccuracy; // 0.0-1.0
  final String? coachNotes; // Optional coach feedback

  const ShotModel({
    required this.shotId,
    required this.sessionId,
    required this.timestamp,
    required this.batSpeed,
    required this.powerIndex,
    required this.timingScore,
    required this.sweetSpotAccuracy,
    this.coachNotes,
  });

  /// Create ShotModel from Firestore document
  factory ShotModel.fromJson(Map<String, dynamic> json) {
    return ShotModel(
      shotId: json['shotId'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      batSpeed: (json['batSpeed'] as num).toDouble(),
      powerIndex: json['powerIndex'] as int,
      timingScore: (json['timingScore'] as num).toDouble(),
      sweetSpotAccuracy: (json['sweetSpotAccuracy'] as num).toDouble(),
      coachNotes: json['coachNotes'] as String?,
    );
  }

  /// Convert ShotModel to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'shotId': shotId,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'batSpeed': batSpeed,
      'powerIndex': powerIndex,
      'timingScore': timingScore,
      'sweetSpotAccuracy': sweetSpotAccuracy,
      'coachNotes': coachNotes,
    };
  }

  /// Create a copy of ShotModel with updated fields
  ShotModel copyWith({
    String? shotId,
    String? sessionId,
    DateTime? timestamp,
    double? batSpeed,
    int? powerIndex,
    double? timingScore,
    double? sweetSpotAccuracy,
    String? coachNotes,
  }) {
    return ShotModel(
      shotId: shotId ?? this.shotId,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      batSpeed: batSpeed ?? this.batSpeed,
      powerIndex: powerIndex ?? this.powerIndex,
      timingScore: timingScore ?? this.timingScore,
      sweetSpotAccuracy: sweetSpotAccuracy ?? this.sweetSpotAccuracy,
      coachNotes: coachNotes ?? this.coachNotes,
    );
  }

  /// Get timing score as a readable string
  String get timingScoreText {
    if (timingScore > 0) {
      return '+${timingScore.toStringAsFixed(1)}ms';
    } else if (timingScore < 0) {
      return '${timingScore.toStringAsFixed(1)}ms';
    } else {
      return 'Perfect';
    }
  }

  /// Get sweet spot accuracy as percentage
  String get sweetSpotAccuracyText {
    return '${(sweetSpotAccuracy * 100).toStringAsFixed(1)}%';
  }

  /// Get power level description
  String get powerLevel {
    if (powerIndex >= 90) return 'Excellent';
    if (powerIndex >= 80) return 'Very Good';
    if (powerIndex >= 70) return 'Good';
    if (powerIndex >= 60) return 'Average';
    return 'Below Average';
  }

  @override
  String toString() {
    return 'ShotModel(shotId: $shotId, sessionId: $sessionId, timestamp: $timestamp, batSpeed: $batSpeed, powerIndex: $powerIndex, timingScore: $timingScore, sweetSpotAccuracy: $sweetSpotAccuracy, coachNotes: $coachNotes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShotModel &&
        other.shotId == shotId &&
        other.sessionId == sessionId &&
        other.timestamp == timestamp &&
        other.batSpeed == batSpeed &&
        other.powerIndex == powerIndex &&
        other.timingScore == timingScore &&
        other.sweetSpotAccuracy == sweetSpotAccuracy &&
        other.coachNotes == coachNotes;
  }

  @override
  int get hashCode {
    return shotId.hashCode ^
        sessionId.hashCode ^
        timestamp.hashCode ^
        batSpeed.hashCode ^
        powerIndex.hashCode ^
        timingScore.hashCode ^
        sweetSpotAccuracy.hashCode ^
        coachNotes.hashCode;
  }
}

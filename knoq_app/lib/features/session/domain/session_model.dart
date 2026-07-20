class SessionModel {
  final String id;
  final String playerId;
  final String? academyId;
  final String deviceId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int totalHits;
  final int sweetSpotHits;
  final int sweetSpotPct;
  final int avgPower;
  final int peakPower;
  final double? avgSwing;
  final double? peakSwing;
  final Map<String, dynamic> zoneDistribution;
  final double? consistencyScore;
  final String? coachNote;
  final String? appVersion;
  final String? firmwareVersion;
  final String syncStatus;
  final Map<String, dynamic>? insights;
  final String? videoUrl;

  SessionModel({
    required this.id,
    required this.playerId,
    this.academyId,
    required this.deviceId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalHits,
    required this.sweetSpotHits,
    required this.sweetSpotPct,
    required this.avgPower,
    required this.peakPower,
    this.avgSwing,
    this.peakSwing,
    required this.zoneDistribution,
    this.consistencyScore,
    this.coachNote,
    this.appVersion,
    this.firmwareVersion,
    required this.syncStatus,
    this.insights,
    this.videoUrl,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      academyId: json['academy_id'] as String?,
      deviceId: json['device_id'] as String,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] as String,
      totalHits: json['total_hits'] as int? ?? 0,
      sweetSpotHits: json['sweet_spot_hits'] as int? ?? 0,
      sweetSpotPct: json['sweet_spot_pct'] as int? ?? 0,
      avgPower: json['avg_power'] as int? ?? 0,
      peakPower: json['peak_power'] as int? ?? 0,
      // Handle db parsings
      avgSwing: json['avg_swing'] != null ? (json['avg_swing'] is num ? (json['avg_swing'] as num).toDouble() : double.tryParse(json['avg_swing'].toString())) : null,
      peakSwing: json['peak_swing'] != null ? (json['peak_swing'] is num ? (json['peak_swing'] as num).toDouble() : double.tryParse(json['peak_swing'].toString())) : null,
      zoneDistribution: json['zone_distribution'] as Map<String, dynamic>? ?? {},
      consistencyScore: json['consistency_score'] != null ? (json['consistency_score'] is num ? (json['consistency_score'] as num).toDouble() : double.tryParse(json['consistency_score'].toString())) : null,
      coachNote: json['coach_note'] as String?,
      appVersion: json['app_version'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      insights: json['insights'] as Map<String, dynamic>?,
      videoUrl: json['video_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'academy_id': academyId,
      'device_id': deviceId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'total_hits': totalHits,
      'sweet_spot_hits': sweetSpotHits,
      'sweet_spot_pct': sweetSpotPct,
      'avg_power': avgPower,
      'peak_power': peakPower,
      'avg_swing': avgSwing,
      'peak_swing': peakSwing,
      'zone_distribution': zoneDistribution,
      'consistency_score': consistencyScore,
      'coach_note': coachNote,
      'app_version': appVersion,
      'firmware_version': firmwareVersion,
      'sync_status': syncStatus,
      'insights': insights,
      'video_url': videoUrl,
    };
  }

  SessionModel copyWith({
    String? id,
    String? playerId,
    String? academyId,
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    int? totalHits,
    int? sweetSpotHits,
    int? sweetSpotPct,
    int? avgPower,
    int? peakPower,
    double? avgSwing,
    double? peakSwing,
    Map<String, dynamic>? zoneDistribution,
    double? consistencyScore,
    String? coachNote,
    String? appVersion,
    String? firmwareVersion,
    String? syncStatus,
    Map<String, dynamic>? insights,
    String? videoUrl,
  }) {
    return SessionModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      academyId: academyId ?? this.academyId,
      deviceId: deviceId ?? this.deviceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalHits: totalHits ?? this.totalHits,
      sweetSpotHits: sweetSpotHits ?? this.sweetSpotHits,
      sweetSpotPct: sweetSpotPct ?? this.sweetSpotPct,
      avgPower: avgPower ?? this.avgPower,
      peakPower: peakPower ?? this.peakPower,
      avgSwing: avgSwing ?? this.avgSwing,
      peakSwing: peakSwing ?? this.peakSwing,
      zoneDistribution: zoneDistribution ?? this.zoneDistribution,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      coachNote: coachNote ?? this.coachNote,
      appVersion: appVersion ?? this.appVersion,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      insights: insights ?? this.insights,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

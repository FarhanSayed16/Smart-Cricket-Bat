class ShotData {
  final int hit; // sequence number
  final String zone; // Top, Sweet, Left, Right, Bottom
  final int power; // 0-100
  final double? swing; // Nullable as per MPU-9250 constraints
  final int sweetPct;
  final int avgPower;
  final int totalHits;
  final int? videoOffsetMs;
  final DateTime? timestamp;

  ShotData({
    required this.hit,
    required this.zone,
    required this.power,
    this.swing,
    required this.sweetPct,
    required this.avgPower,
    required this.totalHits,
    this.videoOffsetMs,
    this.timestamp,
  });

  factory ShotData.fromJson(Map<String, dynamic> json) {
    // Graceful handling of swing metric per Masterplan Rule 3.3
    double? parsedSwing;
    if (json.containsKey('swing')) {
      final val = json['swing'];
      if (val != null) {
        final doubleVal = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (doubleVal != null && doubleVal > 0) {
          parsedSwing = doubleVal;
        }
      }
    }

    return ShotData(
      hit: json['hit'] as int? ?? 1,
      zone: json['zone'] as String? ?? 'Sweet',
      power: json['power'] as int? ?? 0,
      swing: parsedSwing,
      sweetPct: json['sweetPct'] as int? ?? 0,
      avgPower: json['avgPower'] as int? ?? 0,
      totalHits: json['totalHits'] as int? ?? 1,
      videoOffsetMs: json['videoOffsetMs'] as int?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hit': hit,
      'zone': zone,
      'power': power,
      'swing': swing,
      'sweetPct': sweetPct,
      'avgPower': avgPower,
      'totalHits': totalHits,
      'videoOffsetMs': videoOffsetMs,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class SessionSummary {
  final int totalShots;
  final int avgPower;
  final Map<String, double> zoneDistribution;

  SessionSummary({
    required this.totalShots,
    required this.avgPower,
    required this.zoneDistribution,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    Map<String, double> zones = {};
    if (json['zones'] != null) {
      (json['zones'] as Map<String, dynamic>).forEach((k, v) {
        zones[k] = (v is num) ? v.toDouble() : double.parse(v.toString());
      });
    }
    
    return SessionSummary(
      totalShots: json['total'] as int? ?? 0,
      avgPower: json['avgPower'] as int? ?? 0,
      zoneDistribution: zones,
    );
  }
}

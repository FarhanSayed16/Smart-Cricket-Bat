class AnalyticsModel {
  final int totalSessions;
  final int totalHits;
  final int overallSweetPct;
  final int overallAvgPower;
  final int overallPeakPower;
  final double? overallAvgSwing;
  
  final Map<String, int> zoneTotals;
  final Map<String, double> powerTrend;
  final Map<String, double?> swingTrend;
  final Map<String, double> sweetTrend;
  final Map<String, double> consistencyTrend;
  
  final String? strongestZone;
  final String? weakestZone;

  AnalyticsModel({
    required this.totalSessions,
    required this.totalHits,
    required this.overallSweetPct,
    required this.overallAvgPower,
    required this.overallPeakPower,
    this.overallAvgSwing,
    required this.zoneTotals,
    required this.powerTrend,
    required this.swingTrend,
    required this.sweetTrend,
    required this.consistencyTrend,
    this.strongestZone,
    this.weakestZone,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseZoneTotals(dynamic data) {
      if (data == null) return {};
      final map = data as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    Map<String, double> parseTrend(dynamic data) {
      if (data == null) return {};
      final map = data as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    Map<String, double?> parseNullableTrend(dynamic data) {
      if (data == null) return {};
      final map = data as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v != null ? (v as num).toDouble() : null));
    }

    return AnalyticsModel(
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalHits: json['total_hits'] as int? ?? 0,
      overallSweetPct: json['overall_sweet_pct'] as int? ?? 0,
      overallAvgPower: json['overall_avg_power'] as int? ?? 0,
      overallPeakPower: json['overall_peak_power'] as int? ?? 0,
      overallAvgSwing: json['overall_avg_swing'] != null ? (json['overall_avg_swing'] as num).toDouble() : null,
      zoneTotals: parseZoneTotals(json['zone_totals']),
      powerTrend: parseTrend(json['power_trend']),
      swingTrend: parseNullableTrend(json['swing_trend']),
      sweetTrend: parseTrend(json['sweet_trend']),
      consistencyTrend: parseTrend(json['consistency_trend']),
      strongestZone: json['strongest_zone'] as String?,
      weakestZone: json['weakest_zone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_hits': totalHits,
      'overall_sweet_pct': overallSweetPct,
      'overall_avg_power': overallAvgPower,
      'overall_peak_power': overallPeakPower,
      'overall_avg_swing': overallAvgSwing,
      'zone_totals': zoneTotals,
      'power_trend': powerTrend,
      'swing_trend': swingTrend,
      'sweet_trend': sweetTrend,
      'consistency_trend': consistencyTrend,
      'strongest_zone': strongestZone,
      'weakest_zone': weakestZone,
    };
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/features/analytics/domain/analytics_model.dart';

void main() {
  group('AnalyticsModel', () {
    test('fromJson parses correctly with all data', () {
      final json = {
        'total_sessions': 10,
        'total_hits': 500,
        'overall_sweet_pct': 75,
        'overall_avg_power': 85,
        'overall_peak_power': 99,
        'overall_avg_swing': 120.5,
        'zone_totals': {'Sweet': 375, 'Top': 50, 'Left': 25, 'Right': 25, 'Bottom': 25},
        'power_trend': {'session_1': 80.0, 'session_2': 85.0},
        'swing_trend': {'session_1': 110.0, 'session_2': 120.0},
        'sweet_trend': {'session_1': 70.0, 'session_2': 75.0},
        'consistency_trend': {'session_1': 80.0, 'session_2': 85.0},
        'strongest_zone': 'Sweet',
        'weakest_zone': 'Bottom',
      };

      final model = AnalyticsModel.fromJson(json);

      expect(model.totalSessions, 10);
      expect(model.totalHits, 500);
      expect(model.overallSweetPct, 75);
      expect(model.overallAvgPower, 85);
      expect(model.overallPeakPower, 99);
      expect(model.overallAvgSwing, 120.5);
      expect(model.zoneTotals['Sweet'], 375);
      expect(model.powerTrend['session_1'], 80.0);
      expect(model.swingTrend['session_1'], 110.0);
      expect(model.strongestZone, 'Sweet');
      expect(model.weakestZone, 'Bottom');
    });

    test('fromJson handles nulls and missing fields gracefully', () {
      final json = <String, dynamic>{};

      final model = AnalyticsModel.fromJson(json);

      expect(model.totalSessions, 0);
      expect(model.totalHits, 0);
      expect(model.overallSweetPct, 0);
      expect(model.overallAvgPower, 0);
      expect(model.overallPeakPower, 0);
      expect(model.overallAvgSwing, isNull);
      expect(model.zoneTotals, isEmpty);
      expect(model.powerTrend, isEmpty);
      expect(model.swingTrend, isEmpty);
      expect(model.sweetTrend, isEmpty);
      expect(model.consistencyTrend, isEmpty);
      expect(model.strongestZone, isNull);
      expect(model.weakestZone, isNull);
    });

    test('fromJson parses nullable swing trend correctly', () {
      final json = {
        'swing_trend': {'session_1': 110.0, 'session_2': null, 'session_3': 120.5},
      };

      final model = AnalyticsModel.fromJson(json);

      expect(model.swingTrend.length, 3);
      expect(model.swingTrend['session_1'], 110.0);
      expect(model.swingTrend['session_2'], isNull);
      expect(model.swingTrend['session_3'], 120.5);
    });
  });
}

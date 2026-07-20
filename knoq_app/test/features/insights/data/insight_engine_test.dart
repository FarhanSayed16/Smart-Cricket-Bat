import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/features/session/domain/session_stats.dart';
import 'package:knoq_app/features/insights/data/insight_engine.dart';

void main() {
  late InsightEngine engine;
  late SessionStats stats;

  setUp(() {
    engine = InsightEngine();
    stats = SessionStats();
  });

  ShotData makeShot({required int index, String zone = 'Sweet', int power = 50, double? swing}) {
    return ShotData(
      hit: index,
      power: power,
      zone: zone,
      sweetPct: 0,
      avgPower: 0,
      totalHits: index,
      swing: swing,
    );
  }

  void addShots(int count, {String zone = 'Sweet', int power = 50, double? swing}) {
    for (int i = 0; i < count; i++) {
      stats.addShot(makeShot(index: stats.totalHits + 1, zone: zone, power: power, swing: swing));
    }
  }

  group('InsightEngine Rules -', () {
    test('empty session -> empty list', () {
      expect(engine.generateInsights(stats, []).isEmpty, true);
    });

    test('< 5 shots -> empty list', () {
      addShots(4);
      final shots = List<ShotData>.generate(4, (i) => makeShot(index: i + 1));
      expect(engine.generateInsights(stats, shots).isEmpty, true);
    });

    test('all sweet (>70%) -> positive insight', () {
      addShots(10, zone: 'Sweet', power: 50);
      final shots = List<ShotData>.generate(10, (i) => makeShot(index: i + 1, zone: 'Sweet', power: 50));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.length, 1);
      expect(insights.first.type, 'Sweet Spot');
      expect(insights.first.title, 'Excellent Accuracy');
    });

    test('heavy left bias -> left zone insight', () {
      addShots(5, zone: 'Left', power: 50); // 50% left
      addShots(5, zone: 'Sweet', power: 50);
      final shots = List<ShotData>.generate(10, (i) => makeShot(
        index: i + 1, power: 50, zone: i < 5 ? 'Left' : 'Sweet'));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.any((e) => e.title == 'Heavy Left Bias'), true);
    });

    test('fatigue detected -> fatigue insight is #1 priority', () {
      // Need > 50 shots
      // First quarter avg power = 80
      addShots(14, zone: 'Sweet', power: 80);
      // middle
      addShots(28, zone: 'Sweet', power: 60);
      // last quarter avg power = 50 (< 80 * 0.8 = 64)
      addShots(14, zone: 'Sweet', power: 50);

      final shots = List<ShotData>.generate(56, (i) => makeShot(
        index: i + 1, power: i < 14 ? 80 : (i < 42 ? 60 : 50), zone: 'Sweet'));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.isNotEmpty, true);
      expect(insights.first.type, 'Fatigue');
      expect(insights.first.title, 'Power Drooped Over Time');
    });

    test('exactly 40% left -> no trigger (must be >40%)', () {
      addShots(4, zone: 'Left', power: 50); // 40%
      addShots(6, zone: 'Sweet', power: 50);
      final shots = List<ShotData>.generate(10, (i) => makeShot(
        index: i + 1, power: 50, zone: i < 4 ? 'Left' : 'Sweet'));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.any((e) => e.title == 'Heavy Left Bias'), false);
    });

    test('all shots have swing=null -> NO swing insights generated', () {
      addShots(10, zone: 'Sweet', power: 50, swing: null);
      final shots = List<ShotData>.generate(10, (i) => makeShot(index: i + 1, power: 50, zone: 'Sweet'));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.any((e) => e.type == 'Swing'), false);
    });

    test('60% shots have swing data + high stdDev -> swing inconsistency', () {
      addShots(3, zone: 'Sweet', power: 50, swing: 10);
      addShots(3, zone: 'Sweet', power: 50, swing: 150); // High stddev
      addShots(4, zone: 'Sweet', power: 50, swing: null);

      final shots = List<ShotData>.generate(10, (i) => makeShot(
        index: i + 1, power: 50, zone: 'Sweet',
        swing: i < 3 ? 10.0 : (i < 6 ? 150.0 : null)));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.any((e) => e.type == 'Swing' && e.title == 'Inconsistent Swing Tempo'), true);
    });

    test('30% shots have swing data -> hasValidSwingData=false -> no swing insights', () {
      addShots(3, zone: 'Sweet', power: 50, swing: 100);
      addShots(7, zone: 'Sweet', power: 50, swing: null);

      final shots = List<ShotData>.generate(10, (i) => makeShot(
        index: i + 1, power: 50, zone: 'Sweet',
        swing: i < 3 ? 100.0 : null));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.any((e) => e.type == 'Swing'), false);
    });

    test('3+ issues -> only top 3 returned', () {
      // Left bias + Right bias + Low sweet + Power inconsistency
      addShots(5, zone: 'Left', power: 30);
      addShots(5, zone: 'Right', power: 80);

      final shots = List<ShotData>.generate(10, (i) => makeShot(
        index: i + 1, power: i < 5 ? 30 : 80,
        zone: i < 5 ? 'Left' : 'Right'));

      final insights = engine.generateInsights(stats, shots);
      expect(insights.length, lessThanOrEqualTo(3));
    });
  });

  group('Cross-Session Trend Insights -', () {
    test('sweet% improving over 3 sessions -> positive insight', () {
      final insights = engine.generateCrossSessionInsights(
        recentSweetPcts: [30.0, 45.0, 60.0],
        recentAvgPowers: [50.0, 50.0, 50.0],
        recentConsistencies: [50.0, 50.0, 50.0],
      );
      expect(insights.any((e) => e.title == 'Great Progress!'), true);
    });

    test('avg power declining over 3 sessions -> improvement insight', () {
      final insights = engine.generateCrossSessionInsights(
        recentSweetPcts: [50.0, 50.0, 50.0],
        recentAvgPowers: [80.0, 70.0, 55.0],
        recentConsistencies: [50.0, 50.0, 50.0],
      );
      expect(insights.any((e) => e.title == 'Power Trending Down'), true);
    });

    test('consistency improving over 3 sessions -> positive insight', () {
      final insights = engine.generateCrossSessionInsights(
        recentSweetPcts: [50.0, 50.0, 50.0],
        recentAvgPowers: [50.0, 50.0, 50.0],
        recentConsistencies: [40.0, 55.0, 72.0],
      );
      expect(insights.any((e) => e.title == 'Becoming More Consistent'), true);
    });

    test('< 3 sessions -> empty list', () {
      final insights = engine.generateCrossSessionInsights(
        recentSweetPcts: [50.0, 60.0],
        recentAvgPowers: [50.0, 50.0],
        recentConsistencies: [50.0, 50.0],
      );
      expect(insights.isEmpty, true);
    });

    test('flat trends -> no insights', () {
      final insights = engine.generateCrossSessionInsights(
        recentSweetPcts: [50.0, 50.0, 50.0],
        recentAvgPowers: [60.0, 60.0, 60.0],
        recentConsistencies: [55.0, 55.0, 55.0],
      );
      expect(insights.isEmpty, true);
    });
  });
}

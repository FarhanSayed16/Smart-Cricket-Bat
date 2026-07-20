import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/features/session/domain/session_stats.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';

void main() {
  group('SessionStats', () {
    late SessionStats stats;

    setUp(() {
      stats = SessionStats();
    });

    test('initial state is zeroed out', () {
      expect(stats.totalHits, 0);
      expect(stats.sweetSpotHits, 0);
      expect(stats.sweetSpotPct, 0);
      expect(stats.avgPower, 0);
      expect(stats.peakPower, 0);
      expect(stats.avgSwing, 0);
      expect(stats.peakSwing, 0);
      expect(stats.hasSwingData, false);
      expect(stats.computeConsistency(), 0);
    });

    test('computes averages and percentages correctly with valid swing', () {
      stats.addShot(ShotData(hit: 1, zone: 'Sweet', power: 80, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 2, zone: 'Top', power: 60, swing: 100.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 3, zone: 'Sweet', power: 100, swing: 140.0, sweetPct: 0, avgPower: 0, totalHits: 0));

      expect(stats.totalHits, 3);
      expect(stats.sweetSpotHits, 2);
      expect(stats.sweetSpotPct, 67); // (2/3) * 100
      expect(stats.avgPower, 80); // (80+60+100) / 3
      expect(stats.peakPower, 100);
      expect(stats.avgSwing, 120.0); // (120+100+140) / 3
      expect(stats.peakSwing, 140.0);
      expect(stats.hasSwingData, true);
    });

    test('handles missing swing data gracefully', () {
      stats.addShot(ShotData(hit: 1, zone: 'Sweet', power: 80, swing: null, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 2, zone: 'Top', power: 60, swing: null, sweetPct: 0, avgPower: 0, totalHits: 0));
      
      expect(stats.hasSwingData, false);
      expect(stats.avgSwing, 0);
      expect(stats.peakSwing, 0);
    });

    test('hasSwingData is true only if >= 50% shots have swing', () {
      stats.addShot(ShotData(hit: 1, zone: 'Sweet', power: 80, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 2, zone: 'Top', power: 60, swing: null, sweetPct: 0, avgPower: 0, totalHits: 0));
      expect(stats.hasSwingData, true); // 1 out of 2 = 50%
      
      stats.addShot(ShotData(hit: 3, zone: 'Left', power: 70, swing: null, sweetPct: 0, avgPower: 0, totalHits: 0));
      expect(stats.hasSwingData, false); // 1 out of 3 = 33%
    });

    test('consistencyScore is 100 when all shots same zone and same power', () {
      stats.addShot(ShotData(hit: 1, zone: 'Sweet', power: 80, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 2, zone: 'Sweet', power: 80, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 3, zone: 'Sweet', power: 80, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));

      expect(stats.computeConsistency(), 100);
    });

    test('consistencyScore is < 40 when fully random distribution', () {
      stats.addShot(ShotData(hit: 1, zone: 'Sweet', power: 10, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 2, zone: 'Top', power: 90, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 3, zone: 'Left', power: 20, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 4, zone: 'Right', power: 100, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));
      stats.addShot(ShotData(hit: 5, zone: 'Bottom', power: 50, swing: 120.0, sweetPct: 0, avgPower: 0, totalHits: 0));

      expect(stats.computeConsistency() < 40, true);
    });
  });
}

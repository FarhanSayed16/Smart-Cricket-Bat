import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'dart:math';

class SessionStats {
  int totalHits = 0;
  int sweetSpotHits = 0;
  int get sweetSpotPct => totalHits == 0 ? 0 : ((sweetSpotHits / totalHits) * 100).round();
  
  double _powerSum = 0;
  final List<int> _powers = [];
  int get avgPower => totalHits == 0 ? 0 : (_powerSum / totalHits).round();
  int peakPower = 0;
  
  int _swingCount = 0;
  double _swingSum = 0;
  double get avgSwing => _swingCount == 0 ? 0 : _swingSum / _swingCount;
  double peakSwing = 0;
  
  // Rule: true if >= 50% of shots have valid swing bounds
  bool get hasSwingData => totalHits > 0 && (_swingCount / totalHits) >= 0.5;

  Map<String, int> zoneDistribution = {
    'Sweet': 0, 'Top': 0, 'Left': 0, 'Right': 0, 'Bottom': 0
  };

  void addShot(ShotData shot) {
    totalHits++;
    
    if (shot.zone == 'Sweet') {
      sweetSpotHits++;
    }
    
    // Accumulate distribution
    if (zoneDistribution.containsKey(shot.zone)) {
      zoneDistribution[shot.zone] = zoneDistribution[shot.zone]! + 1;
    } else {
      zoneDistribution[shot.zone] = 1;
    }

    // Power
    int clampedPower = shot.power.clamp(0, 100);
    _powerSum += clampedPower;
    _powers.add(clampedPower);
    if (clampedPower > peakPower) peakPower = clampedPower;

    // Swing
    if (shot.swing != null) {
      _swingCount++;
      _swingSum += shot.swing!;
      if (shot.swing! > peakSwing) peakSwing = shot.swing!;
    }
  }

  double computeConsistency() {
    if (totalHits < 2) return 0;
    
    // 1. Zone Entropy Calculation
    double entropy = 0;
    for (var value in zoneDistribution.values) {
       if (value > 0) {
          double p = value / totalHits;
          entropy -= p * (log(p) / log(2));
       }
    }
    
    // Max entropy for 5 variables is ~2.3219 
    // Normalized to 0-50 (0 entropy = 0 score here meaning perfectly in one zone)
    double zoneEntropyScore = (entropy / 2.3219) * 50;

    // 2. Power Standard Deviation Calculation
    double meanPower = avgPower.toDouble();
    double sumOfSquaredDiffs = 0;
    for (int p in _powers) {
      sumOfSquaredDiffs += pow(p - meanPower, 2);
    }
    double variance = sumOfSquaredDiffs / _powers.length;
    double stdDev = sqrt(variance);

    // Normalize stdDev to 0-50 range (cap stdDev at 25)
    // if stdDev is 25, score is 50. If 0, score is 0.
    double powerStdDevNormalized = min(50, stdDev * 2.0);

    // Formula: consistencyScore = 100 - (zoneEntropyScore + powerStdDevNormalized)
    double score = 100 - (zoneEntropyScore + powerStdDevNormalized);
    return score.clamp(0, 100);
  }
}

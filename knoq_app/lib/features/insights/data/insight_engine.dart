import 'dart:math';
import 'package:flutter/material.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/features/session/domain/session_stats.dart';
import 'package:knoq_app/features/insights/domain/insight_model.dart';

class InsightEngine {
  /// Generates top 3 insights prioritized from fatigue > low sweet > zone > power inconsistency > swing > positive.
  List<InsightModel> generateInsights(SessionStats stats, List<ShotData> shots) {
    if (shots.length < 5) return [];

    final List<InsightModel> results = [];

    // 1. Fatigue (Priority 1)
    if (shots.length > 50) {
      int quarterLength = shots.length ~/ 4;
      var firstQuarter = shots.sublist(0, quarterLength);
      var lastQuarter = shots.sublist(shots.length - quarterLength);

      double firstAvg = firstQuarter.map((s) => s.power).reduce((a, b) => a + b) / quarterLength;
      double lastAvg = lastQuarter.map((s) => s.power).reduce((a, b) => a + b) / quarterLength;

      if (lastAvg < (firstAvg * 0.8)) {
        results.add(const InsightModel(
          type: 'Fatigue',
          title: 'Power Drooped Over Time',
          detail: 'Your baseline power dropped towards the end of the session, signaling potential fatigue.',
          action: 'Focus on endurance and rest. Don\'t compromise form when tired.',
          severity: InsightSeverity.priority,
          icon: Icons.battery_alert,
        ));
      }
    }

    // 2. Sweet Spot (Priority 2)
    double sweetPctStr = stats.sweetSpotPct.toDouble();
    if (sweetPctStr < 30) {
      results.add(const InsightModel(
        type: 'Sweet Spot',
        title: 'Low Sweet Spot Ratio',
        detail: 'Less than 30% of your hits were on the sweet spot.',
        action: 'Slow down your swing. Focus heavily on eye-to-ball coordination.',
        severity: InsightSeverity.priority,
        icon: Icons.error_outline,
      ));
    } else if (sweetPctStr >= 30 && sweetPctStr < 50) {
      results.add(const InsightModel(
        type: 'Sweet Spot',
        title: 'Inconsistent Strike Zone',
        detail: 'You are missing the sweet spot on over half your shots.',
        action: 'Check your stance distance from the stumps and head position.',
        severity: InsightSeverity.improvement,
        icon: Icons.warning_amber,
      ));
    }

    // 3. Zone Biases (Priority 3)
    int leftHits = stats.zoneDistribution['Left'] ?? 0;
    int rightHits = stats.zoneDistribution['Right'] ?? 0;
    int bottomHits = stats.zoneDistribution['Bottom'] ?? 0;
    int topHits = stats.zoneDistribution['Top'] ?? 0;
    int total = stats.totalHits;

    if ((leftHits / total) > 0.40) {
      results.add(const InsightModel(
        type: 'Zone Bias',
        title: 'Heavy Left Bias',
        detail: 'Over 40% of shots hit the left edge of the bat.',
        action: 'You may be stepping too far across or dragging bat face.',
        severity: InsightSeverity.improvement,
        icon: Icons.keyboard_double_arrow_left,
      ));
    }
    if ((rightHits / total) > 0.40) {
      results.add(const InsightModel(
        type: 'Zone Bias',
        title: 'Heavy Right Bias',
        detail: 'Over 40% of shots hit the right edge of the bat.',
        action: 'Check if you are backing away on impact or reaching out too far.',
        severity: InsightSeverity.improvement,
        icon: Icons.keyboard_double_arrow_right,
      ));
    }
    if ((bottomHits / total) > 0.25) {
      results.add(const InsightModel(
        type: 'Zone Bias',
        title: 'Bottom Edge Hits',
        detail: 'A high frequency of bottom edge contacts detected.',
        action: 'Work on your timing. You might be playing the ball too early or late ( Yorker ).',
        severity: InsightSeverity.improvement,
        icon: Icons.arrow_downward,
      ));
    }
    if ((topHits / total) > 0.30) {
      results.add(const InsightModel(
        type: 'Zone Bias',
        title: 'Top Edge Hits',
        detail: 'You are catching the ball high on the bat face frequently.',
        action: 'Focus on getting your head over the ball on the front foot.',
        severity: InsightSeverity.improvement,
        icon: Icons.arrow_upward,
      ));
    }

    // 4. Power Inconsistency & Levels (Priority 4)
    double meanPower = stats.avgPower.toDouble();
    double powerVar = shots.map((s) => pow(s.power - meanPower, 2)).reduce((a, b) => a + b) / shots.length;
    double powerStdDev = sqrt(powerVar);

    if (powerStdDev > 25) {
      results.add(const InsightModel(
        type: 'Power',
        title: 'Inconsistent Power',
        detail: 'Your shot power varies wildly between swings.',
        action: 'Try to find a comfortable baseline rhythm instead of swinging at random intensities.',
        severity: InsightSeverity.improvement,
        icon: Icons.compare_arrows,
      ));
    } else if (stats.avgPower > 80 && sweetPctStr < 50) {
      results.add(const InsightModel(
        type: 'Power',
        title: 'Power Overload',
        detail: 'You are generating strong power but accuracy is low.',
        action: 'Redirect focus to timing and accuracy instead of raw force.',
        severity: InsightSeverity.improvement,
        icon: Icons.fitness_center,
      ));
    } else if (stats.avgPower < 40) {
      results.add(const InsightModel(
        type: 'Power',
        title: 'Low Average Power',
        detail: 'Overall power generated is below 40%.',
        action: 'Check your backlift and ensure a full follow-through.',
        severity: InsightSeverity.info,
        icon: Icons.arrow_downward,
      ));
    }

    // 5. Swing Data (Priority 5)
    if (stats.hasSwingData) {
      final validSwings = shots.where((s) => s.swing != null && s.swing! > 0).map((s) => s.swing!).toList();
      if (validSwings.isNotEmpty) {
        double meanSwing = validSwings.reduce((a, b) => a + b) / validSwings.length;
        double swingVar = validSwings.map((s) => pow(s - meanSwing, 2)).reduce((a, b) => a + b) / validSwings.length;
        double swingStdDev = sqrt(swingVar);

        if (swingStdDev > 40) {
          results.add(const InsightModel(
            type: 'Swing',
            title: 'Inconsistent Swing Tempo',
            detail: 'The speed of your bat swing is fluctuating significantly.',
            action: 'Focus on a smooth, repetitive swing arc rather than snatching at the ball.',
            severity: InsightSeverity.improvement,
            icon: Icons.sync_problem,
          ));
        }

        if (meanSwing > 80 && sweetPctStr < 40) {
          results.add(const InsightModel(
            type: 'Swing',
            title: 'Speed Over Accuracy',
            detail: 'High swing speeds combined with low sweet spot accuracy.',
            action: 'Slow everything down by 20%. Control > Power.',
            severity: InsightSeverity.priority,
            icon: Icons.speed,
          ));
        }
      }
    }

    // 6. Positives (Priority 6)
    if (sweetPctStr >= 70) {
      results.add(const InsightModel(
        type: 'Sweet Spot',
        title: 'Excellent Accuracy',
        detail: 'You hit the sweet spot over 70% of the time!',
        action: 'Keep doing what you are doing. Focus on increasing power without losing this form.',
        severity: InsightSeverity.positive,
        icon: Icons.check_circle_outline,
      ));
    } else if (sweetPctStr >= 50 && sweetPctStr < 70) {
      results.add(const InsightModel(
        type: 'Sweet Spot',
        title: 'Solid Timing',
        detail: 'Very consistent contact throughout the session.',
        action: 'Try testing this form against faster deliveries.',
        severity: InsightSeverity.positive,
        icon: Icons.thumb_up_alt_outlined,
      ));
    }
    
    if (stats.avgPower > 80 && sweetPctStr >= 50) {
      results.add(const InsightModel(
        type: 'Power',
        title: 'Incredible Power',
        detail: 'You consistently generated high power outputs while keeping good form.',
        action: 'Ready for match-situations.',
        severity: InsightSeverity.positive,
        icon: Icons.flash_on,
      ));
    }

    // Return top 3 insights, preserving priority order (already appended by priority)
    return results.take(3).toList();
  }

  /// Cross-session trend analysis. Requires >= 3 sessions of historical aggregate data.
  /// [recentSweetPcts] / [recentAvgPowers] / [recentConsistencies] are ordered oldest → newest.
  List<InsightModel> generateCrossSessionInsights({
    required List<double> recentSweetPcts,
    required List<double> recentAvgPowers,
    required List<double> recentConsistencies,
  }) {
    if (recentSweetPcts.length < 3) return [];

    final List<InsightModel> results = [];
    final last3Sweet = recentSweetPcts.sublist(recentSweetPcts.length - 3);
    final last3Power = recentAvgPowers.sublist(recentAvgPowers.length - 3);
    final last3Consistency = recentConsistencies.sublist(recentConsistencies.length - 3);

    // Sweet% improving: each session >= previous
    if (last3Sweet[2] > last3Sweet[1] && last3Sweet[1] > last3Sweet[0]) {
      results.add(const InsightModel(
        type: 'Trend',
        title: 'Great Progress!',
        detail: 'Your sweet spot accuracy has improved over your last 3 sessions.',
        action: 'Keep this form. Try challenging yourself with faster deliveries.',
        severity: InsightSeverity.positive,
        icon: Icons.trending_up,
      ));
    }

    // Avg power declining over last 3
    if (last3Power[2] < last3Power[1] && last3Power[1] < last3Power[0]) {
      results.add(const InsightModel(
        type: 'Trend',
        title: 'Power Trending Down',
        detail: 'Your average power has declined over your last 3 sessions.',
        action: 'Check for fatigue or overtraining. Consider rest days between sessions.',
        severity: InsightSeverity.improvement,
        icon: Icons.trending_down,
      ));
    }

    // Consistency improving over last 3
    if (last3Consistency[2] > last3Consistency[1] && last3Consistency[1] > last3Consistency[0]) {
      results.add(const InsightModel(
        type: 'Trend',
        title: 'Becoming More Consistent',
        detail: 'Your consistency score has steadily improved over the last 3 sessions.',
        action: 'Excellent discipline. Maintain your routine.',
        severity: InsightSeverity.positive,
        icon: Icons.auto_graph,
      ));
    }

    return results.take(3).toList();
  }
}

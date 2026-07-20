import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/core/constants/api_endpoints.dart';
import 'package:knoq_app/features/analytics/domain/analytics_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:intl/intl.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

final analyticsRepositoryProvider = Provider((ref) {
  return AnalyticsRepository(apiClient: ref.watch(apiClientProvider));
});

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Future<AnalyticsModel> getAnalytics({String range = '7d'}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.analytics,
        queryParameters: {'range': range},
      );
      return AnalyticsModel.fromJson(response.data['data']);
    } catch (e) {
      // Fallback: Compute locally from Hive
      return _computeLocalAnalytics(range);
    }
  }

  Future<AnalyticsModel> getPlayerAnalytics(String playerId, {String range = '7d'}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.playerAnalytics(playerId),
        queryParameters: {'range': range},
      );
      return AnalyticsModel.fromJson(response.data['data']);
    } catch (e) {
      // Offline Coach mode fallback not supported strictly without backend yet,
      // but we return local data to prevent crashing.
      return _computeLocalAnalytics(range);
    }
  }

  Future<Map<String, dynamic>> getAdvancedAnalytics(String playerId, {String range = '7d'}) async {
    try {
      final response = await apiClient.dio.get(
        '/analytics/player/$playerId/advanced',
        queryParameters: {'range': range},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Aggregates local offline sessions (from cache + pending queue) into an AnalyticsModel
  AnalyticsModel _computeLocalAnalytics(String range) {
    final cacheBox = Hive.box('sessions_cache');
    final pendingBox = Hive.box('pending_sync');

    List<SessionModel> allLocalSessions = [];

    // 1. Gather cached
    for (var key in cacheBox.keys) {
      if (key == '_cache_timestamp') continue;
      final raw = cacheBox.get(key);
      if (raw == null) continue;
      try {
        allLocalSessions.add(SessionModel.fromJson(json.decode(raw as String)));
      } catch (e) {
        // Skip malformed cache entries
      }
    }
    // 2. Gather pending
    for (var raw in pendingBox.values) {
      if (raw == null) continue;
      try {
        final data = json.decode(raw as String) as Map<String, dynamic>;
        if (data.containsKey('session')) {
          allLocalSessions.add(SessionModel.fromJson(data['session']));
        }
      } catch (e) {
        // Skip malformed pending entries
      }
    }

    // Filter by range
    final now = DateTime.now();
    DateTime threshold;
    if (range == '7d') {
      threshold = now.subtract(const Duration(days: 7));
    } else if (range == '30d') {
      threshold = now.subtract(const Duration(days: 30));
    } else if (range == 'session') {
      // Just the very latest session
      allLocalSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      if (allLocalSessions.isNotEmpty) {
        allLocalSessions = [allLocalSessions.first];
      }
      threshold = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      // all
      threshold = DateTime.fromMillisecondsSinceEpoch(0);
    }

    var validSessions = allLocalSessions.where((s) => s.startTime.isAfter(threshold)).toList();
    
    // Sort ascending for trend lines
    validSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    int totalHits = 0;
    int sweetHits = 0;
    int peakPower = 0;
    double powerSum = 0;
    double swingSum = 0;
    int swingCount = 0;
    Map<String, int> zoneTotals = {'Sweet': 0, 'Top': 0, 'Bottom': 0, 'Left': 0, 'Right': 0};

    Map<String, double> powerTrend = {};
    Map<String, double?> swingTrend = {};
    Map<String, double> sweetTrend = {};
    Map<String, double> consistencyTrend = {};

    final formatter = DateFormat('MMM d');

    for (var s in validSessions) {
       totalHits += s.totalHits;
       sweetHits += s.sweetSpotHits;
       if (s.peakPower > peakPower) peakPower = s.peakPower;
       powerSum += (s.avgPower * s.totalHits); // Weighted average
       
       if (s.avgSwing != null) {
          swingSum += (s.avgSwing! * s.totalHits);
          swingCount += s.totalHits;
       }

       s.zoneDistribution.forEach((key, value) {
          zoneTotals[key] = (zoneTotals[key] ?? 0) + (value as num).toInt();
       });

       String dateKey = formatter.format(s.startTime);
       // basic deduplication if multiple sessions on same day for simplicity offline:
       if (powerTrend.containsKey(dateKey)) {
          dateKey = '${dateKey} (2)';
       }

       powerTrend[dateKey] = s.avgPower.toDouble();
       swingTrend[dateKey] = s.avgSwing;
       sweetTrend[dateKey] = s.sweetSpotPct.toDouble();
       if (s.consistencyScore != null) {
         consistencyTrend[dateKey] = s.consistencyScore!;
       }
    }

    int overallSweetPct = totalHits > 0 ? ((sweetHits / totalHits) * 100).round() : 0;
    int overallAvgPower = totalHits > 0 ? (powerSum / totalHits).round() : 0;
    double? overallAvgSwing = swingCount > 0 ? (swingSum / swingCount) : null;

    String? strongest;
    String? weakest;
    
    if (totalHits > 0) {
       var sortedZones = zoneTotals.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
       if (sortedZones.isNotEmpty) {
          strongest = sortedZones.first.key;
          weakest = sortedZones.last.key;
       }
    }

    return AnalyticsModel(
      totalSessions: validSessions.length,
      totalHits: totalHits,
      overallSweetPct: overallSweetPct,
      overallAvgPower: overallAvgPower,
      overallPeakPower: peakPower,
      overallAvgSwing: overallAvgSwing,
      zoneTotals: zoneTotals,
      powerTrend: powerTrend,
      swingTrend: swingTrend,
      sweetTrend: sweetTrend,
      consistencyTrend: consistencyTrend,
      strongestZone: strongest,
      weakestZone: weakest,
    );
  }
}

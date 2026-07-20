import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:knoq_app/features/analytics/data/analytics_repository.dart';
import 'package:knoq_app/core/widgets/stat_card.dart';
import 'package:knoq_app/core/widgets/empty_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:knoq_app/features/analytics/domain/analytics_model.dart';
import 'package:knoq_app/services/analytics_service.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

final analyticsRangeProvider = StateProvider<String>((ref) => '7d');

final analyticsDataProvider = FutureProvider.autoDispose<AnalyticsModel>((ref) async {
  final range = ref.watch(analyticsRangeProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalytics(range: range);
});

final advancedAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final range = ref.watch(analyticsRangeProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return {};
  return repo.getAdvancedAnalytics(user.id, range: range);
});

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = ref.watch(analyticsRangeProvider);
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final advancedAsync = ref.watch(advancedAnalyticsProvider);

    // Fire analytics event when screen is viewed
    ref.read(analyticsServiceProvider).logAnalyticsViewed();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'session', label: Text('Latest')),
                ButtonSegment(value: '7d', label: Text('7d')),
                ButtonSegment(value: '30d', label: Text('30d')),
                ButtonSegment(value: 'all', label: Text('All Time')),
              ],
              selected: {range},
              onSelectionChanged: (Set<String> newSelection) {
                ref.read(analyticsRangeProvider.notifier).state = newSelection.first;
              },
            ),
          ),
        ),
      ),
      body: analyticsAsync.when(
        data: (data) {
          if (data.totalSessions == 0) {
            return const Center(
              child: EmptyState(
                title: 'No Data Yet',
                subtitle: 'Complete a session to start tracking your progress.',
                illustration: Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(analyticsDataProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryGrid(data, theme),
                const SizedBox(height: 16),
                _buildImprovementBadges(advancedAsync, theme),
                const SizedBox(height: 16),
                _buildPersonalBests(advancedAsync, theme),
                const SizedBox(height: 16),
                _buildOptimalSessionLength(advancedAsync, theme),
                const SizedBox(height: 24),
                _buildZoneDonut(data, theme),
                const SizedBox(height: 24),
                _buildConsistencyGauge(data, theme),
                const SizedBox(height: 24),
                _buildFatigueCurve(advancedAsync, theme),
                const SizedBox(height: 24),
                _buildTrendChart('Power Trend (%)', data.powerTrend, theme, Icons.bolt),
                const SizedBox(height: 24),
                _buildTrendChart('Sweet Spot Trend (%)', data.sweetTrend, theme, Icons.flare),
                if (data.swingTrend.values.any((v) => v != null)) ...[
                  const SizedBox(height: 24),
                  _buildTrendChart('Swing Speed Trend (°/s)', data.swingTrend, theme, Icons.speed, isSwing: true),
                ],
                const SizedBox(height: 24),
                _buildExtremities(data, theme),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => _buildShimmerLoading(theme),
        error: (error, stack) => Center(child: Text('Error computing analytics: $error')),
      ),
    );
  }

  Widget _buildSummaryGrid(AnalyticsModel data, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatCard(icon: Icons.sports_baseball, label: 'Total Hits', value: '${data.totalHits}'),
        StatCard(icon: Icons.analytics_outlined, label: 'Avg Power', value: '${data.overallAvgPower}'),
        StatCard(icon: Icons.flare, label: 'Sweet Spot', value: '${data.overallSweetPct}%'),
        if (data.overallAvgSwing != null)
          StatCard(icon: Icons.sync, label: 'Avg Swing', value: '${data.overallAvgSwing!.toStringAsFixed(1)}°/s')
        else
          StatCard(icon: Icons.bolt, label: 'Peak Power', value: '${data.overallPeakPower}'),
      ],
    );
  }

  Widget _buildConsistencyGauge(AnalyticsModel data, ThemeData theme) {
    if (data.consistencyTrend.isEmpty) return const SizedBox.shrink();
    
    // Get latest consistency
    final latestConsistency = data.consistencyTrend.values.last;
    
    Color gaugeColor;
    if (latestConsistency >= 70) gaugeColor = Colors.green;
    else if (latestConsistency >= 40) gaugeColor = Colors.orange;
    else gaugeColor = Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text('Consistency Score', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: latestConsistency / 100,
                    strokeWidth: 16,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(gaugeColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${latestConsistency.round()}',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneDonut(AnalyticsModel data, ThemeData theme) {
    final Map<String, Color> zoneColors = {
      'Sweet': Colors.green,
      'Top': Colors.blue,
      'Bottom': Colors.orange,
      'Left': Colors.purple,
      'Right': Colors.pink,
    };

    int hitTotal = 0;
    data.zoneTotals.forEach((k, v) => hitTotal += v);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Strike Zone Distribution', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: data.zoneTotals.entries.map((entry) {
                        final val = entry.value;
                        final double pct = hitTotal > 0 ? (val / hitTotal) * 100 : 0;
                        return PieChartSectionData(
                          color: zoneColors[entry.key] ?? Colors.grey,
                          value: val.toDouble(),
                          title: pct >= 5 ? '${pct.round()}%' : '',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$hitTotal', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Hits'),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.zoneTotals.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: zoneColors[entry.key]),
                    const SizedBox(width: 4),
                    Text('${entry.key} (${entry.value})', style: theme.textTheme.bodySmall),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(String title, Map<String, dynamic> trendData, ThemeData theme, IconData icon, {bool isSwing = false}) {
    if (trendData.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    List<String> labels = trendData.keys.toList();
    
    for (int i = 0; i < labels.length; i++) {
      final val = trendData[labels[i]];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    double maxY = 100;
    if (isSwing) {
      double maxVal = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      maxY = ((maxVal / 50).ceil() * 50).toDouble(); // Round to nearest 50
      if (maxY < 100) maxY = 150; 
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Icon(icon, size: 20, color: theme.colorScheme.primary),
                 const SizedBox(width: 8),
                 Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                           if (value.toInt() >= 0 && value.toInt() < labels.length) {
                             // Minimal labeling to avoid crowding
                             if (labels.length > 5 && value.toInt() % (labels.length ~/ 4) != 0 && value.toInt() != labels.length -1) {
                               return const SizedBox.shrink();
                             }
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                             );
                           }
                           return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      )
                    )
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFatigueCurve(AsyncValue<Map<String, dynamic>> advancedAsync, ThemeData theme) {
    return advancedAsync.when(
      data: (adv) {
        final fatigueCurve = adv['fatigueCurve'] as List?;
        if (fatigueCurve == null || fatigueCurve.isEmpty) return const SizedBox.shrink();

        List<FlSpot> spots = [];
        for (var point in fatigueCurve) {
          final shotNum = point['shot_number'] as num;
          final power = point['avg_power'] as num;
          spots.add(FlSpot(shotNum.toDouble(), power.toDouble()));
        }

        if (spots.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                     Icon(Icons.battery_alert, size: 20, color: theme.colorScheme.primary),
                     const SizedBox(width: 8),
                     Text('Fatigue Curve (Power vs Shot #)', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                               if (value.toInt() % 10 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                                  );
                               }
                               return const SizedBox.shrink();
                            }
                          )
                        )
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.redAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.redAccent.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildExtremities(AnalyticsModel data, ThemeData theme) {
    if (data.strongestZone == null || data.weakestZone == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(child: _buildExtremityCard('Strongest Zone', data.strongestZone!, Colors.green, theme)),
        const SizedBox(width: 16),
        Expanded(child: _buildExtremityCard('Weakest Zone', data.weakestZone!, Colors.red, theme)),
      ],
    );
  }

  Widget _buildExtremityCard(String title, String zone, Color color, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(zone, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementBadges(AsyncValue<Map<String, dynamic>> advancedAsync, ThemeData theme) {
    return advancedAsync.when(
      data: (data) {
        final improvement = data['improvement'];
        if (improvement == null) return const SizedBox.shrink();

        final sweetChange = improvement['sweet_spot_change'] ?? 0;
        final powerChange = improvement['power_change'] ?? 0;

        if (sweetChange == 0 && powerChange == 0) return const SizedBox.shrink();

        return Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (sweetChange != 0)
              _buildBadgeChip(
                sweetChange > 0 ? '+$sweetChange% sweet spot this week' : '$sweetChange% sweet spot this week',
                sweetChange > 0 ? Colors.green : Colors.orange,
                sweetChange > 0 ? Icons.trending_up : Icons.trending_down,
                theme,
              ),
            if (powerChange != 0)
              _buildBadgeChip(
                powerChange > 0 ? '+$powerChange avg power this week' : '$powerChange avg power this week',
                powerChange > 0 ? Colors.green : Colors.orange,
                powerChange > 0 ? Icons.trending_up : Icons.trending_down,
                theme,
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadgeChip(String label, Color color, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPersonalBests(AsyncValue<Map<String, dynamic>> advancedAsync, ThemeData theme) {
    return advancedAsync.when(
      data: (data) {
        final pb = data['personalBests'];
        final newPBs = data['newPersonalBests'] as List? ?? [];
        if (pb == null) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 8),
                    Text('Personal Bests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (newPBs.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('NEW PB!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildPBItem('Peak Power', '${pb['max_power'] ?? 0}', newPBs.contains('peak_power'), theme)),
                    Expanded(child: _buildPBItem('Sweet Spot', '${pb['max_sweet'] ?? 0}%', newPBs.contains('sweet_spot'), theme)),
                    Expanded(child: _buildPBItem('Most Hits', '${pb['max_hits'] ?? 0}', newPBs.contains('total_hits'), theme)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPBItem(String label, String value, bool isNewPB, ThemeData theme) {
    return Column(
      children: [
        if (isNewPB)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🏆 NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildOptimalSessionLength(AsyncValue<Map<String, dynamic>> advancedAsync, ThemeData theme) {
    return advancedAsync.when(
      data: (data) {
        final optimalLength = data['optimalSessionLength'];
        if (optimalLength == null) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Optimal Session Length', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Your performance drops after $optimalLength shots. Consider splitting into shorter sessions for best results.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$optimalLength',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           GridView.count(
             crossAxisCount: 2,
             childAspectRatio: 1.5,
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             mainAxisSpacing: 16,
             crossAxisSpacing: 16,
             children: List.generate(4, (i) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
           ),
           const SizedBox(height: 24),
           Card(child: const SizedBox(height: 250), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
           const SizedBox(height: 24),
           Card(child: const SizedBox(height: 250), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ],
      )
    );
  }
}

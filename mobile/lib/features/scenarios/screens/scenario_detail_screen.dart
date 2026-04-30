// Scenario detail screen — projected balance chart + event list.
// Goals also show a target line on the chart and a progress ring.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../models/scenario_event.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/add_scenario_sheet.dart';

class ScenarioDetailScreen extends ConsumerWidget {
  const ScenarioDetailScreen({super.key, required this.scenarioId});
  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(scenarioDetailProvider(scenarioId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $e')),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});
  final ScenarioDetail detail;

  Color get _accentColor =>
      colorFromHex(detail.scenario.color, fallback: BrandColors.accent);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final accent = _accentColor;
    final scenario = detail.scenario;

    return Scaffold(
      appBar: AppBar(
        title: Text(scenario.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => AddScenarioSheet(existing: scenario),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => AddEventSheet(scenarioId: scenarioId),
        ),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          // ── Summary cards ─────────────────────────────────────────────
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryTile(
                label: 'Starting',
                value: fmt.format(detail.startingNetWorth / 100),
                color: cs.outline,
              ),
              const SizedBox(width: 12),
              _SummaryTile(
                label: 'Projected',
                value: fmt.format(detail.finalBalance / 100),
                color: accent,
              ),
              const SizedBox(width: 12),
              _SummaryTile(
                label: detail.netChange >= 0 ? 'Gain' : 'Loss',
                value:
                    '${detail.netChange >= 0 ? '+' : ''}${fmt.format(detail.netChange / 100)}',
                color: detail.netChange >= 0 ? Colors.green : cs.error,
              ),
            ],
          ),

          // ── Goal progress ring ────────────────────────────────────────
          if (scenario.isGoal && scenario.targetAmount != null) ...[
            const SizedBox(height: 16),
            _GoalProgress(detail: detail, accent: accent),
          ],

          // ── Chart ─────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _ProjectionChart(detail: detail, accent: accent),

          // ── Events ────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Text('Events',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (detail.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No events yet — tap + to add one.',
                  style: TextStyle(color: cs.outline),
                ),
              ),
            )
          else
            ...detail.events.map((e) => _EventTile(
                  event: e,
                  scenarioId: scenarioId,
                )),
        ],
      ),
    );
  }

  String get scenarioId => detail.scenario.id;
}

// ---------------------------------------------------------------------------
// Summary tile
// ---------------------------------------------------------------------------

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal progress ring
// ---------------------------------------------------------------------------

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({required this.detail, required this.accent});
  final ScenarioDetail detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final target = detail.scenario.targetAmount!;
    final current = detail.finalBalance;
    final progress = (current / target).clamp(0.0, 1.0);
    final daysLeft = detail.scenario.targetDate
        ?.difference(DateTime.now())
        .inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                        progress >= 1 ? Colors.green : accent),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Goal Progress',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${fmt.format(current / 100)} of ${fmt.format(target / 100)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (daysLeft != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      daysLeft > 0
                          ? '$daysLeft days remaining'
                          : 'Target date passed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: daysLeft > 0 ? cs.outline : cs.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Projection line chart — actual history (grey) + scenario projection (color)
// ---------------------------------------------------------------------------
//
// X-axis is days relative to today: negative = past, 0 = today, positive = future.
// This gives a natural "today" divider between the two lines.

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.detail, required this.accent});
  final ScenarioDetail detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final hist = detail.historicalPoints;
    final proj = detail.projection;
    if (hist.isEmpty && proj.isEmpty) return const SizedBox.shrink();

    // Convert history to (daysFromToday, balance) — always negative X.
    final histSpots = hist.map((p) {
      final days = p.date.difference(todayKey).inDays.toDouble();
      return FlSpot(days, p.balanceCents / 100);
    }).toList();

    // Projection: today = 0, future = positive X.
    final projSpots = proj.map((p) {
      final days = p.date.difference(todayKey).inDays.toDouble();
      return FlSpot(days, p.balanceCents / 100);
    }).toList();

    // Join at today for a seamless line — prepend today's balance to projection.
    final todayBalance = detail.startingNetWorth / 100;
    if (projSpots.isNotEmpty && projSpots.first.x != 0) {
      projSpots.insert(0, FlSpot(0, todayBalance));
    }
    if (histSpots.isNotEmpty && histSpots.last.x != 0) {
      histSpots.add(FlSpot(0, todayBalance));
    }

    // Y-axis range across both lines + target.
    final allY = [
      ...histSpots.map((s) => s.y),
      ...projSpots.map((s) => s.y),
    ];
    if (allY.isEmpty) return const SizedBox.shrink();

    final targetY = detail.scenario.isGoal &&
            detail.scenario.targetAmount != null
        ? detail.scenario.targetAmount! / 100
        : null;

    final minY = ([...allY, ?targetY].reduce((a, b) => a < b ? a : b)) - 500;
    final maxY = ([...allY, ?targetY].reduce((a, b) => a > b ? a : b)) + 500;

    // X range
    final minX = histSpots.isNotEmpty ? histSpots.first.x : 0.0;
    final maxX = projSpots.isNotEmpty ? projSpots.last.x : 0.0;

    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    // Build a lookup for bottom axis labels — sample ~4 dates.
    List<DateTime> sampleDates() {
      final all = [
        ...hist.map((p) => p.date),
        ...proj.map((p) => p.date),
      ]..sort((a, b) => a.compareTo(b));
      if (all.isEmpty) return [];
      final step = (all.length / 4).ceil();
      return [
        for (var i = 0; i < all.length; i += step) all[i],
        all.last,
      ];
    }

    final labelDates = sampleDates();

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
            // Vertical line at x=0 (today divider)
            getDrawingVerticalLine: (v) => FlLine(
              color: v == 0
                  ? cs.outline.withValues(alpha: 0.6)
                  : cs.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: v == 0 ? 1.5 : 0.5,
              dashArray: v == 0 ? [4, 4] : null,
            ),
            verticalInterval: (maxX - minX) / 4,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (v, _) => Text(
                  fmt.format(v),
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  // Find the closest sample date.
                  final date = labelDates.cast<DateTime?>().firstWhere(
                    (d) =>
                        (d!.difference(todayKey).inDays.toDouble() - v).abs() <
                        1,
                    orElse: () => null,
                  );
                  if (date == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${date.month}/${date.year.toString().substring(2)}',
                      style: TextStyle(fontSize: 10, color: cs.outline),
                    ),
                  );
                },
                interval: (maxX - minX) / 4,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          extraLinesData: ExtraLinesData(
            // "Today" vertical marker label
            verticalLines: [
              VerticalLine(
                x: 0,
                color: cs.outline.withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'Today',
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ),
            ],
          ),
          lineBarsData: [
            // ── Actual history — grey solid line ──────────────────────
            if (histSpots.isNotEmpty)
              LineChartBarData(
                spots: histSpots,
                isCurved: true,
                color: cs.outline.withValues(alpha: 0.7),
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: cs.outline.withValues(alpha: 0.05),
                ),
              ),
            // ── Scenario projection — accent color ────────────────────
            if (projSpots.isNotEmpty)
              LineChartBarData(
                spots: projSpots,
                isCurved: true,
                color: accent,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: accent.withValues(alpha: 0.08),
                ),
              ),
            // ── Goal target — dashed green line ───────────────────────
            if (targetY != null)
              LineChartBarData(
                spots: [FlSpot(minX, targetY), FlSpot(maxX, targetY)],
                isCurved: false,
                color: Colors.green,
                barWidth: 1.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) =>
                  touchedSpots.map((s) {
                final label = s.barIndex == 0
                    ? 'Actual'
                    : s.barIndex == 1
                        ? 'Projected'
                        : 'Target';
                return LineTooltipItem(
                  '$label\n${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(s.y)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600,
                      fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event tile
// ---------------------------------------------------------------------------

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, required this.scenarioId});
  final ScenarioEvent event;
  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isPositive = event.eventType.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive
              ? Colors.green.withValues(alpha: 0.15)
              : cs.errorContainer,
          child: Text(
            isPositive ? '↑' : '↓',
            style: TextStyle(
              color: isPositive ? Colors.green : cs.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(event.label,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${event.eventType.label} · '
          '${event.eventDate.year}-'
          '${event.eventDate.month.toString().padLeft(2, '0')}-'
          '${event.eventDate.day.toString().padLeft(2, '0')}'
          '${event.isRecurring ? ' · Recurring' : ''}',
          style: TextStyle(color: cs.outline, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isPositive ? '+' : '-'}${fmt.format(event.amount / 100)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isPositive ? Colors.green : cs.error,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    builder: (_) => AddEventSheet(
                      scenarioId: scenarioId,
                      existing: event,
                    ),
                  );
                } else if (v == 'delete') {
                  await ref
                      .read(scenariosRepositoryProvider)
                      .deleteEvent(event.id);
                  ref.invalidate(
                      scenarioDetailProvider(scenarioId));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

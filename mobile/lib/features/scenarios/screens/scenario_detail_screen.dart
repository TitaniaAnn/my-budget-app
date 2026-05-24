// Scenario detail screen — projected balance chart + event list.
// Goals also show a target line on the chart and a progress ring.
// Debt-payoff scenarios swap the whole body for a multi-debt
// amortisation view (summary + per-debt toggle).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/scenario.dart';
import '../models/scenario_event.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../services/debt_payoff_simulator.dart';
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
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
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

    // Debt-payoff scenarios swap the body entirely — different
    // projection (multi-debt amortisation), no events to add, and
    // the FAB disappears with them.
    if (scenario.kind == ScenarioKind.debtPayoff) {
      return Scaffold(
        appBar: AppBar(
          title: Text(scenario.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showAppSheet<void>(
                context,
                child: AddScenarioSheet(existing: scenario),
              ),
            ),
          ],
        ),
        body: _DebtPayoffBody(scenario: scenario, accent: accent),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(scenario.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showAppSheet<void>(
              context,
              child: AddScenarioSheet(existing: scenario),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAppSheet<void>(
          context,
          child: AddEventSheet(scenarioId: scenarioId),
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
          Text(
            'Events',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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
            ...detail.events.map(
              (e) => _EventTile(event: e, scenarioId: scenarioId),
            ),
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
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });
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
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
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
                      progress >= 1 ? Colors.green : accent,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                  Text(
                    'Goal Progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

/// User-selectable horizon for the projection chart. Stored as
/// transient widget state (not persisted) — most users want a
/// quick "zoom to 6 months" and we don't need it to survive a
/// reload.
enum _ChartRange {
  oneMonth(label: '1M', daysEachSide: 30),
  sixMonths(label: '6M', daysEachSide: 180),
  oneYear(label: '1Y', daysEachSide: 365),
  fiveYears(label: '5Y', daysEachSide: 365 * 5),
  all(label: 'All', daysEachSide: null),
  custom(label: 'Custom', daysEachSide: null);

  const _ChartRange({required this.label, required this.daysEachSide});
  final String label;
  final int? daysEachSide;
}

class _ProjectionChart extends StatefulWidget {
  const _ProjectionChart({required this.detail, required this.accent});
  final ScenarioDetail detail;
  final Color accent;

  @override
  State<_ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<_ProjectionChart> {
  // 1Y is a focused default — past year of history + the next year
  // of projection. The full 5Y view is still one tap away.
  _ChartRange _range = _ChartRange.oneYear;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final accent = widget.accent;
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final hist = detail.historicalPoints;
    final proj = detail.projection;
    if (hist.isEmpty && proj.isEmpty) return const SizedBox.shrink();

    // Convert history to (daysFromToday, balance) — always negative X.
    final histSpotsAll = hist.map((p) {
      final days = p.date.difference(todayKey).inDays.toDouble();
      return FlSpot(days, p.balanceCents / 100);
    }).toList();

    // Projection: today = 0, future = positive X.
    final projSpotsAll = proj.map((p) {
      final days = p.date.difference(todayKey).inDays.toDouble();
      return FlSpot(days, p.balanceCents / 100);
    }).toList();

    // Resolve the visible-x window before filtering. minXData/maxXData
    // describe the full series; _resolvedRange picks a sub-window
    // based on the user-selected preset.
    final minXData = histSpotsAll.isNotEmpty ? histSpotsAll.first.x : 0.0;
    final maxXData = projSpotsAll.isNotEmpty ? projSpotsAll.last.x : 0.0;
    final (visibleMinX, visibleMaxX) = _resolvedRange(
      todayKey: todayKey,
      dataMinX: minXData,
      dataMaxX: maxXData,
    );

    // Filter spots to the visible window. Keep one spot on each
    // side OF the window if available so the line clips cleanly at
    // the chart edge instead of disappearing into empty space.
    final histSpots = _clipSpots(histSpotsAll, visibleMinX, visibleMaxX);
    final projSpots = _clipSpots(projSpotsAll, visibleMinX, visibleMaxX);

    // Join at today for a seamless line — prepend today's balance to projection.
    final todayBalance = detail.startingNetWorth / 100;
    if (projSpots.isNotEmpty && projSpots.first.x != 0) {
      projSpots.insert(0, FlSpot(0, todayBalance));
    }
    if (histSpots.isNotEmpty && histSpots.last.x != 0) {
      histSpots.add(FlSpot(0, todayBalance));
    }

    // Y-axis range across both lines + target.
    final allY = [...histSpots.map((s) => s.y), ...projSpots.map((s) => s.y)];
    if (allY.isEmpty) return const SizedBox.shrink();

    final targetY =
        detail.scenario.isGoal && detail.scenario.targetAmount != null
        ? detail.scenario.targetAmount! / 100
        : null;

    final minY = ([...allY, ?targetY].reduce((a, b) => a < b ? a : b)) - 500;
    final maxY = ([...allY, ?targetY].reduce((a, b) => a > b ? a : b)) + 500;

    // X range — visible window, clamped to actual data so an empty-
    // side window (e.g. "1Y" with no historical data) doesn't draw
    // a wide expanse of nothing.
    final minX = visibleMinX < minXData ? minXData : visibleMinX;
    final maxX = visibleMaxX > maxXData ? maxXData : visibleMaxX;

    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    // Build a lookup for bottom axis labels — sample ~4 dates.
    List<DateTime> sampleDates() {
      final all = [...hist.map((p) => p.date), ...proj.map((p) => p.date)]
        ..sort((a, b) => a.compareTo(b));
      if (all.isEmpty) return [];
      final step = (all.length / 4).ceil();
      return [for (var i = 0; i < all.length; i += step) all[i], all.last];
    }

    final labelDates = sampleDates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RangeChips(
          selected: _range,
          customFrom: _customFrom,
          customTo: _customTo,
          onSelected: (r) async {
            if (r == _ChartRange.custom) {
              final picked = await _pickCustomRange(context);
              if (picked != null) {
                setState(() {
                  _range = _ChartRange.custom;
                  _customFrom = picked.$1;
                  _customTo = picked.$2;
                });
              }
            } else {
              setState(() => _range = r);
            }
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
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
                            (d!.difference(todayKey).inDays.toDouble() - v)
                                .abs() <
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
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final label = s.barIndex == 0
                        ? 'Actual'
                        : s.barIndex == 1
                        ? 'Projected'
                        : 'Target';
                    return LineTooltipItem(
                      '$label\n${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(s.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Resolves the user's preset choice to an x-axis window in
  /// "days from today". Returns the full data range for `all` and
  /// the custom-picker range for `custom`.
  (double, double) _resolvedRange({
    required DateTime todayKey,
    required double dataMinX,
    required double dataMaxX,
  }) {
    switch (_range) {
      case _ChartRange.all:
        return (dataMinX, dataMaxX);
      case _ChartRange.custom:
        // Fall back to the full range when either bound is missing
        // (shouldn't happen — the chip only flips to custom after a
        // picker returns both — but defends against a malformed
        // state restore).
        if (_customFrom == null || _customTo == null) {
          return (dataMinX, dataMaxX);
        }
        final from = _customFrom!.difference(todayKey).inDays.toDouble();
        final to = _customTo!.difference(todayKey).inDays.toDouble();
        return (from, to);
      case _ChartRange.oneMonth:
      case _ChartRange.sixMonths:
      case _ChartRange.oneYear:
      case _ChartRange.fiveYears:
        final d = _range.daysEachSide!.toDouble();
        return (-d, d);
    }
  }

  /// Keeps only spots whose x lies within [minX]..[maxX] inclusive.
  /// Walks the (already x-sorted) list and slices.
  List<FlSpot> _clipSpots(List<FlSpot> spots, double minX, double maxX) {
    return spots.where((s) => s.x >= minX && s.x <= maxX).toList();
  }

  /// Opens a date-range picker for the "Custom" preset. Returns the
  /// (from, to) tuple or null when cancelled.
  Future<(DateTime, DateTime)?> _pickCustomRange(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today.add(const Duration(days: 365 * 30)),
      initialDateRange: DateTimeRange(
        start: _customFrom ?? today.subtract(const Duration(days: 365)),
        end: _customTo ?? today.add(const Duration(days: 365)),
      ),
    );
    if (picked == null) return null;
    return (picked.start, picked.end);
  }
}

/// Chip row for selecting the chart's visible date window. Lives
/// next to the chart in the same column.
class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.selected,
    required this.customFrom,
    required this.customTo,
    required this.onSelected,
  });
  final _ChartRange selected;
  final DateTime? customFrom;
  final DateTime? customTo;
  final ValueChanged<_ChartRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('M/d/yy');
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final r in _ChartRange.values)
          ChoiceChip(
            label: Text(
              r == _ChartRange.custom &&
                      selected == _ChartRange.custom &&
                      customFrom != null &&
                      customTo != null
                  ? '${fmt.format(customFrom!)} – ${fmt.format(customTo!)}'
                  : r.label,
              style: theme.textTheme.bodySmall,
            ),
            selected: selected == r,
            onSelected: (_) => onSelected(r),
          ),
      ],
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
        title: Text(
          event.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
                  showAppSheet<void>(
                    context,
                    child: AddEventSheet(
                      scenarioId: scenarioId,
                      existing: event,
                    ),
                  );
                } else if (v == 'delete') {
                  await ref
                      .read(scenariosRepositoryProvider)
                      .deleteEvent(event.id);
                  ref.invalidate(scenarioDetailProvider(scenarioId));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debt-payoff body
// ---------------------------------------------------------------------------
//
// Runs `simulateMultiDebtPayoff` against the current account balances
// (rather than the snapshot captured at scenario-creation time), so a
// payment made yesterday on a real card is reflected the next time the
// user opens the plan. The captured min-payment + APR on the
// scenario's targets stay authoritative — they're what the user
// committed to, not what the account happens to advertise today.

enum _DebtView { summary, perDebt }

class _DebtPayoffBody extends ConsumerStatefulWidget {
  const _DebtPayoffBody({required this.scenario, required this.accent});
  final Scenario scenario;
  final Color accent;

  @override
  ConsumerState<_DebtPayoffBody> createState() => _DebtPayoffBodyState();
}

class _DebtPayoffBodyState extends ConsumerState<_DebtPayoffBody> {
  _DebtView _view = _DebtView.summary;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (accounts) => _buildBody(context, accounts),
    );
  }

  Widget _buildBody(BuildContext context, List<Account> accounts) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scenario = widget.scenario;
    final targets = scenario.debtPayoffTargets ?? const [];
    final strategy =
        scenario.debtPayoffStrategy ?? DebtPayoffStrategy.avalanche;
    final monthlyBudget = scenario.debtPayoffMonthlyBudgetCents ?? 0;

    // Resolve live balances per target. Accounts that have been
    // deleted since the plan was saved silently drop out — matches
    // the simulator's contract.
    final startingPrincipals = <String, int>{
      for (final t in targets)
        if (accounts.any((a) => a.id == t.accountId))
          t.accountId: accounts
              .firstWhere((a) => a.id == t.accountId)
              .currentBalance
              .abs(),
    };

    final oneOffs = scenario.debtPayoffOneOffPayments ?? const [];
    final result = simulateMultiDebtPayoff(
      targets: targets,
      startingPrincipals: startingPrincipals,
      strategy: strategy,
      monthlyBudgetCents: monthlyBudget,
      startDate: DateTime.now(),
      oneOffPayments: oneOffs
          .map(
            (p) => OneOffPaymentInput(
              date: p.date,
              amountCents: p.amountCents,
              accountId: p.accountId,
            ),
          )
          .toList(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SizedBox(height: 16),
        _DebtSummaryHeader(
          result: result,
          strategy: strategy,
          monthlyBudget: monthlyBudget,
          accent: widget.accent,
          onEditBudget: () =>
              _editBudget(context, ref, scenario, monthlyBudget),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_DebtView>(
          segments: const [
            ButtonSegment(
              value: _DebtView.summary,
              label: Text('Summary'),
              icon: Icon(Icons.show_chart),
            ),
            ButtonSegment(
              value: _DebtView.perDebt,
              label: Text('Per debt'),
              icon: Icon(Icons.format_list_bulleted),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (s) => setState(() => _view = s.first),
        ),
        const SizedBox(height: 16),
        if (_view == _DebtView.summary)
          _DebtSummaryChart(result: result, accent: widget.accent)
        else
          _PerDebtList(result: result, accounts: accounts, targets: targets),
        const SizedBox(height: 20),
        _OneOffSection(
          scenario: scenario,
          accounts: accounts,
          oneOffs: oneOffs,
          onAdd: () => _addOneOff(context, scenario, accounts),
          onEdit: (idx) => _editOneOff(context, scenario, accounts, idx),
          onDelete: (idx) => _deleteOneOff(context, scenario, idx),
        ),
        if (!result.allPaidOff) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    monthlyBudget <
                            targets.fold<int>(
                              0,
                              (a, t) => a + t.minPaymentCents,
                            )
                        ? 'Your monthly budget doesn\'t cover the sum of '
                              'minimum payments. Edit the plan to increase '
                              'the budget.'
                        : 'At this budget, at least one debt isn\'t paid off '
                              'within the 50-year simulation horizon.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Mutations ───────────────────────────────────────────────
  // Each helper writes via the repository, then invalidates the
  // detail provider so the rebuild reads fresh data. Local state
  // isn't touched directly — Riverpod is the single source of
  // truth so the AddScenarioSheet editor path and these inline
  // helpers can't drift.

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    Scenario scenario,
    int currentCents,
  ) async {
    final newCents = await showDialog<int>(
      context: context,
      builder: (_) => _BudgetEditDialog(currentCents: currentCents),
    );
    if (newCents == null) return;
    await ref
        .read(scenariosRepositoryProvider)
        .updateScenario(
          scenarioId: scenario.id,
          debtPayoffMonthlyBudgetCents: newCents,
        );
    ref.invalidate(scenarioDetailProvider(scenario.id));
  }

  Future<void> _addOneOff(
    BuildContext context,
    Scenario scenario,
    List<Account> accounts,
  ) async {
    final result = await showDialog<OneOffPayment>(
      context: context,
      builder: (_) => _OneOffDialog(
        existing: null,
        eligibleAccounts: _eligibleDebtAccounts(scenario, accounts),
      ),
    );
    if (result == null) return;
    final next = [...?scenario.debtPayoffOneOffPayments, result];
    await _persistOneOffs(scenario, next);
  }

  Future<void> _editOneOff(
    BuildContext context,
    Scenario scenario,
    List<Account> accounts,
    int index,
  ) async {
    final list = scenario.debtPayoffOneOffPayments ?? const [];
    if (index < 0 || index >= list.length) return;
    final result = await showDialog<OneOffPayment>(
      context: context,
      builder: (_) => _OneOffDialog(
        existing: list[index],
        eligibleAccounts: _eligibleDebtAccounts(scenario, accounts),
      ),
    );
    if (result == null) return;
    final next = [...list]..[index] = result;
    await _persistOneOffs(scenario, next);
  }

  Future<void> _deleteOneOff(
    BuildContext context,
    Scenario scenario,
    int index,
  ) async {
    final list = scenario.debtPayoffOneOffPayments ?? const [];
    if (index < 0 || index >= list.length) return;
    final next = [...list]..removeAt(index);
    await _persistOneOffs(scenario, next);
  }

  Future<void> _persistOneOffs(
    Scenario scenario,
    List<OneOffPayment> next,
  ) async {
    await ref
        .read(scenariosRepositoryProvider)
        .updateScenario(
          scenarioId: scenario.id,
          debtPayoffOneOffPayments: next,
        );
    ref.invalidate(scenarioDetailProvider(scenario.id));
  }

  /// Debts on this plan that still have a positive principal —
  /// the only accounts a targeted one-off can usefully point at.
  List<Account> _eligibleDebtAccounts(
    Scenario scenario,
    List<Account> accounts,
  ) {
    final ids = (scenario.debtPayoffTargets ?? const [])
        .map((t) => t.accountId)
        .toSet();
    return accounts.where((a) => ids.contains(a.id)).toList();
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Three-tile header: debt-free date, total interest paid, total paid.
/// Wraps to two rows on narrow screens so amounts don't get squeezed
/// to ellipsis. The strategy/budget line is tappable — opens an
/// inline budget-edit dialog so the user doesn't have to enter the
/// full edit sheet to bump $50/month.
class _DebtSummaryHeader extends StatelessWidget {
  const _DebtSummaryHeader({
    required this.result,
    required this.strategy,
    required this.monthlyBudget,
    required this.accent,
    required this.onEditBudget,
  });
  final MultiDebtPayoffResult result;
  final DebtPayoffStrategy strategy;
  final int monthlyBudget;
  final Color accent;
  final VoidCallback onEditBudget;

  String _strategyLabel(DebtPayoffStrategy s) => switch (s) {
    DebtPayoffStrategy.avalanche => 'Avalanche (highest APR first)',
    DebtPayoffStrategy.snowball => 'Snowball (smallest balance first)',
    DebtPayoffStrategy.custom => 'Custom (per-debt extras)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('MMM yyyy');
    final freeDate = result.debtFreeDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SummaryTile(
              label: 'Debt-free',
              value: freeDate != null ? dateFmt.format(freeDate) : '—',
              color: accent,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Interest',
              value: formatCurrency(result.totalInterestCents),
              color: cs.error,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Total paid',
              value: formatCurrency(result.totalPaidCents),
              color: cs.outline,
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onEditBudget,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_strategyLabel(strategy)} · '
                    '${formatCurrency(monthlyBudget)}/month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 14, color: cs.outline),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Line chart of total outstanding debt across all accounts, summed
/// per simulated month. One line — the family debt curve.
class _DebtSummaryChart extends StatelessWidget {
  const _DebtSummaryChart({required this.result, required this.accent});
  final MultiDebtPayoffResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (result.months.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No projection — edit the plan to add debts.',
            style: TextStyle(color: cs.outline),
          ),
        ),
      );
    }
    final startTotal = result.startingPrincipals.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final spots = <FlSpot>[FlSpot(0, startTotal / 100)];
    for (var i = 0; i < result.months.length; i++) {
      final total = result.months[i].balances.values.fold<int>(
        0,
        (a, b) => a + b,
      );
      spots.add(FlSpot((i + 1).toDouble(), total / 100));
    }
    final maxY = (startTotal / 100) * 1.05;
    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.last.x,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (v, _) => Text(
                  fmt.format(v),
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (spots.last.x / 4).clamp(1, double.infinity),
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${v.toInt()}mo',
                    style: TextStyle(fontSize: 10, color: cs.outline),
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-debt list. Each row shows the starting principal, the
/// captured APR, total interest paid on that debt, and the month
/// it clears.
class _PerDebtList extends StatelessWidget {
  const _PerDebtList({
    required this.result,
    required this.accounts,
    required this.targets,
  });
  final MultiDebtPayoffResult result;
  final List<Account> accounts;
  final List<DebtPayoffTarget> targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('MMM yyyy');

    // Sum interest per debt across the schedule once, not in the
    // ListView builder.
    final interestByDebt = <String, int>{};
    for (final m in result.months) {
      for (final entry in m.interest.entries) {
        interestByDebt[entry.key] =
            (interestByDebt[entry.key] ?? 0) + entry.value;
      }
    }

    return Column(
      children: [
        for (final t in targets) ...[
          _PerDebtRow(
            account: accounts.where((a) => a.id == t.accountId).firstOrNull,
            startingPrincipal: result.startingPrincipals[t.accountId] ?? 0,
            aprBps: t.aprBps,
            interestPaid: interestByDebt[t.accountId] ?? 0,
            payoffDate: result.payoffDates[t.accountId],
            dateFmt: dateFmt,
            cs: cs,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _PerDebtRow extends StatelessWidget {
  const _PerDebtRow({
    required this.account,
    required this.startingPrincipal,
    required this.aprBps,
    required this.interestPaid,
    required this.payoffDate,
    required this.dateFmt,
    required this.cs,
    required this.theme,
  });
  final Account? account;
  final int startingPrincipal;
  final int aprBps;
  final int interestPaid;
  final DateTime? payoffDate;
  final DateFormat dateFmt;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final title = account?.name ?? '(deleted account)';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            account?.accountType.icon ?? Icons.credit_card_outlined,
            color: cs.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatCurrency(startingPrincipal)} · '
                  '${(aprBps / 100).toStringAsFixed(2)}% APR',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
                Text(
                  'Interest: ${formatCurrency(interestPaid)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payoffDate != null ? 'Paid off' : 'Not paid',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
              Text(
                payoffDate != null ? dateFmt.format(payoffDate!) : '—',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── One-off payments section ────────────────────────────────────────────────

/// "One-off payments" header + list + add button. Each row tap edits
/// the entry; a trailing menu deletes it. Renders an empty-state
/// blurb when no one-offs exist yet so the affordance is visible.
class _OneOffSection extends StatelessWidget {
  const _OneOffSection({
    required this.scenario,
    required this.accounts,
    required this.oneOffs,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final Scenario scenario;
  final List<Account> accounts;
  final List<OneOffPayment> oneOffs;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('MMM d, yyyy');
    final sorted = [...oneOffs]..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'One-off payments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No one-off payments yet. Add a tax refund, bonus, or '
              'anything else that\'s not part of your monthly budget.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          )
        else
          for (var i = 0; i < sorted.length; i++)
            _OneOffRow(
              payment: sorted[i],
              accountName: _resolveAccountName(sorted[i].accountId),
              dateFmt: dateFmt,
              // The sorted list re-orders the underlying list, so
              // resolve the original index by identity before
              // invoking the parent's edit/delete callbacks.
              onEdit: () => onEdit(oneOffs.indexOf(sorted[i])),
              onDelete: () => onDelete(oneOffs.indexOf(sorted[i])),
            ),
      ],
    );
  }

  String? _resolveAccountName(String? accountId) {
    if (accountId == null) return null;
    return accounts.where((a) => a.id == accountId).firstOrNull?.name;
  }
}

class _OneOffRow extends StatelessWidget {
  const _OneOffRow({
    required this.payment,
    required this.accountName,
    required this.dateFmt,
    required this.onEdit,
    required this.onDelete,
  });
  final OneOffPayment payment;
  final String? accountName;
  final DateFormat dateFmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        onTap: onEdit,
        leading: Icon(Icons.bolt_outlined, color: cs.outline),
        title: Text(
          formatCurrency(payment.amountCents),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${dateFmt.format(payment.date)} · '
          '${accountName ?? 'Any debt (via strategy)'}',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

// ─── Dialogs ────────────────────────────────────────────────────────────────

/// Inline budget editor — single number field, returns the new
/// cents value on Save or null on Cancel.
class _BudgetEditDialog extends StatefulWidget {
  const _BudgetEditDialog({required this.currentCents});
  final int currentCents;

  @override
  State<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<_BudgetEditDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: (widget.currentCents / 100).toStringAsFixed(0),
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final cents = parseToCents(_ctrl.text);
    if (cents <= 0) {
      setState(() => _error = 'Enter a positive amount.');
      return;
    }
    Navigator.of(context).pop(cents);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (\$)',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Add / edit a one-off lump-sum payment. Returns a non-null
/// [OneOffPayment] on Save, null on Cancel. Account picker is
/// optional — null targeting means "let the strategy decide."
class _OneOffDialog extends StatefulWidget {
  const _OneOffDialog({required this.existing, required this.eligibleAccounts});
  final OneOffPayment? existing;
  final List<Account> eligibleAccounts;

  @override
  State<_OneOffDialog> createState() => _OneOffDialogState();
}

class _OneOffDialogState extends State<_OneOffDialog> {
  late DateTime _date =
      widget.existing?.date ?? DateTime.now().add(const Duration(days: 30));
  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.existing != null
        ? (widget.existing!.amountCents / 100).toStringAsFixed(2)
        : '',
  );
  late String? _accountId = widget.existing?.accountId;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 31)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amount = parseToCents(_amountCtrl.text);
    if (amount <= 0) {
      setState(() => _error = 'Enter a positive amount.');
      return;
    }
    Navigator.of(context).pop(
      OneOffPayment(date: _date, amountCents: amount, accountId: _accountId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit one-off' : 'Add one-off'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountCtrl,
            autofocus: widget.existing == null,
            decoration: const InputDecoration(
              labelText: 'Amount (\$)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(dateFmt.format(_date)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _accountId,
            decoration: const InputDecoration(
              labelText: 'Apply to',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Any debt (via strategy)'),
              ),
              for (final a in widget.eligibleAccounts)
                DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

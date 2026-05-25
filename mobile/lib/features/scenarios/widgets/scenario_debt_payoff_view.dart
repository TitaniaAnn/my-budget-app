// Debt-payoff view for ScenarioDetailScreen — extracted from the
// screen file in audit R4 because the debt-payoff sub-tree was
// ~750 lines and made the screen file 1858 LOC.
//
// Runs `simulateMultiDebtPayoff` against the current account balances
// (rather than the snapshot captured at scenario-creation time), so a
// payment made yesterday on a real card is reflected the next time the
// user opens the plan. The captured min-payment + APR on the
// scenario's targets stay authoritative — they're what the user
// committed to, not what the account happens to advertise today.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/scenario.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../services/debt_payoff_simulator.dart';

enum _DebtView { summary, perDebt }

class DebtPayoffView extends ConsumerStatefulWidget {
  const DebtPayoffView({
    super.key,
    required this.scenario,
    required this.accent,
  });
  final Scenario scenario;
  final Color accent;

  @override
  ConsumerState<DebtPayoffView> createState() => _DebtPayoffViewState();
}

class _DebtPayoffViewState extends ConsumerState<DebtPayoffView> {
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
        else ...[
          _PerDebtChart(result: result, accounts: accounts, targets: targets),
          const SizedBox(height: 16),
          _PerDebtList(result: result, accounts: accounts, targets: targets),
        ],
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
    final dateFmt = kMonthYear;
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

/// Distinct colors cycled across debt lines in [_PerDebtChart].
/// Eight slots — a household with more debts than this is rare;
/// extras wrap around and rely on the legend to disambiguate.
const _perDebtPalette = <Color>[
  Color(0xFF6366F1), // indigo
  Color(0xFF22C55E), // green
  Color(0xFFEF4444), // red
  Color(0xFFF59E0B), // amber
  Color(0xFF3B82F6), // blue
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
];

/// Multi-line chart showing each debt's remaining principal over
/// the simulated months — one line per debt. Renders the family
/// payoff race in a single view: the user can see which debt
/// clears first, the slope of the rest, and where the lines fall
/// off as each debt zeroes.
///
/// X-axis: months from now. Y-axis: dollars. Colors cycle through
/// [_perDebtPalette]; the legend below the chart pairs each color
/// with its account name so a debt without a custom account color
/// is still identifiable.
class _PerDebtChart extends StatelessWidget {
  const _PerDebtChart({
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
    if (result.months.isEmpty || targets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Walk in target order so colors stay stable across renders
    // (the simulator's `balances` map keying-by-id has no order).
    final lines = <_PerDebtLine>[];
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      final start = result.startingPrincipals[t.accountId];
      if (start == null) continue; // dropped at sim start (zero balance)
      final spots = <FlSpot>[FlSpot(0, start / 100)];
      for (var m = 0; m < result.months.length; m++) {
        final bal = result.months[m].balances[t.accountId] ?? 0;
        spots.add(FlSpot((m + 1).toDouble(), bal / 100));
      }
      final acct = accounts.where((a) => a.id == t.accountId).firstOrNull;
      lines.add(
        _PerDebtLine(
          name: acct?.name ?? '(deleted)',
          color: _perDebtPalette[lines.length % _perDebtPalette.length],
          spots: spots,
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();

    final maxX = lines.first.spots.last.x;
    final maxY =
        lines
            .expand((l) => l.spots.map((s) => s.y))
            .fold<double>(0, (a, b) => a > b ? a : b) *
        1.05;
    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
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
                    interval: (maxX / 4).clamp(1, double.infinity),
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
                for (final line in lines)
                  LineChartBarData(
                    spots: line.spots,
                    isCurved: false,
                    color: line.color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final line = lines[s.barIndex];
                    return LineTooltipItem(
                      '${line.name}\n${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(s.y)}',
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final line in lines)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: line.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    line.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Internal helper bundling a per-debt line's name + color + points
/// so the build method doesn't juggle three parallel lists.
class _PerDebtLine {
  const _PerDebtLine({
    required this.name,
    required this.color,
    required this.spots,
  });
  final String name;
  final Color color;
  final List<FlSpot> spots;
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
    final dateFmt = kMonthYear;

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
    final dateFmt = kLongDate;
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
    final dateFmt = kLongDate;
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

/// Same-name twin of the `_SummaryTile` that lives in
/// scenario_detail_screen.dart. The two files share the tile
/// visually (tinted bg, no border, label + bold value) but private
/// classes can't be shared across files. Audit R3 flagged a
/// similarly-named tile in dashboard_screen.dart as a candidate
/// for dedup — that one has a different API (cents + icon) so this
/// duplication is intentional, not the audit's target.
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

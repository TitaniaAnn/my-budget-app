// Scenarios list screen — tabbed Plans / Goals view.
// Each card shows projected balance, net change, and color accent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/scenario.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../widgets/add_scenario_sheet.dart';

class ScenariosScreen extends ConsumerStatefulWidget {
  const ScenariosScreen({super.key});

  @override
  ConsumerState<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends ConsumerState<ScenariosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenariosAsync = ref.watch(scenariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenarios'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const AddScenarioSheet(),
        ),
        tooltip: 'New Scenario',
        child: const Icon(Icons.add),
      ),
      body: scenariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (scenarios) {
          final plans = scenarios.where((s) => !s.isGoal).toList();
          final goals = scenarios.where((s) => s.isGoal).toList();
          return TabBarView(
            controller: _tabs,
            children: [
              _ScenarioList(
                scenarios: plans,
                emptyMessage: 'No plans yet.\nTap + to create a what-if scenario.',
                onRefresh: () => ref.refresh(scenariosProvider.future),
              ),
              _ScenarioList(
                scenarios: goals,
                emptyMessage: 'No goals yet.\nTap + and toggle "Save as Goal".',
                onRefresh: () => ref.refresh(scenariosProvider.future),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ScenarioList extends ConsumerWidget {
  const _ScenarioList({
    required this.scenarios,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final List<Scenario> scenarios;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scenarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: scenarios.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _ScenarioCard(scenario: scenarios[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario card — taps to detail, shows projected balance + net change
// ---------------------------------------------------------------------------

class _ScenarioCard extends ConsumerWidget {
  const _ScenarioCard({required this.scenario});
  final Scenario scenario;

  Color get _accent {
    final hex = scenario.color;
    if (hex == null) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _accent;
    final detailAsync = ref.watch(scenarioDetailProvider(scenario.id));
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return GestureDetector(
      onTap: () => context.push('/scenarios/${scenario.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top bar
            Container(height: 4, color: accent),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scenario.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (scenario.description != null)
                              Text(
                                scenario.description!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.outline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Edit / delete menu
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
                              builder: (_) =>
                                  AddScenarioSheet(existing: scenario),
                            );
                          } else if (v == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Scenario?'),
                                content: const Text(
                                    'This will remove all events too.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ref
                                  .read(scenariosRepositoryProvider)
                                  .deleteScenario(scenario.id);
                              ref.invalidate(scenariosProvider);
                            }
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

                  const SizedBox(height: 12),

                  // Projection summary
                  detailAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, st) => Text('Could not load projection',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                    data: (detail) => Row(
                      children: [
                        _MiniStat(
                          label: 'Projected',
                          value: fmt.format(detail.finalBalance / 100),
                          color: accent,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          label: detail.netChange >= 0 ? 'Gain' : 'Loss',
                          value:
                              '${detail.netChange >= 0 ? '+' : ''}${fmt.format(detail.netChange / 100)}',
                          color: detail.netChange >= 0
                              ? Colors.green
                              : cs.error,
                        ),
                        if (scenario.isGoal &&
                            scenario.targetAmount != null) ...[
                          const SizedBox(width: 16),
                          _MiniStat(
                            label: 'Target',
                            value: fmt.format(
                                scenario.targetAmount! / 100),
                            color: cs.outline,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Goal target date
                  if (scenario.isGoal && scenario.targetDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 14, color: cs.outline),
                        const SizedBox(width: 4),
                        Text(
                          'By ${scenario.targetDate!.year}-'
                          '${scenario.targetDate!.month.toString().padLeft(2, '0')}-'
                          '${scenario.targetDate!.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
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

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: color, fontSize: 11)),
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

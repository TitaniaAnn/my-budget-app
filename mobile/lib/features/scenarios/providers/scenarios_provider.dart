// Riverpod providers for scenarios.
//
// The projection engine walks forward from today's net worth, applying each
// scenario event (and expanding recurring events) day-by-day to produce a
// list of (date, balanceCents) data points for the chart.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../models/scenario.dart';
import '../models/scenario_event.dart';
import '../repositories/scenarios_repository.dart';

part 'scenarios_provider.g.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

/// A single point on the projected balance chart.
class ProjectionPoint {
  const ProjectionPoint(this.date, this.balanceCents);
  final DateTime date;
  final int balanceCents;
}

/// A scenario paired with its projection series, events, and actual history.
class ScenarioDetail {
  const ScenarioDetail({
    required this.scenario,
    required this.events,
    required this.projection,
    required this.historicalPoints,
    required this.startingNetWorth,
  });

  final Scenario scenario;
  final List<ScenarioEvent> events;

  /// Weekly balance points from today forward — the scenario projection.
  final List<ProjectionPoint> projection;

  /// Actual net worth points reconstructed from past transactions (oldest first).
  /// Empty when there are no transactions in the lookback window.
  final List<ProjectionPoint> historicalPoints;

  /// Current net worth (sum of all account balances).
  final int startingNetWorth;

  /// Final projected balance at the end of the window.
  int get finalBalance =>
      projection.isEmpty ? startingNetWorth : projection.last.balanceCents;

  /// Net change vs starting net worth.
  int get netChange => finalBalance - startingNetWorth;
}

// ─── Projection engine ────────────────────────────────────────────────────────

/// How far ahead to project (in days). 5 years covers most goal horizons.
const _projectionDays = 365 * 5;

/// Expands a [ScenarioEvent] into every date it occurs within [windowEnd].
///
/// For non-recurring events this returns just [event.eventDate].
/// For recurring events it parses the RRULE and generates dates.
/// Currently supports FREQ=DAILY, WEEKLY, MONTHLY, YEARLY with optional COUNT.
List<DateTime> _expandDates(ScenarioEvent event, DateTime windowEnd) {
  final start = DateTime(
    event.eventDate.year,
    event.eventDate.month,
    event.eventDate.day,
  );
  if (!event.isRecurring || event.recurrenceRule == null) {
    return start.isAfter(windowEnd) ? [] : [start];
  }

  // Parse a minimal subset of RRULE (FREQ + optional COUNT/UNTIL).
  final rule = event.recurrenceRule!.toUpperCase();
  String rruleVal(String key) {
    final match = RegExp('$key=([^;]+)').firstMatch(rule);
    return match?.group(1) ?? '';
  }

  final freq = rruleVal('FREQ');
  final count = int.tryParse(rruleVal('COUNT'));
  final untilStr = rruleVal('UNTIL');
  DateTime? until;
  if (untilStr.isNotEmpty && untilStr.length >= 8) {
    until = DateTime.tryParse(
        '${untilStr.substring(0, 4)}-${untilStr.substring(4, 6)}-${untilStr.substring(6, 8)}');
  }
  final effectiveEnd =
      until != null && until.isBefore(windowEnd) ? until : windowEnd;

  final dates = <DateTime>[];
  var current = start;
  while (!current.isAfter(effectiveEnd)) {
    if (count != null && dates.length >= count) break;
    dates.add(current);
    current = switch (freq) {
      'DAILY' => current.add(const Duration(days: 1)),
      'WEEKLY' => current.add(const Duration(days: 7)),
      'MONTHLY' => DateTime(current.year, current.month + 1, current.day),
      'YEARLY' => DateTime(current.year + 1, current.month, current.day),
      _ => effectiveEnd.add(const Duration(days: 1)), // unknown — stop
    };
  }
  return dates;
}

/// Builds the projection series for [events] starting at [startingBalance].
///
/// Produces one [ProjectionPoint] per day from [from] to [from + windowDays].
/// Events that fall on a day are applied as a lump sum to the running balance.
List<ProjectionPoint> _buildProjection({
  required int startingBalance,
  required List<ScenarioEvent> events,
  required DateTime from,
  required int windowDays,
}) {
  final windowEnd = from.add(Duration(days: windowDays));

  // Build a map: date → net delta in cents for that day.
  final deltas = <DateTime, int>{};
  for (final event in events) {
    final int delta =
        event.eventType.isPositive ? event.amount : -event.amount;
    for (final date in _expandDates(event, windowEnd)) {
      final key = DateTime(date.year, date.month, date.day);
      deltas[key] = (deltas[key] ?? 0) + delta;
    }
  }

  // Walk forward day-by-day accumulating the balance.
  // To keep the chart readable we sample every 7 days (weekly points).
  final points = <ProjectionPoint>[];
  var balance = startingBalance;
  for (var i = 0; i <= windowDays; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    balance += deltas[day] ?? 0;
    if (i % 7 == 0 || i == windowDays) {
      points.add(ProjectionPoint(day, balance));
    }
  }
  return points;
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// All scenarios for the current household.
@riverpod
Future<List<Scenario>> scenarios(ScenariosRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];
  return ref.read(scenariosRepositoryProvider).fetchScenarios(householdId);
}

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.
@riverpod
Future<ScenarioDetail> scenarioDetail(
  ScenarioDetailRef ref,
  String scenarioId,
) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) throw StateError('No household');

  final repo = ref.read(scenariosRepositoryProvider);
  final accountsRepo = ref.read(accountsRepositoryProvider);

  final (scenariosList, events, accounts) = await (
    repo.fetchScenarios(householdId),
    repo.fetchEvents(scenarioId),
    accountsRepo.fetchAccounts(householdId),
  ).wait;

  final scenario =
      scenariosList.firstWhere((s) => s.id == scenarioId);

  // Net worth = assets − credit card debt.
  final netWorth = accounts.fold<int>(0, (sum, a) {
    if (a.accountType.name == 'credit_card') {
      return sum - a.currentBalance.abs();
    }
    return sum + a.currentBalance;
  });

  // Projection window: use target date if it's a goal, otherwise 5 years.
  final from = DateTime.now();
  int windowDays = _projectionDays;
  if (scenario.isGoal && scenario.targetDate != null) {
    final goalDays = scenario.targetDate!.difference(from).inDays;
    if (goalDays > 0) windowDays = goalDays;
  }

  // Fetch historical and build projection in parallel.
  final (rawHistory, projection) = await (
    repo.fetchHistoricalNetWorth(
      householdId: householdId,
      currentNetWorth: netWorth,
    ),
    Future.value(_buildProjection(
      startingBalance: netWorth,
      events: events,
      from: from,
      windowDays: windowDays,
    )),
  ).wait;

  final historicalPoints = rawHistory
      .map((p) => ProjectionPoint(p.date, p.balanceCents))
      .toList();

  return ScenarioDetail(
    scenario: scenario,
    events: events,
    projection: projection,
    historicalPoints: historicalPoints,
    startingNetWorth: netWorth,
  );
}

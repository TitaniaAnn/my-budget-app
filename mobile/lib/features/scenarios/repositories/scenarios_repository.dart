// Data access layer for scenarios and scenario events.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/scenario.dart';
import '../models/scenario_event.dart';

part 'scenarios_repository.g.dart';

@riverpod
ScenariosRepository scenariosRepository(ScenariosRepositoryRef ref) {
  return ScenariosRepository();
}

/// Walks backward from today's known net worth, emitting one end-of-day
/// balance per transaction date.
///
/// `B_today = currentNetWorth`, and for each older transaction date `d` in
/// descending order, `B_d = B_{prev} - D_{prev}`, where `prev` is the
/// previous date emitted (or today on the first step). Days with no
/// transactions are not in the output — adjacent emitted points are correct
/// because non-transaction days have zero delta.
///
/// Returns points oldest-first so a chart can draw left-to-right.
///
/// Pure function so it can be regression-tested without a Supabase fixture
/// (this is the math the off-by-one bug lived in).
List<({DateTime date, int balanceCents})> reconstructHistoricalNetWorth({
  required int currentNetWorth,
  required Map<DateTime, int> deltasByDate,
  required DateTime today,
}) {
  final todayKey = DateTime(today.year, today.month, today.day);

  // Sorted descending; only dates strictly after today are dropped (a
  // misdated future row should not pull current-balance into the past).
  final dates = deltasByDate.keys.where((d) => !d.isAfter(todayKey)).toList()
    ..sort((a, b) => b.compareTo(a));

  final points = <({DateTime date, int balanceCents})>[];
  var balance = currentNetWorth;
  var prev = todayKey;
  points.add((date: todayKey, balanceCents: balance));

  for (final date in dates) {
    if (!date.isBefore(prev)) continue; // skip today / duplicates
    // Undo the deltas of `prev` to step from end-of-`prev` to end-of-`date`.
    // Between two adjacent transaction dates there are no other deltas, so
    // this is a single subtraction even when many days separate them.
    balance -= deltasByDate[prev] ?? 0;
    points.add((date: date, balanceCents: balance));
    prev = date;
  }

  return points.reversed.toList();
}

class ScenariosRepository {
  /// Reconstructs historical net worth by walking backward from [currentNetWorth].
  ///
  /// Fetches all transactions for the household from [lookbackDays] ago to
  /// today, groups them by date, then replays them in reverse to build a
  /// running end-of-day balance at each transaction date. Returns points
  /// oldest-first.
  ///
  /// Because account balances already reflect all past transactions, we start
  /// from today's known net worth (== end-of-today balance) and walk back:
  /// `B_{date} = B_{prev} - D_{prev}`, where `prev` is the next-newer date
  /// emitted (or today on the first step). Concretely: to compute end-of-day
  /// balance for `date`, we undo the transactions that happened on every
  /// day strictly *after* `date` — which, between two adjacent transaction
  /// dates in the sorted list, reduces to undoing only the newer one.
  Future<List<({DateTime date, int balanceCents})>> fetchHistoricalNetWorth({
    required String householdId,
    required int currentNetWorth,
    int lookbackDays = 365,
  }) async {
    final from = DateTime.now().subtract(Duration(days: lookbackDays));
    final data = await supabase
        .from('transactions')
        .select('transaction_date, amount')
        .eq('household_id', householdId)
        .gte('transaction_date', from.toIso8601String().substring(0, 10))
        .order('transaction_date', ascending: false);

    // Aggregate net deltas per date (sum of all transaction amounts).
    final deltasByDate = <DateTime, int>{};
    for (final row in data) {
      final dateStr = row['transaction_date'] as String;
      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      deltasByDate[date] = (deltasByDate[date] ?? 0) + (row['amount'] as int);
    }

    return reconstructHistoricalNetWorth(
      currentNetWorth: currentNetWorth,
      deltasByDate: deltasByDate,
      today: DateTime.now(),
    );
  }

  /// Fetches all scenarios for the household, newest first.
  Future<List<Scenario>> fetchScenarios(String householdId) async {
    final data = await supabase
        .from('scenarios')
        .select()
        .eq('household_id', householdId)
        .order('created_at', ascending: false);
    return data.map<Scenario>(Scenario.fromJson).toList();
  }

  /// Fetches all events for a scenario, ordered chronologically by
  /// event_date ASC then sort_order ASC. Scenarios are forward-
  /// projecting timelines, so the user sees the earliest event first
  /// — left-to-right in any rendering.
  ///
  /// postgrest's .order() defaults to DESC, so the explicit
  /// `ascending: true` is load-bearing: without it the timeline
  /// renders backwards (farthest-future event first).
  Future<List<ScenarioEvent>> fetchEvents(String scenarioId) async {
    final data = await supabase
        .from('scenario_events')
        .select()
        .eq('scenario_id', scenarioId)
        .order('event_date', ascending: true)
        .order('sort_order', ascending: true);
    return data.map<ScenarioEvent>(ScenarioEvent.fromJson).toList();
  }

  /// Creates a new scenario and returns it.
  Future<Scenario> createScenario({
    required String householdId,
    required String createdBy,
    required String name,
    String? description,
    String? color,
    bool isGoal = false,
    int? targetAmount,
    DateTime? targetDate,
    DateTime? baseDate,
  }) async {
    final data = await supabase
        .from('scenarios')
        .insert({
          'household_id': householdId,
          'created_by': createdBy,
          'name': name,
          'description': ?description,
          'color': ?color,
          'base_date': (baseDate ?? DateTime.now()).toIso8601String().substring(
            0,
            10,
          ),
          'is_baseline': false,
          'is_goal': isGoal,
          'target_amount': ?targetAmount,
          'target_date': ?targetDate?.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return Scenario.fromJson(data);
  }

  /// Updates scenario metadata.
  Future<Scenario> updateScenario({
    required String scenarioId,
    String? name,
    String? description,
    String? color,
    bool? isGoal,
    int? targetAmount,
    DateTime? targetDate,
  }) async {
    final data = await supabase
        .from('scenarios')
        .update({
          'name': ?name,
          'description': ?description,
          'color': ?color,
          'is_goal': ?isGoal,
          'target_amount': ?targetAmount,
          'target_date': ?targetDate?.toIso8601String().substring(0, 10),
        })
        .eq('id', scenarioId)
        .select()
        .single();
    return Scenario.fromJson(data);
  }

  /// Deletes a scenario and its events (cascade handled by DB).
  Future<void> deleteScenario(String scenarioId) async {
    await supabase.from('scenarios').delete().eq('id', scenarioId);
  }

  /// Creates a new event on a scenario.
  Future<ScenarioEvent> createEvent({
    required String scenarioId,
    required EventType eventType,
    required String label,
    required DateTime eventDate,
    required int amountCents,
    bool isRecurring = false,
    String? recurrenceRule,
    String? accountId,
    int sortOrder = 0,
    int? paymentAprBps,
  }) async {
    final data = await supabase
        .from('scenario_events')
        .insert({
          'scenario_id': scenarioId,
          'event_type': eventType.name,
          'label': label,
          'event_date': eventDate.toIso8601String().substring(0, 10),
          'amount': amountCents,
          'is_recurring': isRecurring,
          'recurrence_rule': ?recurrenceRule,
          'account_id': ?accountId,
          'sort_order': sortOrder,
          'payoff_apr_bps': ?paymentAprBps,
          'parameters': {},
        })
        .select()
        .single();
    return ScenarioEvent.fromJson(data);
  }

  /// Updates an existing event.
  Future<ScenarioEvent> updateEvent({
    required String eventId,
    String? label,
    DateTime? eventDate,
    int? amountCents,
    EventType? eventType,
    bool? isRecurring,
    String? recurrenceRule,
    int? paymentAprBps,
  }) async {
    final data = await supabase
        .from('scenario_events')
        .update({
          'label': ?label,
          'event_date': ?eventDate?.toIso8601String().substring(0, 10),
          'amount': ?amountCents,
          'event_type': ?eventType?.name,
          'is_recurring': ?isRecurring,
          'recurrence_rule': ?recurrenceRule,
          'payoff_apr_bps': ?paymentAprBps,
        })
        .eq('id', eventId)
        .select()
        .single();
    return ScenarioEvent.fromJson(data);
  }

  /// Deletes a single event.
  Future<void> deleteEvent(String eventId) async {
    await supabase.from('scenario_events').delete().eq('id', eventId);
  }
}

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

class ScenariosRepository {
  /// Reconstructs historical net worth by walking backward from [currentNetWorth].
  ///
  /// Fetches all transactions for the household from [lookbackDays] ago to
  /// today, groups them by date, then replays them in reverse to build a
  /// running balance at each date. Returns points oldest-first.
  ///
  /// Because account balances already reflect all past transactions, we
  /// start from today's known net worth and subtract each day's net delta
  /// as we step backward.
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
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      deltasByDate[date] =
          (deltasByDate[date] ?? 0) + (row['amount'] as int);
    }

    // Walk backward from today, subtracting each day's transactions.
    // This reconstructs what the balance was before those transactions.
    final today = DateTime.now();
    final todayKey =
        DateTime(today.year, today.month, today.day);

    var balance = currentNetWorth;
    final points = <({DateTime date, int balanceCents})>[];

    // Collect all unique dates in descending order.
    final dates = deltasByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Insert today as the anchor point.
    points.add((date: todayKey, balanceCents: balance));

    for (final date in dates) {
      if (date == todayKey) continue;
      // Reverse the transactions that happened on this date.
      balance -= deltasByDate[date]!;
      points.add((date: date, balanceCents: balance));
    }

    // Return oldest-first so the chart draws left-to-right.
    return points.reversed.toList();
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

  /// Fetches all events for a scenario, ordered by date then sort_order.
  Future<List<ScenarioEvent>> fetchEvents(String scenarioId) async {
    final data = await supabase
        .from('scenario_events')
        .select()
        .eq('scenario_id', scenarioId)
        .order('event_date')
        .order('sort_order');
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
          'base_date':
              (baseDate ?? DateTime.now()).toIso8601String().substring(0, 10),
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
  }) async {
    final data = await supabase
        .from('scenario_events')
        .update({
          'label': ?label,
          'event_date':
              ?eventDate?.toIso8601String().substring(0, 10),
          'amount': ?amountCents,
          'event_type': ?eventType?.name,
          'is_recurring': ?isRecurring,
          'recurrence_rule': ?recurrenceRule,
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

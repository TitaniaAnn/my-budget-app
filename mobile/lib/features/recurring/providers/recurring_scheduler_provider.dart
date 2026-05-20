// Fire-and-forget scheduler trigger.
//
// The recurring scheduler (run_recurring_scheduler, migration 032)
// is invoked on app startup via this provider: once per app
// process, before the dashboard fetches its data. Riverpod's cache
// gives us the "once" semantic for free — the future resolves on
// first read and stays resolved for the rest of the session.
//
// The dashboard provider awaits this so any due rules materialise
// before the dashboard reads transactions / spending — otherwise
// the user would see stale data for one frame until the next
// refresh.
//
// Errors from the scheduler are surfaced as a Future failure (the
// dashboard's error state will catch them). A single failed pass
// shouldn't bring the whole app down — but we don't silently
// swallow either, because a misconfigured rule that's repeatedly
// hitting an FK violation deserves attention.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/household_provider.dart';
import '../repositories/recurring_transactions_repository.dart';

part 'recurring_scheduler_provider.g.dart';

/// Runs [RecurringTransactionsRepository.runScheduler] once per
/// app process. Returns the count of transactions emitted.
///
/// Resolves to 0 immediately when the user has no household
/// (pre-auth, etc.) — the scheduler has nothing to act on then,
/// and we don't want the dashboard provider to be blocked by an
/// auth-state race.
@Riverpod(keepAlive: true)
Future<int> runRecurringScheduler(RunRecurringSchedulerRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return 0;
  final repo = ref.read(recurringTransactionsRepositoryProvider);
  return repo.runScheduler(householdId: householdId);
}

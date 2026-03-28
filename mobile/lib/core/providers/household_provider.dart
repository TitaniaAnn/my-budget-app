// Provides the current user's household ID.
//
// Every piece of user data in the DB is scoped to a household_id. This
// provider resolves that ID once so other providers don't each need to
// query household_members separately.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../supabase/supabase_client.dart';

part 'household_provider.g.dart';

/// Fetches the household_id for the currently authenticated user.
///
/// Returns null if the user is not logged in. The household is created
/// automatically by the [handle_new_user] DB trigger on signup, so every
/// user is guaranteed to have exactly one household.
@riverpod
Future<String?> householdId(HouseholdIdRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final row = await supabase
      .from('household_members')
      .select('household_id')
      .eq('user_id', user.id)
      .single();

  return row['household_id'] as String?;
}

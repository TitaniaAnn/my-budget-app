// Settings providers — profile info, household info, and update methods.
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

// ── Models ────────────────────────────────────────────────────────────────────

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String displayName,
  }) = _UserProfile;
}

@freezed
class HouseholdMember with _$HouseholdMember {
  const factory HouseholdMember({
    required String userId,
    required String displayName,
    required String role,
    required bool isCurrentUser,
  }) = _HouseholdMember;
}

@freezed
class HouseholdInfo with _$HouseholdInfo {
  const factory HouseholdInfo({
    required String householdId,
    required String householdName,
    required bool isOwner,
    required List<HouseholdMember> members,
  }) = _HouseholdInfo;
}

// ── Repository ────────────────────────────────────────────────────────────────

class SettingsRepository {
  Future<void> updateDisplayName(String name) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('household_members')
        .update({'display_name': name})
        .eq('user_id', userId);
  }

  Future<void> updateHouseholdName(String householdId, String name) async {
    await supabase
        .from('households')
        .update({'name': name})
        .eq('id', householdId);
  }
}

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository();
}

// ── Providers ─────────────────────────────────────────────────────────────────

@riverpod
Future<UserProfile> profile(ProfileRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  final row = await supabase
      .from('household_members')
      .select('display_name')
      .eq('user_id', user.id)
      .single();

  return UserProfile(
    userId: user.id,
    displayName: (row['display_name'] as String?) ?? user.email ?? '',
  );
}

@riverpod
Future<HouseholdInfo> householdInfo(HouseholdInfoRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) throw Exception('No household found');

  final (householdRow, membersRows) = await (
    supabase.from('households').select('name').eq('id', householdId).single(),
    supabase
        .from('household_members')
        .select('user_id, display_name, role')
        .eq('household_id', householdId),
  ).wait;

  final members = (membersRows as List).map((m) {
    final uid = m['user_id'] as String;
    return HouseholdMember(
      userId: uid,
      displayName: (m['display_name'] as String?) ?? '',
      role: (m['role'] as String?) ?? 'member',
      isCurrentUser: uid == user.id,
    );
  }).toList();

  final isOwner = members
      .where((m) => m.isCurrentUser)
      .any((m) => m.role == 'owner');

  return HouseholdInfo(
    householdId: householdId,
    householdName: (householdRow['name'] as String?) ?? '',
    isOwner: isOwner,
    members: members,
  );
}

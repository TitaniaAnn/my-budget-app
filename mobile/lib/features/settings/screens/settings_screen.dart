// Settings screen — profile, household, appearance, and account actions.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/sync/last_synced_provider.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/currency/screens/currency_settings_screen.dart';
import '../../../features/holdings/screens/target_allocations_screen.dart';
import '../../../features/notifications/screens/notification_settings_screen.dart';
import '../../../features/receipts/screens/review_ocr_lines_screen.dart';
import '../../../features/recurring/screens/recurring_transactions_screen.dart';
import '../../../features/reports/screens/monthly_report_screen.dart';
import '../../../features/transactions/screens/manage_tags_screen.dart';
import '../../../features/transactions/screens/review_categorisations_screen.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final householdAsync = ref.watch(householdInfoProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile ────────────────────────────────────────────────────
          _SectionHeader('Profile'),
          profileAsync.when(
            loading: () => const _LoadingTile(),
            error: (e, _) => _ErrorTile(e.toString()),
            data: (profile) => _ProfileTile(
              displayName: profile.displayName,
              email: user?.email ?? '',
              onEdit: () => _editDisplayName(context, ref, profile.displayName),
            ),
          ),

          // ── Household ──────────────────────────────────────────────────
          _SectionHeader('Household'),
          householdAsync.when(
            loading: () => const _LoadingTile(),
            error: (e, _) => _ErrorTile(e.toString()),
            data: (info) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Household Name'),
                  subtitle: Text(info.householdName),
                  trailing: info.isOwner
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: info.isOwner
                      ? () =>
                            _editHouseholdName(context, ref, info.householdName)
                      : null,
                ),
                const Divider(),
                ...info.members.map(
                  (m) => ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        m.displayName.isNotEmpty
                            ? m.displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(m.displayName),
                    subtitle: Text(m.role),
                    trailing: m.isCurrentUser
                        ? const Chip(label: Text('You'))
                        : null,
                  ),
                ),
                if (info.isOwner) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: const Text('Invite Member'),
                    subtitle: const Text('Share a code to add family'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _inviteMember(context, ref, info.householdId),
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('Join with Code'),
                  subtitle: const Text(
                    'Enter an invite code to join a household',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _joinWithCode(context, ref),
                ),
              ],
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _ThemeTile(current: themeMode),

          // ── Categorisations ────────────────────────────────────────────
          _SectionHeader('Categorisations'),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Review uncertain ML guesses'),
            subtitle: const Text(
              'Confirm or correct categorisations the model was unsure about',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReviewCategorisationsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Review OCR lines'),
            subtitle: const Text(
              'Confirm or correct line items the recognizer was unsure about',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReviewOcrLinesScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Manage Tags'),
            subtitle: const Text('Rename, recolor, or remove household tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ManageTagsScreen()),
            ),
          ),

          // ── Automation ─────────────────────────────────────────────────
          _SectionHeader('Automation'),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Recurring Transactions'),
            subtitle: const Text(
              'Rules that auto-create transactions on a cadence',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecurringTransactionsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text(
              'Over-budget and large-transaction alerts (local)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Linked Banks'),
            subtitle: const Text(
              'Plaid-connected accounts and their sync status',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/plaid'),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Target Allocation'),
            subtitle: const Text(
              'Set per-asset-class targets to surface rebalance drift',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TargetAllocationsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: const Text(
              'Display currency + FX rates for cross-currency totals',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CurrencySettingsScreen(),
              ),
            ),
          ),

          // ── Sync (Phase 5c) ────────────────────────────────────────────
          _SectionHeader('Sync'),
          const _SyncStatusTile(),

          // ── Reports ────────────────────────────────────────────────────
          _SectionHeader('Reports'),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Monthly Report'),
            subtitle: const Text(
              'Income, expenses, and category breakdown — shareable as PDF',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonthlyReportScreen(),
              ),
            ),
          ),

          // ── Account ────────────────────────────────────────────────────
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () => _changePassword(context, ref, user?.email ?? ''),
          ),
          const Divider(),
          // Audit 2026-05-26 M3: GDPR Right to Access. Migration
          // 067's export_my_data RPC returns one JSON blob with
          // every row the user can see across their household(s).
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export my data'),
            subtitle: const Text(
              'Download a JSON copy of everything in your household',
            ),
            onTap: () => _exportMyData(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: context.cs.error),
            // Audit 2026-05-26 I1: canonical proof-of-concept
            // migration to AppLocalizations. Adding a new locale =
            // adding `lib/l10n/app_<locale>.arb`, regenerating, no
            // code touch beyond strings here.
            title: Text(
              AppLocalizations.of(context).settingsSignOut,
              style: TextStyle(color: context.cs.error),
            ),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          // Audit 2026-05-26 M3 supersedes the audit_2026_05_25 C3
          // honest-but-empty placeholder. The real cascade-delete
          // edge function (delete-my-account) plus migration 067's
          // delete_my_household RPC together remove the household
          // (cascades wire the rest) AND the auth.users row.
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: context.cs.error),
            title: Text(
              'Delete my account',
              style: TextStyle(color: context.cs.error),
            ),
            subtitle: const Text(
              'Permanently delete your household + every record',
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'MyBudget · v1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Action helpers ─────────────────────────────────────────────────────────

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final ctrl = TextEditingController(text: current);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Display Name'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != null && result.isNotEmpty) {
        await ref.read(settingsRepositoryProvider).updateDisplayName(result);
        ref.invalidate(profileProvider);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _editHouseholdName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final ctrl = TextEditingController(text: current);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Household Name'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != null && result.isNotEmpty) {
        final householdId = await ref.read(householdIdProvider.future);
        if (householdId != null) {
          await ref
              .read(settingsRepositoryProvider)
              .updateHouseholdName(householdId, result);
          ref.invalidate(householdInfoProvider);
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _changePassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset link to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await supabase.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        context.showSnackBar('Password reset email sent.');
      }
    }
  }

  Future<void> _inviteMember(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) async {
    final emailCtrl = TextEditingController();
    String selectedRole = 'partner';

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setState) => AlertDialog(
            title: const Text('Invite Member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'partner', child: Text('Partner')),
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                  ],
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Generate Code'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || emailCtrl.text.trim().isEmpty) return;

      try {
        final code = await ref
            .read(settingsRepositoryProvider)
            .createInvite(
              householdId: householdId,
              email: emailCtrl.text.trim(),
              role: selectedRole,
            );
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Invite Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Share this code with ${emailCtrl.text.trim()}:'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        dialogCtx,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expires in 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(dialogCtx).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('Failed to create invite: $e');
        }
      }
    } finally {
      emailCtrl.dispose();
    }
  }

  Future<void> _joinWithCode(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Join Household'),
          content: TextField(
            controller: codeCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'e.g. AB12CD34',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Join'),
            ),
          ],
        ),
      );

      if (confirmed != true || codeCtrl.text.trim().isEmpty) return;

      final error = await ref
          .read(settingsRepositoryProvider)
          .acceptInvite(codeCtrl.text.trim());

      if (!context.mounted) return;

      if (error != null) {
        context.showSnackBar(error);
      } else {
        ref.invalidate(householdInfoProvider);
        context.showSnackBar('Welcome to your new household!');
      }
    } finally {
      codeCtrl.dispose();
    }
  }

  /// Audit 2026-05-26 M3 — GDPR Right to Access (Art. 15).
  /// Calls the `export_my_data` RPC, encodes the JSONB return
  /// as a pretty-printed string, opens a copy-friendly dialog
  /// so the user can paste the export wherever they want it.
  Future<void> _exportMyData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await supabase.rpc<dynamic>('export_my_data');
      if (!context.mounted) return;
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Your data'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pretty));
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Audit 2026-05-26 M3 — GDPR Right to Erasure (Art. 17).
    // Supersedes the audit_2026_05_25 C3 honest-but-empty
    // placeholder. The delete-my-account edge function calls
    // migration 067's delete_my_household RPC (cascades the
    // entire data graph) AND auth.admin.deleteUser to remove
    // the auth.users row itself.
    //
    // Caller MUST be the household owner; the RPC raises 42501
    // otherwise and the edge function surfaces 403. Members
    // who aren't owners need to leave the household separately.
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null || !context.mounted) return;

    final confirmed = await confirmDestructive(
      context,
      title: 'Delete your account?',
      message:
          'This permanently deletes:\n\n'
          ' • your household and every account, transaction,\n'
          '   receipt, budget, holding, scenario, and tag\n'
          ' • every linked bank (Plaid items) on this household\n'
          " • your sign-in credentials\n\n"
          "Members of the household who aren't you are removed\n"
          "from this household but their auth accounts stay.\n\n"
          "This cannot be undone.",
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await supabase.functions.invoke(
        'delete-my-account',
        body: {'householdId': householdId},
      );
      if (resp.data is Map &&
          (resp.data as Map)['auth_user_deleted'] == true) {
        // Both halves succeeded. Sign out locally; auth.admin
        // already invalidated the session server-side.
        await supabase.auth.signOut();
        if (!context.mounted) return;
        context.go('/login');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account deleted.'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Unexpected response: ${resp.data}'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Deletion failed: $e')),
      );
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) =>
      const ListTile(title: LinearProgressIndicator());
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
    ),
    title: Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 13,
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.displayName,
    required this.email,
    required this.onEdit,
  });
  final String displayName;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(email),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onEdit,
    );
  }
}

/// Three-way theme toggle: System / Light / Dark.
class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(_icon(current)),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 18),
          ),
        ],
        selected: {current},
        onSelectionChanged: (s) =>
            ref.read(themeModeNotifierProvider.notifier).setMode(s.first),
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  IconData _icon(ThemeMode m) => switch (m) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };
}

/// Settings → Sync section (Phase 5c). Shows the "last synced"
/// timestamp + pending-write count and exposes a manual "Sync
/// now" affordance that drains the queue and re-fetches.
class _SyncStatusTile extends ConsumerWidget {
  const _SyncStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSyncedAsync = ref.watch(lastSyncedAtProvider);
    final pendingAsync = ref.watch(pendingWritesCountValueProvider);
    final pendingUploadsAsync = ref.watch(
      pendingStorageUploadsCountValueProvider,
    );
    final colors = context.appColors;

    final lastSynced = lastSyncedAsync.valueOrNull;
    final pending = pendingAsync.valueOrNull ?? 0;
    final pendingUploads = pendingUploadsAsync.valueOrNull ?? 0;
    final pendingTotal = pending + pendingUploads;

    final subtitleParts = <String>[
      'Last synced ${formatLastSynced(lastSynced, DateTime.now())}',
      if (pending > 0)
        pending == 1
            ? '1 change waiting to upload'
            : '$pending changes waiting to upload',
      if (pendingUploads > 0)
        pendingUploads == 1
            ? '1 receipt image waiting to upload'
            : '$pendingUploads receipt images waiting to upload',
    ];

    return ListTile(
      leading: Icon(
        pendingTotal > 0
            ? Icons.cloud_sync_outlined
            : Icons.cloud_done_outlined,
        color: pendingTotal > 0 ? BrandColors.warning : colors.textMuted,
      ),
      title: const Text('Sync now'),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: const Icon(Icons.refresh),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final result = await ref
            .read(syncCoordinatorProvider)
            .pullToRefresh(ref);
        // Brief feedback so the user knows the action took effect.
        // Two messages: a "no work" path (queue was empty, just
        // re-fetched) and a "replayed N, failed M" path.
        final text = result.drainAttempted == 0
            ? 'Refreshed.'
            : result.drainFailed == 0
            ? 'Refreshed and replayed ${result.drainAttempted} pending '
                  '${result.drainAttempted == 1 ? "change" : "changes"}.'
            : 'Refreshed. ${result.drainAttempted - result.drainFailed} '
                  'replayed, ${result.drainFailed} still pending.';
        messenger.showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
        );
      },
    );
  }
}

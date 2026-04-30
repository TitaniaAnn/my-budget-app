// Settings screen — profile, household, appearance, and account actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
                      ? () => _editHouseholdName(
                          context, ref, info.householdName)
                      : null,
                ),
                const Divider(),
                ...info.members.map((m) => ListTile(
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
                    )),
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
                  subtitle: const Text('Enter an invite code to join a household'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _joinWithCode(context, ref),
                ),
              ],
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _ThemeTile(current: themeMode),

          // ── Account ────────────────────────────────────────────────────
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () => _changePassword(context, ref, user?.email ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: context.cs.error),
            title: Text('Sign Out',
                style: TextStyle(color: context.cs.error)),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: context.cs.error),
            title: Text('Delete Account',
                style: TextStyle(color: context.cs.error)),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'MyBudget · v1.0.0',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Action helpers ─────────────────────────────────────────────────────────

  Future<void> _editDisplayName(
      BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(settingsRepositoryProvider).updateDisplayName(result);
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editHouseholdName(
      BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final householdId =
          await ref.read(householdIdProvider.future);
      if (householdId != null) {
        await ref
            .read(settingsRepositoryProvider)
            .updateHouseholdName(householdId, result);
        ref.invalidate(householdInfoProvider);
      }
    }
  }

  Future<void> _changePassword(
      BuildContext context, WidgetRef ref, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset link to $email?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirmed == true) {
      await supabase.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    }
  }

  Future<void> _inviteMember(
      BuildContext context, WidgetRef ref, String householdId) async {
    final emailCtrl = TextEditingController();
    String selectedRole = 'partner';

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
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Generate Code')),
          ],
        ),
      ),
    );

    if (confirmed != true || emailCtrl.text.trim().isEmpty) return;

    try {
      final code = await ref.read(settingsRepositoryProvider).createInvite(
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
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogCtx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expires in 7 days',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(dialogCtx).colorScheme.outline),
                ),
              ],
            ),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Done')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invite: $e')),
        );
      }
    }
  }

  Future<void> _joinWithCode(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();

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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Join')),
        ],
      ),
    );

    if (confirmed != true || codeCtrl.text.trim().isEmpty) return;

    final error = await ref
        .read(settingsRepositoryProvider)
        .acceptInvite(codeCtrl.text.trim());

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ref.invalidate(householdInfoProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to your new household!')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and all household data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogCtx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Supabase doesn't expose a delete-user endpoint from the client SDK —
      // sign out and show guidance to contact support.
      await supabase.auth.signOut();
      if (context.mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Signed out. Contact support to fully delete your account.'),
            duration: Duration(seconds: 6),
          ),
        );
      }
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
        leading: Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.error),
        title: Text(message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 13)),
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
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      title: Text(displayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
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
              icon: Icon(Icons.brightness_auto, size: 18)),
          ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode, size: 18)),
          ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode, size: 18)),
        ],
        selected: {current},
        onSelectionChanged: (s) =>
            ref.read(themeModeNotifierProvider.notifier).setMode(s.first),
        style: const ButtonStyle(
            visualDensity: VisualDensity.compact),
      ),
    );
  }

  IconData _icon(ThemeMode m) => switch (m) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      };
}

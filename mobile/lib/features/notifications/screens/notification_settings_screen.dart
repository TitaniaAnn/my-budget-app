// Notification preferences — pushed from Settings → Notifications.
//
// The master toggle drives the OS permission flow: flipping it ON
// requests permission, and if the OS denies, the toggle bounces
// back OFF with a snackbar telling the user where to enable it.
// Sub-toggles and the threshold are plain state writes — they only
// take effect when the master is on, but persist either way.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../providers/notification_settings_provider.dart';
import '../repositories/notification_log_repository.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsNotifierProvider);
    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text(
              'Master switch. Sub-toggles below still persist when off.',
            ),
            value: settings.enabled,
            onChanged: (value) async {
              if (value) {
                final granted = await NotificationService.instance
                    .requestPermission();
                if (!context.mounted) return;
                if (!granted) {
                  // Bounce the toggle back; the user needs to enable
                  // it in OS settings before flipping this on.
                  context.showSnackBar(
                    'Notification permission denied — enable it in '
                    'system settings to use alerts.',
                  );
                  return;
                }
              }
              await notifier.setEnabled(value);
            },
          ),
          const Divider(),

          // Per-trigger toggles. Greyed out (but still tappable) when
          // the master is off — flipping the master back on resumes
          // each trigger's last-set state without needing to re-toggle.
          _SectionHeader('Triggers'),
          SwitchListTile(
            title: const Text('Over-budget alerts'),
            subtitle: const Text(
              'Notify when a category exceeds its cap for the period',
            ),
            value: settings.budgetOverEnabled,
            onChanged: notifier.setBudgetOverEnabled,
          ),
          SwitchListTile(
            title: const Text('Large transactions'),
            subtitle: Text(
              'Notify on incoming or outgoing transactions over '
              '${formatCurrency(settings.largeTxThresholdCents)}',
            ),
            value: settings.largeTxEnabled,
            onChanged: notifier.setLargeTxEnabled,
          ),
          if (settings.largeTxEnabled)
            ListTile(
              title: const Text('Large-transaction threshold'),
              subtitle: Text(
                'Currently ${formatCurrency(settings.largeTxThresholdCents)}',
                style: TextStyle(color: context.appColors.textSubtle),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editThreshold(context, ref),
            ),

          const Divider(),
          _SectionHeader('Maintenance'),
          ListTile(
            title: const Text('Reset notification history'),
            subtitle: Text(
              'Clear the dedup log so previously-fired alerts can '
              'fire again. Useful after testing or a mistaken silence.',
              style: TextStyle(color: context.appColors.textSubtle),
            ),
            trailing: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () => _resetHistory(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _resetHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Reset notification history?',
      message:
          'Previously-fired alerts will be able to fire again. '
          'This affects every device in the household.',
      confirmLabel: 'Reset',
    );
    if (!confirmed) return;

    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) return;

    // Clear server-side ledger first; if it fails, we don't want to
    // half-reset by wiping just the local map.
    await ref
        .read(notificationLogRepositoryProvider)
        .clearAll(householdId: householdId);
    await clearLastFired();

    if (!context.mounted) return;
    context.showSnackBar('Notification history cleared.');
  }

  Future<void> _editThreshold(BuildContext context, WidgetRef ref) async {
    final current = ref
        .read(notificationSettingsNotifierProvider)
        .largeTxThresholdCents;
    final controller = TextEditingController(text: (current / 100).toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Large-transaction threshold'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(prefixText: r'$'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final cents = parseToCents(controller.text);
              if (cents <= 0) {
                Navigator.of(ctx).pop();
                return;
              }
              Navigator.of(ctx).pop(cents);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(notificationSettingsNotifierProvider.notifier)
          .setLargeTxThresholdCents(result);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

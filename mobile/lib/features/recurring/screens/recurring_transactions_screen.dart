// Management surface for recurring transaction rules — pushed from
// Settings → Automation → Recurring Transactions.
//
// Lists every rule in the household soonest-due first. Tapping a
// row opens the AddRecurringSheet in edit mode; the FAB opens it
// in create mode. Per-row affordances (pause / resume / delete)
// live inside the edit sheet to keep this surface scannable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/recurring_transaction.dart';
import '../providers/recurring_transactions_provider.dart';
import '../widgets/add_recurring_sheet.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAppSheet<void>(
          context,
          child: const AddRecurringSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(recurringTransactionsProvider),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return const EmptyView(
              icon: Icons.repeat,
              title: 'No recurring rules yet',
              subtitle:
                  'Tap + to add one. Recurring rules automatically '
                  'create transactions on a cadence — Spotify \$9.99 '
                  'monthly, paycheck biweekly, etc.',
            );
          }
          // Accounts lookup so each tile can show "Checking" instead of a
          // raw UUID. Tolerant of a still-loading or errored fetch —
          // tiles fall back to "—" rather than blocking the whole list.
          final accountNames = {
            for (final a in accountsAsync.valueOrNull ?? const [])
              a.id: a.name,
          };
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = rules[i];
              return _RecurringTile(
                rule: r,
                accountName: accountNames[r.accountId] ?? '—',
                onTap: () => showAppSheet<void>(
                  context,
                  child: AddRecurringSheet(rule: r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.rule,
    required this.accountName,
    required this.onTap,
  });

  final RecurringTransaction rule;
  final String accountName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isExpense = rule.amountCents < 0;
    final isPaused = !rule.isActive ||
        (rule.skippedUntilDate != null &&
            !rule.skippedUntilDate!.isBefore(DateTime.now()));

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Expanded(
            child: Text(
              rule.description,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                // Subtle visual cue for inactive / currently-paused
                // rules so the user can spot at a glance which won't
                // fire soon.
                color: isPaused ? colors.textSubtle : null,
                decoration: rule.isActive ? null : TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '-' : '+'}'
            '${formatCurrency(rule.amountCents.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isExpense ? colors.expense : colors.income,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          [
            rule.cadence.displayName,
            accountName,
            'next ${DateFormat.yMMMd().format(rule.nextOccurrenceDate)}',
            if (rule.skippedUntilDate != null)
              'paused until ${DateFormat.yMMMd().format(rule.skippedUntilDate!)}',
            if (!rule.isActive) 'inactive',
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: colors.textSubtle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

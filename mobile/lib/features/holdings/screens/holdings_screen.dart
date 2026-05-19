// Per-account holdings list. Pushed from the account detail screen
// for any investment-group account. Renders one card per position
// with symbol, quantity, current value, and gain/loss vs cost basis
// when known. Tap to edit, FAB to add.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/holdings_provider.dart';
import '../widgets/add_holding_sheet.dart';
import '../widgets/holding_card.dart';

class HoldingsScreen extends ConsumerWidget {
  final String accountId;
  final String accountName;

  const HoldingsScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(holdingsForAccountProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: Text('$accountName — Holdings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAppSheet<void>(
          context,
          child: AddHoldingSheet(accountId: accountId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Holding'),
      ),
      body: holdingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(holdingsForAccountProvider(accountId)),
        ),
        data: (holdings) {
          if (holdings.isEmpty) {
            return const EmptyView(
              icon: Icons.trending_up_outlined,
              title: 'No holdings yet',
              subtitle:
                  'Tap + to add a position. Holdings stack with the '
                  'account balance — they\'re a detail view, not a '
                  'replacement.',
            );
          }
          // Summary header: total current value across all positions.
          // The account's own current_balance is the canonical net
          // worth contribution; this footer is a cross-check so the
          // user can see how much of the account is accounted for in
          // holdings vs cash/other.
          final totalValue = holdings.fold<int>(
            0,
            (sum, h) => sum + h.currentValue,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _SummaryHeader(totalCents: totalValue, count: holdings.length),
              const SizedBox(height: 12),
              for (final h in holdings) ...[
                HoldingCard(holding: h),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  final int totalCents;
  final int count;

  const _SummaryHeader({required this.totalCents, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total market value',
                  style: TextStyle(fontSize: 12, color: colors.textSubtle),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(totalCents),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count ${count == 1 ? 'position' : 'positions'}',
            style: TextStyle(fontSize: 12, color: colors.textSubtle),
          ),
        ],
      ),
    );
  }
}

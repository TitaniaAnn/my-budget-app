// Cross-account holdings list filtered to a single [AssetClass].
// Pushed from the dashboard's Asset Allocation donut when the user
// taps a slice or a legend row — "I see Bonds is 18%, show me what
// that's actually made of."
//
// Reuses the canonical [HoldingCard] so tapping a row drops into
// the same edit sheet the per-account screen uses. The screen
// itself owns no edit affordance of its own: holdings are created
// scoped to an account, and the account detail is the right place
// to add them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/holding.dart';
import '../providers/holdings_provider.dart';
import '../widgets/holding_card.dart';

class HoldingsByClassScreen extends ConsumerWidget {
  const HoldingsByClassScreen({super.key, required this.assetClass});

  final AssetClass assetClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(householdHoldingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(assetClass.displayName)),
      body: holdingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(householdHoldingsProvider),
        ),
        data: (allHoldings) {
          // Filter by class. Note: holdings with no assetClass match
          // [AssetClass.other] in the dashboard rollup (see
          // assetAllocationProvider), so the same treatment here keeps
          // the drill-down's contents in sync with the donut slice
          // that referenced this class.
          final holdings =
              allHoldings
                  .where(
                    (h) => (h.assetClass ?? AssetClass.other) == assetClass,
                  )
                  .toList()
                // Largest position first — same convention as the
                // donut's "largest slice on top" ordering.
                ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

          if (holdings.isEmpty) {
            return EmptyView(
              icon: Icons.trending_up_outlined,
              title: 'No ${assetClass.displayName} holdings',
              subtitle:
                  'Open an investment account from the Accounts tab to '
                  'add a position here.',
            );
          }
          final total = holdings.fold<int>(0, (s, h) => s + h.currentValue);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _ClassHeader(
                assetClass: assetClass,
                totalCents: total,
                count: holdings.length,
              ),
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

class _ClassHeader extends StatelessWidget {
  const _ClassHeader({
    required this.assetClass,
    required this.totalCents,
    required this.count,
  });

  final AssetClass assetClass;
  final int totalCents;
  final int count;

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
          // Solid color block — matches the same hex the donut slice
          // and the per-holding card chip use, so the user's eye
          // tracks from "tapped this color" to "now I'm here".
          Container(
            width: 14,
            height: 38,
            decoration: BoxDecoration(
              color: assetClass.sliceColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total in ${assetClass.displayName}',
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

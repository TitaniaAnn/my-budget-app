// Reusable holding card. Used by the per-account [HoldingsScreen]
// and the cross-account [HoldingsByClassScreen] surfaces. Tapping
// opens [AddHoldingSheet] in edit mode — `accountId` comes from
// the holding itself so the widget can be dropped anywhere without
// the call site having to thread it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../models/holding.dart';
import 'add_holding_sheet.dart';

class HoldingCard extends ConsumerWidget {
  final Holding holding;

  const HoldingCard({super.key, required this.holding});

  static final _qtyFmt = NumberFormat.decimalPattern();

  /// Days after which a value is considered stale enough to flag.
  /// 30 days is a tradeoff: short enough that a quarterly statement
  /// doesn't sit unmarked, long enough that volatile securities
  /// don't drown the user in stale chips between updates.
  static const int _staleAfterDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final cs = context.cs;

    // Gain/loss vs cost basis when both are present. The number
    // shown is signed dollars; the sign drives the color and arrow.
    final basis = holding.costBasis;
    final hasGainLoss = basis != null && basis > 0;
    final gainLoss = hasGainLoss ? holding.currentValue - basis : null;
    final gainLossPct = hasGainLoss && basis > 0
        ? (gainLoss! / basis) * 100
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showAppSheet<void>(
        context,
        child: AddHoldingSheet(accountId: holding.accountId, holding: holding),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            // Asset class color chip — quick visual grouping when
            // scanning a long list. Unclassified holdings get a
            // muted dot so they're still distinguishable.
            Container(
              width: 10,
              height: 38,
              decoration: BoxDecoration(
                color: holding.assetClass?.sliceColor ?? colors.textSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.symbol.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (holding.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      holding.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.textSubtle),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${_qtyFmt.format(holding.quantity)} ${holding.quantity == 1 ? 'share' : 'shares'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSubtle,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Stale-price badge: surfaces when the user
                      // hasn't re-marked the value in 30+ days, or
                      // when last_priced_at was never set (backfilled
                      // positions). Tapping the card opens the edit
                      // sheet, where saving a new currentValue
                      // refreshes the timestamp.
                      if (_isStale(holding.lastPricedAt)) ...[
                        const SizedBox(width: 6),
                        _StalePill(lastPricedAt: holding.lastPricedAt),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(holding.currentValue),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (gainLoss != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${gainLoss >= 0 ? '+' : '-'}${formatCurrency(gainLoss.abs())} '
                    '(${gainLossPct!.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: gainLoss >= 0 ? colors.income : colors.expense,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// True when [at] is null (position never priced) or older than the
/// staleness threshold. Top-level so the rule could be unit-tested
/// independently of the card widget when that becomes worth doing.
bool _isStale(DateTime? at) {
  if (at == null) return true;
  return DateTime.now().difference(at).inDays > HoldingCard._staleAfterDays;
}

/// Small amber chip on the holding card when its price is stale.
/// Text adapts to whether the position has ever been priced: "Never
/// priced" reads more accurately than "Stale · — d" for a row the
/// user just typed in without a last_priced_at hint.
class _StalePill extends StatelessWidget {
  const _StalePill({required this.lastPricedAt});

  final DateTime? lastPricedAt;

  @override
  Widget build(BuildContext context) {
    // Warning amber — same family as the loans accent so the chip
    // reads as a soft heads-up rather than an error.
    const accent = Color(0xFFF59E0B);
    final label = lastPricedAt == null
        ? 'Never priced'
        : 'Stale · ${DateTime.now().difference(lastPricedAt!).inDays}d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

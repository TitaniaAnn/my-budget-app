// Dashboard banner that surfaces when one or more linked
// Plaid Items returned `requires_reauth: true` on the most
// recent sync. Tap → re-launch Plaid Link in update mode for
// that Item.
//
// Phase 4 wires `createUpdateLinkToken` end-to-end. For Phase 3
// the tap surfaces a friendly "ask the household owner to
// reconnect" message — the surface exists so the user knows
// why their sync stopped, even before the update-mode flow
// ships.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plaid_item.dart';
import '../providers/plaid_providers.dart';

class PlaidReauthBanner extends ConsumerWidget {
  const PlaidReauthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(plaidItemsProvider);
    final reauth = itemsAsync.maybeWhen(
      data: (items) => items.where((i) => i.requiresReauth).toList(),
      orElse: () => const <PlaidItem>[],
    );
    if (reauth.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reauth.length == 1
                      ? 'Reconnect ${reauth.first.institutionName ?? "your bank"}'
                      : 'Reconnect ${reauth.length} banks',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sync paused — open the bank settings page to '
                  'reconnect. (Update-mode Link ships in Phase 4.)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

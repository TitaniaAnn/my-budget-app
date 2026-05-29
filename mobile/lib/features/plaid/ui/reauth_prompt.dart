// Dashboard banner that surfaces when one or more linked
// Plaid Items returned `requires_reauth: true` on the most
// recent sync. Tap launches Plaid Link in update mode for the
// first re-auth-needing Item (a multi-item household with
// multiple stale Items resolves them one at a time).
//
// Phase 4 wires this end-to-end: the launcher's
// `updateModeForItemId` mints an access-token-bound link
// token, no public_token exchange is needed on success, and
// the post-launch step re-syncs the Item to clear
// `last_sync_error` if the reconnection succeeded.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ledger_invalidation.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../models/plaid_item.dart';
import '../providers/plaid_providers.dart';
import '../repositories/plaid_repository.dart';
import '../services/plaid_link_launcher.dart';

class PlaidReauthBanner extends ConsumerStatefulWidget {
  const PlaidReauthBanner({super.key});

  @override
  ConsumerState<PlaidReauthBanner> createState() => _PlaidReauthBannerState();
}

class _PlaidReauthBannerState extends ConsumerState<PlaidReauthBanner> {
  bool _busy = false;

  Future<void> _reconnect(PlaidItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final launcher = PlaidLinkLauncher(
        repository: ref.read(plaidRepositoryProvider),
      );
      final outcome = await launcher.launch(updateModeForItemId: item.id);
      if (outcome is PlaidLinkSuccessOutcome) {
        // Update mode reuses the existing access_token — no
        // exchange roundtrip needed. Re-sync to clear the
        // `last_sync_error` flag if Plaid is happy again.
        await ref
            .read(plaidSyncOrchestratorProvider)
            .syncOne(item.id);
        ref.invalidate(plaidItemsProvider);
        invalidateLedger(ref);
        if (mounted) {
          context.showSnackBar(
            'Reconnected ${item.institutionName ?? "your bank"}.',
          );
        }
      } else if (outcome is PlaidLinkExitOutcome && !outcome.isUserCancellation) {
        if (mounted) {
          context.showErrorSnackBar(
            'Reconnect failed (${outcome.errorCode ?? "unknown"}).',
          );
        }
      }
      // User-cancelled exit → silent. Banner stays.
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(plaidItemsProvider);
    final reauth = itemsAsync.maybeWhen(
      data: (items) => items.where((i) => i.requiresReauth).toList(),
      orElse: () => const <PlaidItem>[],
    );
    if (reauth.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final first = reauth.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _busy ? null : () => _reconnect(first),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                          ? 'Reconnect ${first.institutionName ?? "your bank"}'
                          : 'Reconnect ${reauth.length} banks',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _busy
                          ? 'Opening Plaid…'
                          : 'Sync paused — tap to reconnect.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: cs.error),
            ],
          ),
        ),
      ),
    );
  }
}

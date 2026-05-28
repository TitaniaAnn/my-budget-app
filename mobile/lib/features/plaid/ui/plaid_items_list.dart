// "Linked Banks" list — one tile per active plaid_items row.
// Tappable surface for re-auth + status reporting. Empty state
// CTAs into the ConnectBankScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/state_views.dart';
import '../models/plaid_item.dart';
import '../providers/plaid_providers.dart';
import 'connect_bank_screen.dart';

class PlaidItemsScreen extends ConsumerWidget {
  const PlaidItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(plaidItemsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Banks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(plaidItemsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ConnectBankScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Connect bank'),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(plaidItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.account_balance_outlined,
              title: 'No banks linked yet',
              subtitle: 'Tap "Connect bank" to add your first one.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _PlaidItemTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _PlaidItemTile extends StatelessWidget {
  const _PlaidItemTile({required this.item});

  final PlaidItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reauth = item.requiresReauth;
    final hasError = item.lastSyncError != null;
    final lastSync = item.lastSyncAt;
    final subtitle = hasError
        ? (reauth
              ? 'Re-authentication required'
              : 'Last sync error: ${item.lastSyncError}')
        : lastSync == null
        ? 'Initial sync pending'
        : 'Last synced ${DateFormat.yMMMd().add_jm().format(lastSync.toLocal())}';

    return ListTile(
      leading: Icon(
        reauth ? Icons.error_outline : Icons.account_balance_outlined,
        color: reauth ? cs.error : cs.primary,
      ),
      title: Text(item.institutionName ?? 'Unknown institution'),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: hasError ? cs.error : cs.outline),
      ),
      trailing: Text(
        item.environment.displayLabel,
        style: TextStyle(fontSize: 11, color: cs.outline),
      ),
    );
  }
}

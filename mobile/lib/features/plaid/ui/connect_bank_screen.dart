// Connect-Bank screen — opens Plaid Link, exchanges the
// public_token, kicks off an initial sync, surfaces the
// post-Link summary (or any unmapped accounts the user might
// want to take action on).
//
// Entry point: settings ("Connect bank") and the empty-state
// CTA on the Plaid Items list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ledger_invalidation.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../providers/plaid_providers.dart';
import '../repositories/plaid_repository.dart';
import '../services/plaid_link_launcher.dart';

class ConnectBankScreen extends ConsumerStatefulWidget {
  const ConnectBankScreen({super.key});

  @override
  ConsumerState<ConnectBankScreen> createState() => _ConnectBankScreenState();
}

class _ConnectBankScreenState extends ConsumerState<ConnectBankScreen> {
  bool _busy = false;
  String? _status;
  Object? _error;

  Future<void> _launch() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Opening Plaid…';
      _error = null;
    });
    try {
      final launcher = PlaidLinkLauncher(
        repository: ref.read(plaidRepositoryProvider),
      );
      final outcome = await launcher.launch();
      switch (outcome) {
        case PlaidLinkExitOutcome(:final isUserCancellation):
          setState(() {
            _busy = false;
            _status = isUserCancellation
                ? 'Cancelled — no bank linked.'
                : 'Link failed (${outcome.errorCode ?? "unknown"}).';
          });
        case PlaidLinkSuccessOutcome(:final publicToken, :final metadata):
          if (metadata.institution == null) {
            setState(() {
              _busy = false;
              _status = 'Link returned no institution; nothing to import.';
            });
            return;
          }
          setState(() => _status = 'Exchanging token…');
          final result = await ref
              .read(plaidRepositoryProvider)
              .exchangePublicToken(
                publicToken: publicToken,
                institution: metadata.institution!,
                accounts: metadata.accounts,
              );

          setState(() => _status = 'Pulling first batch of transactions…');
          await ref
              .read(plaidSyncOrchestratorProvider)
              .syncOne(result.plaidItemId);

          // Items list + ledger surfaces are stale now.
          ref.invalidate(plaidItemsProvider);
          invalidateLedger(ref);

          setState(() {
            _busy = false;
            _status =
                'Linked ${result.insertedAccounts.length} account'
                "${result.insertedAccounts.length == 1 ? "" : "s"} "
                'from ${metadata.institution!.name}.';
          });
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e;
        _status = null;
      });
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Bank')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_balance_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Link a bank account',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'MyBudget connects to your bank through Plaid. Your bank '
              'credentials are entered into the Plaid Link UI and never '
              'reach this app.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _busy ? null : _launch,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(_busy ? 'Working…' : 'Open Plaid Link'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 24),
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error == null
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

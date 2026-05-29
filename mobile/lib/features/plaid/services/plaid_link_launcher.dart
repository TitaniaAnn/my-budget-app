// Wraps the plaid_flutter SDK so the connect-bank screen
// doesn't have to know about Plaid's stream-based onSuccess /
// onExit / onEvent callbacks. Single-shot: each launch goes
// through createLinkToken → PlaidLink.create → open, then
// resolves on the first onSuccess / onExit / error.
//
// Keeps the plaid_flutter SDK off the rest of the codebase's
// import surface — only this file imports `plaid_flutter`. If
// the SDK ever needs to be swapped (Plaid Link v6 or a fork),
// only this launcher changes.

import 'dart:async';

import 'package:plaid_flutter/plaid_flutter.dart';

import '../repositories/plaid_repository.dart';

/// Outcome of a single Link launch. The connect-bank UI
/// branches on `kind`; success carries the exchange result,
/// exit carries an optional error code for telemetry.
sealed class PlaidLinkOutcome {
  const PlaidLinkOutcome();
}

class PlaidLinkSuccessOutcome extends PlaidLinkOutcome {
  const PlaidLinkSuccessOutcome({
    required this.publicToken,
    required this.metadata,
  });
  final String publicToken;
  final LinkSuccessMetadata metadata;
}

class PlaidLinkExitOutcome extends PlaidLinkOutcome {
  const PlaidLinkExitOutcome({this.errorCode, this.errorMessage});

  /// Plaid error code, e.g. `INVALID_LINK_TOKEN` (rare in
  /// practice — most exits are the user cancelling, which
  /// surface with both fields null).
  final String? errorCode;
  final String? errorMessage;

  bool get isUserCancellation => errorCode == null;
}

class PlaidLinkLauncher {
  PlaidLinkLauncher({required this.repository});

  final PlaidRepository repository;

  /// Mints a token via the Edge Function, hands it to the
  /// platform Link UI, and resolves with the first
  /// success/exit event. Subscription is cancelled before the
  /// return so a subsequent launch starts clean.
  ///
  /// When [updateModeForItemId] is non-null, the launch runs
  /// Link in update mode against that existing Item — used by
  /// the ReauthBanner. No public_token exchange is needed on
  /// success in this mode; the caller should re-trigger sync
  /// instead.
  Future<PlaidLinkOutcome> launch({String? updateModeForItemId}) async {
    final linkToken = updateModeForItemId == null
        ? await repository.createLinkToken()
        : await repository.createUpdateLinkToken(updateModeForItemId);
    await PlaidLink.create(
      configuration: LinkTokenConfiguration(token: linkToken),
    );

    final completer = Completer<PlaidLinkOutcome>();
    StreamSubscription<LinkSuccess>? successSub;
    StreamSubscription<LinkExit>? exitSub;

    void finish(PlaidLinkOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
      // ignore: discarded_futures
      successSub?.cancel();
      // ignore: discarded_futures
      exitSub?.cancel();
    }

    successSub = PlaidLink.onSuccess.listen((event) {
      finish(
        PlaidLinkSuccessOutcome(
          publicToken: event.publicToken,
          metadata: event.metadata,
        ),
      );
    });
    exitSub = PlaidLink.onExit.listen((event) {
      finish(
        PlaidLinkExitOutcome(
          errorCode: event.error?.code,
          errorMessage: event.error?.message,
        ),
      );
    });

    try {
      await PlaidLink.open();
    } catch (e) {
      finish(
        PlaidLinkExitOutcome(
          errorCode: 'OPEN_FAILED',
          errorMessage: e.toString(),
        ),
      );
    }

    return completer.future;
  }
}

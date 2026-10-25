// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches all active accounts for the current household.
///
/// Invalidating this provider (e.g. after creating or deleting an account)
/// triggers a fresh fetch from Supabase automatically.

@ProviderFor(accounts)
final accountsProvider = AccountsProvider._();

/// Fetches all active accounts for the current household.
///
/// Invalidating this provider (e.g. after creating or deleting an account)
/// triggers a fresh fetch from Supabase automatically.

final class AccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          FutureOr<List<Account>>
        >
    with $FutureModifier<List<Account>>, $FutureProvider<List<Account>> {
  /// Fetches all active accounts for the current household.
  ///
  /// Invalidating this provider (e.g. after creating or deleting an account)
  /// triggers a fresh fetch from Supabase automatically.
  AccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsHash();

  @$internal
  @override
  $FutureProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Account>> create(Ref ref) {
    return accounts(ref);
  }
}

String _$accountsHash() => r'f35a2c435a44d65eb724450c9b136c4179e050e3';

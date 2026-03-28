import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/credit_card_rate.dart';
import '../repositories/credit_card_rates_repository.dart';

part 'credit_card_rates_provider.g.dart';

@riverpod
Future<List<CreditCardRate>> creditCardRates(
    CreditCardRatesRef ref, String accountId) async {
  return ref
      .watch(creditCardRatesRepositoryProvider)
      .fetchRates(accountId);
}

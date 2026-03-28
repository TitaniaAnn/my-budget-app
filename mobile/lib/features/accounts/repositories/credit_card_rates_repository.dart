import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/credit_card_rate.dart';

part 'credit_card_rates_repository.g.dart';

@riverpod
CreditCardRatesRepository creditCardRatesRepository(
    CreditCardRatesRepositoryRef ref) {
  return CreditCardRatesRepository();
}

class CreditCardRatesRepository {
  Future<List<CreditCardRate>> fetchRates(String accountId) async {
    final data = await supabase
        .from('credit_card_rates')
        .select()
        .eq('account_id', accountId)
        .order('is_intro', ascending: false)
        .order('created_at');
    return data.map<CreditCardRate>(CreditCardRate.fromJson).toList();
  }

  Future<CreditCardRate> createRate({
    required String accountId,
    required CreditRateType rateType,
    required double rate,
    required bool isIntro,
    DateTime? introEndsOn,
    String? label,
  }) async {
    final data = await supabase
        .from('credit_card_rates')
        .insert({
          'account_id': accountId,
          'rate_type': rateType.name,
          'rate': rate,
          'is_intro': isIntro,
          'intro_ends_on': introEndsOn?.toIso8601String().substring(0, 10),
          'label': label,
        })
        .select()
        .single();
    return CreditCardRate.fromJson(data);
  }

  Future<CreditCardRate> updateRate({
    required String rateId,
    required double rate,
    required bool isIntro,
    DateTime? introEndsOn,
    String? label,
    required bool isActive,
  }) async {
    final data = await supabase
        .from('credit_card_rates')
        .update({
          'rate': rate,
          'is_intro': isIntro,
          'intro_ends_on': introEndsOn?.toIso8601String().substring(0, 10),
          'label': label,
          'is_active': isActive,
        })
        .eq('id', rateId)
        .select()
        .single();
    return CreditCardRate.fromJson(data);
  }

  Future<void> deleteRate(String rateId) async {
    await supabase.from('credit_card_rates').delete().eq('id', rateId);
  }

  /// Tags a transaction with a specific rate.
  Future<void> assignRateToTransaction({
    required String transactionId,
    required String? rateId,
  }) async {
    await supabase
        .from('transactions')
        .update({'rate_id': rateId}).eq('id', transactionId);
  }
}

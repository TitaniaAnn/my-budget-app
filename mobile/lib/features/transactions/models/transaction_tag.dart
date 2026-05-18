// Transaction tag model — mirrors the `transaction_tags` table (migration 020).
//
// Tags answer "what context does this expense belong to?" — a second
// dimension beyond category. A single transaction can carry many tags
// (e.g. a Costco run might be both `contractor` and `pottery_studio`),
// which is why they live in a separate dictionary + assignment table
// rather than as another column on transactions.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_tag.freezed.dart';
part 'transaction_tag.g.dart';

/// Immutable representation of a row in the `transaction_tags` table.
///
/// All tags are household-scoped — there are no system-wide tags. The
/// schema enforces `UNIQUE (household_id, name)` so the picker can
/// safely use `name` as a display key without disambiguation.
@freezed
class TransactionTag with _$TransactionTag {
  const factory TransactionTag({
    required String id,
    required String householdId,
    required String name,

    /// Optional hex color (e.g. "#22C55E") for the chip background.
    /// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
    String? color,
    required DateTime createdAt,
  }) = _TransactionTag;

  factory TransactionTag.fromJson(Map<String, dynamic> json) =>
      _$TransactionTagFromJson(json);
}

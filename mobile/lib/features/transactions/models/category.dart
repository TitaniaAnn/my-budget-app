// Category model.
// Categories can be system-wide (household_id IS NULL) or household-specific.
// They support one level of nesting via parent_id for sub-categories.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Immutable representation of a row in the `categories` table.
///
/// System categories have [householdId] == null and are seeded by
/// 002_seed_categories.sql. Households can create custom categories
/// that reference a [parentId] for grouping.
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    /// Null for system-default categories visible to all households.
    String? householdId,
    required String name,
    /// Parent category id for sub-categories (one level of nesting only).
    String? parentId,
    /// Emoji or icon identifier shown in the UI.
    String? icon,
    /// Hex color string (e.g. "#22C55E") for the category badge.
    String? color,
    /// True for income categories (e.g. Salary, Interest).
    required bool isIncome,
    required int sortOrder,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

// Filter bar widgets used by TransactionsScreen.
//
// Extracted from transactions_screen.dart so the screen file stays
// focused on layout + state and these reusable bits live next to
// the other transaction widgets. The screen still owns the filter
// STATE (which account / category / tag / date is selected); these
// widgets are pure presentation + callback.
//
// `_FilterDropdown` is the shared pill-with-popup-menu underneath
// AccountFilterBar and CategoryFilterBar. The Tag and Date variants
// don't share it because tags want a horizontal-scroll chip row
// (households can have many) and dates want ChoiceChips (the small
// fixed set of presets).

import 'package:flutter/material.dart';

import '../../accounts/models/account.dart';
import '../models/category.dart';
import '../models/transaction_tag.dart';

/// User-facing preset date ranges in the transactions filter bar.
/// Each variant carries its own range() resolver so the screen can
/// translate a selection into (from, to) without a switch.
enum DateFilter {
  all('All time'),
  thisMonth('This month'),
  lastMonth('Last month'),
  last90('Last 90 days'),
  thisYear('This year');

  const DateFilter(this.label);
  final String label;

  (DateTime? from, DateTime? to) get range {
    final now = DateTime.now();
    return switch (this) {
      DateFilter.all => (null, null),
      DateFilter.thisMonth => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0),
      ),
      DateFilter.lastMonth => (
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0),
      ),
      DateFilter.last90 => (
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 89)),
        DateTime(now.year, now.month, now.day),
      ),
      DateFilter.thisYear => (
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31),
      ),
    };
  }
}

/// Shared pill-with-popup-menu used by [AccountFilterBar] and
/// [CategoryFilterBar]. Renders a primary-coloured pill when a
/// filter is active and a surface-coloured pill otherwise; tapping
/// opens a menu of "All <label>" + every item.
class _FilterDropdown extends StatelessWidget {
  final String allLabel;
  final List<({String id, String name})> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final IconData icon;

  const _FilterDropdown({
    required this.allLabel,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = selectedId == null
        ? null
        : items.firstWhere(
            (i) => i.id == selectedId,
            // If the saved selection no longer matches anything
            // (account/category deleted), behave as if All is
            // selected.
            orElse: () => (id: '', name: allLabel),
          );
    final showActive = selected != null && selected.id.isNotEmpty;
    return PopupMenuButton<String?>(
      tooltip: allLabel,
      initialValue: selectedId,
      onSelected: onSelected,
      itemBuilder: (_) => <PopupMenuEntry<String?>>[
        PopupMenuItem<String?>(value: null, child: Text(allLabel)),
        const PopupMenuDivider(),
        for (final i in items)
          PopupMenuItem<String?>(value: i.id, child: Text(i.name)),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: showActive ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: showActive ? cs.primary : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: showActive
                  ? Colors.white
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                selected?.name ?? allLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: showActive
                      ? Colors.white
                      : cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: showActive
                  ? Colors.white
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountFilterBar extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const AccountFilterBar({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _FilterDropdown(
          allLabel: 'All accounts',
          items: [for (final a in accounts) (id: a.id, name: a.name)],
          selectedId: selectedId,
          onSelected: onSelected,
          icon: Icons.account_balance_outlined,
        ),
      ),
    );
  }
}

class CategoryFilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _FilterDropdown(
          allLabel: 'All categories',
          items: [for (final c in categories) (id: c.id, name: c.name)],
          selectedId: selectedId,
          onSelected: onSelected,
          icon: Icons.label_outline,
        ),
      ),
    );
  }
}

/// Horizontal chip row of every tag in the household. Same pill
/// style as [CategoryFilterBar] for visual consistency. Selecting
/// a tag narrows the transactions list to rows carrying that tag;
/// the "All tags" pill clears the filter. Tag chips are prefixed
/// with `#` so they can't be confused with category chips on a
/// glance.
class TagFilterBar extends StatelessWidget {
  final List<TransactionTag> tags;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All tags'),
          ...tags.map((t) => _chip(context, t.id, '#${t.name}')),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String? id, String label) {
    final selected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DateFilterBar extends StatelessWidget {
  final DateFilter selected;
  final ValueChanged<DateFilter> onSelected;

  const DateFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: DateFilter.values
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.label, style: const TextStyle(fontSize: 12)),
                  selected: selected == f,
                  onSelected: (_) => onSelected(f),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

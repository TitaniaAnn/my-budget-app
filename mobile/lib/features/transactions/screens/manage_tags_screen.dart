// Tag management surface — pushed from Settings → Categorisations.
//
// Lists every tag in the household with a colored dot, a tap-to-edit
// action that opens [_EditTagDialog], and a FAB for "New Tag". The
// picker on the transaction edit sheet still has its own quick-add
// affordance for tags created in-context; this screen exists for
// renaming, recoloring, and cleaning up.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/transaction_tag.dart';
import '../providers/transaction_tags_provider.dart';
import '../repositories/transaction_tags_repository.dart';
import '../services/tag_name_validator.dart';

class ManageTagsScreen extends ConsumerWidget {
  const ManageTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(transactionTagsProvider);
    final usageAsync = ref.watch(tagUsageCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, ref, tag: null),
        icon: const Icon(Icons.add),
        label: const Text('New Tag'),
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(transactionTagsProvider),
        ),
        data: (tags) {
          if (tags.isEmpty) {
            return const EmptyView(
              icon: Icons.label_outline,
              title: 'No tags yet',
              subtitle:
                  'Tap + to add one. Tags can be assigned to transactions '
                  'and line items as a second dimension alongside categories.',
            );
          }
          // Usage is supplementary — if the count fetch is still in
          // flight or errored, render rows without subtitles rather
          // than blocking the whole list.
          final usage =
              usageAsync.valueOrNull ??
              const <String, ({int txCount, int lineItemCount})>{};
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: tags.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _TagTile(
              tag: tags[i],
              usage: usage[tags[i].id],
              onTap: () => _showEditDialog(context, ref, tag: tags[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required TransactionTag? tag,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditTagDialog(tag: tag),
    );
  }
}

// ---------------------------------------------------------------------------

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag, required this.usage, required this.onTap});

  final TransactionTag tag;

  /// Per-tag assignment counts. Null when the bulk fetch hasn't
  /// resolved yet (or errored) — the tile still renders the tag,
  /// just without a usage subtitle.
  final ({int txCount, int lineItemCount})? usage;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = tag.color != null
        ? colorFromHex(tag.color)
        : context.appColors.textSubtle;
    return ListTile(
      leading: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      title: Text(tag.name),
      subtitle: _usageSubtitle(),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// "12 transactions · 3 line items" when both counts are non-zero,
  /// trimmed when one is zero, null when both are zero (the tile
  /// renders without a subtitle so the row stays compact).
  Widget? _usageSubtitle() {
    if (usage == null) return null;
    final parts = <String>[];
    final tx = usage!.txCount;
    final li = usage!.lineItemCount;
    if (tx > 0) parts.add('$tx ${tx == 1 ? 'transaction' : 'transactions'}');
    if (li > 0) parts.add('$li ${li == 1 ? 'line item' : 'line items'}');
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}

// ---------------------------------------------------------------------------
// Edit dialog
// ---------------------------------------------------------------------------

/// Curated palette for tag chips. Hand-picked to be distinguishable
/// at small sizes on light and dark themes alike. Adding more swatches
/// here is the right call before introducing a free-form color
/// picker; an arbitrary HSL surface would make every chip identifiable
/// only by its precise label.
const List<({String label, String hex})> _tagPalette = [
  (label: 'Red', hex: '#EF4444'),
  (label: 'Orange', hex: '#F97316'),
  (label: 'Amber', hex: '#F59E0B'),
  (label: 'Green', hex: '#22C55E'),
  (label: 'Teal', hex: '#14B8A6'),
  (label: 'Blue', hex: '#3B82F6'),
  (label: 'Indigo', hex: '#6366F1'),
  (label: 'Purple', hex: '#A855F7'),
  (label: 'Pink', hex: '#EC4899'),
  (label: 'Gray', hex: '#6B7280'),
];

class _EditTagDialog extends ConsumerStatefulWidget {
  const _EditTagDialog({required this.tag});

  /// Null = create flow; non-null = edit existing tag.
  final TransactionTag? tag;

  @override
  ConsumerState<_EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends ConsumerState<_EditTagDialog> {
  final _nameCtrl = TextEditingController();
  String? _selectedColor;
  bool _saving = false;

  bool get _isEdit => widget.tag != null;

  @override
  void initState() {
    super.initState();
    final tag = widget.tag;
    if (tag != null) {
      _nameCtrl.text = tag.name;
      _selectedColor = tag.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(transactionTagsRepositoryProvider);
      if (_isEdit) {
        await repo.updateTag(
          tagId: widget.tag!.id,
          name: name,
          color: _selectedColor,
        );
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        if (householdId == null) return;
        await repo.createTag(
          householdId: householdId,
          name: name,
          color: _selectedColor,
        );
      }
      ref.invalidate(transactionTagsProvider);
      // Usage counts depend on the dictionary's existence too — a
      // newly-created tag should appear with (0, 0) rather than
      // not at all when the manage screen refreshes.
      ref.invalidate(tagUsageCountsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showErrorSnackBar(e);
      }
    }
  }

  Future<void> _delete() async {
    // Concrete numbers in the prompt help the user decide whether
    // this is a "nothing to lose, just clean up" delete or a "this
    // touches actual records" one. Pulled inline rather than via
    // an extra provider watch because the dialog is short-lived.
    final usage = ref.read(tagUsageCountsProvider).valueOrNull?[widget.tag!.id];
    final tx = usage?.txCount ?? 0;
    final li = usage?.lineItemCount ?? 0;
    final String message;
    if (tx == 0 && li == 0) {
      message =
          'This tag isn\'t currently assigned to anything — safe to '
          'remove from the dictionary.';
    } else {
      final parts = <String>[];
      if (tx > 0) parts.add('$tx ${tx == 1 ? 'transaction' : 'transactions'}');
      if (li > 0) parts.add('$li ${li == 1 ? 'line item' : 'line items'}');
      message =
          'This will remove the tag from ${parts.join(' and ')}. The '
          'underlying records are not affected.';
    }

    final confirmed = await confirmDestructive(
      context,
      title: 'Delete Tag?',
      message: message,
    );
    if (!confirmed) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(transactionTagsRepositoryProvider)
          .deleteTag(widget.tag!.id);
      // Assignments cascade-deleted per migration 020's ON DELETE
      // CASCADE. The transactions list and any open editor that
      // displays tag chips needs to re-read; invalidate the bulk
      // assignment provider and the usage counts too.
      ref.invalidate(transactionTagsProvider);
      ref.invalidate(transactionTagAssignmentsProvider);
      ref.invalidate(tagUsageCountsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showErrorSnackBar(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Existing tags drive the collision check. valueOrNull keeps
    // the dialog usable if the dictionary hasn't loaded yet — the
    // first save still hits the DB constraint, so worst case is a
    // brief lag before the inline hint catches up.
    final existing =
        ref.watch(transactionTagsProvider).valueOrNull ??
        const <TransactionTag>[];
    final nameError = validateTagName(
      _nameCtrl.text,
      existing: existing,
      excludeId: widget.tag?.id,
    );
    final canSave =
        !_saving && _nameCtrl.text.trim().isNotEmpty && nameError == null;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Tag' : 'New Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. contractor',
              // Render the validator's message inline. Cleared
              // automatically when the user types something
              // non-colliding, since the next build re-runs the
              // check.
              errorText: nameError,
            ),
            textInputAction: TextInputAction.done,
            // Rebuild on every keystroke so the error text and the
            // Save-button state track the input in real time.
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (canSave) _save();
            },
          ),
          const SizedBox(height: 16),
          Text(
            'COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorSwatch(
                hex: null,
                selected: _selectedColor == null,
                onTap: () => setState(() => _selectedColor = null),
              ),
              for (final c in _tagPalette)
                _ColorSwatch(
                  hex: c.hex,
                  selected:
                      _selectedColor?.toLowerCase() == c.hex.toLowerCase(),
                  onTap: () => setState(() => _selectedColor = c.hex),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (_isEdit)
          TextButton(
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

/// One round swatch in the color row. Null [hex] is the "no color"
/// option, rendered as a hollow circle with a slash so the user
/// can tell at a glance it isn't just a missing color.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String? hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hex != null ? colorFromHex(hex) : null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 3 : 1,
          ),
        ),
        child: hex == null
            ? Center(
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
      ),
    );
  }
}

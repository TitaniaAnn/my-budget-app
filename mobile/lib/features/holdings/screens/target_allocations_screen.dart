// Target asset-class allocations editor — Settings → Investing →
// Target Allocation.
//
// The user enters a percentage per asset class; the screen gates
// the Save button on the sum equaling 100% (with a 1% slack to
// absorb rounding edges). Unsaved targets stay local until the
// user explicitly commits — partial edits would otherwise leak
// onto the rebalance card mid-typing.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/holding.dart';
import '../repositories/target_allocations_repository.dart';

class TargetAllocationsScreen extends ConsumerStatefulWidget {
  const TargetAllocationsScreen({super.key});

  @override
  ConsumerState<TargetAllocationsScreen> createState() =>
      _TargetAllocationsScreenState();
}

class _TargetAllocationsScreenState
    extends ConsumerState<TargetAllocationsScreen> {
  /// Per-class percent as the user has typed it. Indexed by class
  /// so a class the user hasn't entered yet just maps to null.
  /// Storing as int basis points so we don't re-introduce float
  /// drift in the sum check.
  final Map<AssetClass, int> _draft = {};
  late Future<void> _initial;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = _loadInitial();
  }

  Future<void> _loadInitial() async {
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) return;
    final rows = await ref
        .read(targetAllocationsRepositoryProvider)
        .fetchAll(householdId);
    setState(() {
      _draft.clear();
      for (final r in rows) {
        _draft[r.assetClass] = r.targetPctBp;
      }
    });
  }

  int get _sumBp => _draft.values.fold<int>(0, (a, b) => a + b);

  /// 100% ± 1% (100bp) slack. Picking 33/33/33 sums to 99 — the
  /// gate would otherwise reject every "split into thirds" choice.
  bool get _sumIsValid => (_sumBp - 10000).abs() <= 100;

  Future<void> _save() async {
    if (!_sumIsValid) return;
    setState(() => _saving = true);
    final repo = ref.read(targetAllocationsRepositoryProvider);
    try {
      final householdId = await ref.read(householdIdProvider.future);
      final user = ref.read(currentUserProvider);
      if (householdId == null || user == null) {
        throw Exception('Not logged in');
      }
      // Write every non-zero entry, delete every empty one. A
      // future "row count" perf tweak could diff vs server state,
      // but 7 asset classes makes that needless work.
      for (final cls in AssetClass.values) {
        final bp = _draft[cls];
        if (bp == null || bp == 0) {
          await repo.deleteTarget(householdId: householdId, assetClass: cls);
        } else {
          await repo.setTarget(
            householdId: householdId,
            assetClass: cls,
            targetPctBp: bp,
            createdBy: user.id,
          );
        }
      }
      if (mounted) {
        context.showSnackBar('Target allocation saved');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Target Allocation')),
      body: FutureBuilder<void>(
        future: _initial,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorView(
              error: snap.error!,
              onRetry: () => setState(() => _initial = _loadInitial()),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Set the percentage of your portfolio you want held '
                  'in each asset class. The dashboard will surface any '
                  'class that drifts more than 5 percentage points from '
                  'its target.',
                  style: TextStyle(fontSize: 12, color: colors.textSubtle),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final cls in AssetClass.values)
                      _ClassRow(
                        assetClass: cls,
                        valueBp: _draft[cls] ?? 0,
                        onChanged: (bp) => setState(() => _draft[cls] = bp),
                      ),
                  ],
                ),
              ),
              // Live sum + Save button at the bottom so the user
              // always knows whether their numbers add up.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sum: ${(_sumBp / 100).toStringAsFixed(1)}%'
                        '${_sumIsValid ? '' : ' (must be 100%)'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _sumIsValid
                              ? colors.textMuted
                              : colors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _saving || !_sumIsValid ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassRow extends StatefulWidget {
  const _ClassRow({
    required this.assetClass,
    required this.valueBp,
    required this.onChanged,
  });

  final AssetClass assetClass;
  final int valueBp;
  final ValueChanged<int> onChanged;

  @override
  State<_ClassRow> createState() => _ClassRowState();
}

class _ClassRowState extends State<_ClassRow> {
  late final _controller = TextEditingController(
    text: widget.valueBp == 0 ? '' : (widget.valueBp / 100).toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.assetClass.sliceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.assetClass.displayName)),
          SizedBox(
            width: 88,
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
              ],
              decoration: const InputDecoration(suffixText: '%'),
              onChanged: (text) {
                final pct = double.tryParse(text) ?? 0;
                widget.onChanged((pct * 100).round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

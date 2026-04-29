import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/utils/category_icon.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key});

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'star';
  String _selectedColor = '#3B82F6';
  bool _isIncome = false;
  bool _loading = false;

  static const _colorOptions = [
    '#3B82F6', '#22C55E', '#EF4444', '#F97316', '#8B5CF6',
    '#EC4899', '#06B6D4', '#F59E0B', '#10B981', '#6B7280',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      final householdId = await ref.read(householdIdProvider.future);
      if (householdId == null) throw Exception('Not logged in');

      await ref.read(transactionsRepositoryProvider).createCategory(
            householdId: householdId,
            name: name,
            isIncome: _isIncome,
            icon: _selectedIcon,
            color: _selectedColor,
          );

      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
        int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16));

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('New Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          _label('Category Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Pet Care'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Income toggle
          Row(
            children: [
              const Text('Type',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8))),
              const Spacer(),
              _typeChip('Expense', false),
              const SizedBox(width: 8),
              _typeChip('Income', true),
            ],
          ),
          const SizedBox(height: 16),

          // Color
          _label('Color'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorOptions.map((hex) {
              final c = Color(
                  int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
              final selected = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Icon picker
          _label('Icon'),
          SizedBox(
            height: 160,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: categoryIconOptions.length,
              itemBuilder: (_, i) {
                final name = categoryIconOptions[i];
                final selected = name == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.2)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? color : const Color(0xFF334155),
                      ),
                    ),
                    child: Icon(
                      categoryIconData(name),
                      size: 18,
                      color: selected ? color : const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create Category'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8))),
      );

  Widget _typeChip(String label, bool value) {
    final selected = _isIncome == value;
    return GestureDetector(
      onTap: () => setState(() => _isIncome = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF94A3B8),
            )),
      ),
    );
  }
}

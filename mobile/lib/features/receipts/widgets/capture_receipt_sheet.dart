// Bottom sheet for capturing or picking a receipt image, then uploading it.
//
// The user chooses between camera and gallery. After picking, a preview is
// shown so they can confirm before the upload starts.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/household_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/receipts_provider.dart';
import '../repositories/receipts_repository.dart';

/// Shows a modal bottom sheet that lets the user capture a new receipt image
/// or pick one from the photo library.
///
/// On successful upload, invalidates [receiptsProvider] to refresh the grid
/// and navigates to the detail screen for the new receipt.
class CaptureReceiptSheet extends ConsumerStatefulWidget {
  const CaptureReceiptSheet({super.key});

  @override
  ConsumerState<CaptureReceiptSheet> createState() =>
      _CaptureReceiptSheetState();
}

class _CaptureReceiptSheetState extends ConsumerState<CaptureReceiptSheet> {
  File? _pickedFile;
  bool _uploading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 85, // balance quality vs upload size
      maxWidth: 2048,
    );
    if (xfile == null) return; // user cancelled
    setState(() {
      _pickedFile = File(xfile.path);
      _error = null;
    });
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final householdId = await ref.read(householdIdProvider.future);
      final user = ref.read(currentUserProvider);

      if (householdId == null || user == null) {
        setState(() => _error = 'Not logged in.');
        return;
      }

      final repo = ref.read(receiptsRepositoryProvider);
      final receipt = await repo.uploadReceipt(
        householdId: householdId,
        uploadedBy: user.id,
        imageFile: file,
      );

      // Refresh the receipts list so the new item appears in the grid.
      ref.invalidate(receiptsProvider);

      if (mounted) {
        Navigator.of(context).pop(); // close sheet
        context.push('/receipts/${receipt.id}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Add Receipt',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Image preview or picker buttons
            if (_pickedFile == null) ...[
              _PickerButton(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _PickerButton(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Library',
                onTap: () => _pick(ImageSource.gallery),
              ),
            ] else ...[
              // Preview the selected image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _pickedFile!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              // Allow re-picking without losing the preview
              TextButton.icon(
                onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.refresh),
                label: const Text('Choose Different'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading…' : 'Upload Receipt'),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable card used for the camera / gallery picker options.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

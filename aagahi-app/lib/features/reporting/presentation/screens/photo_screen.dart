import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../providers/reporting_providers.dart';
import 'review_screen.dart';

/// Screen F4 (screens_v2.html flow F) - an optional photo, via
/// `image_picker` (CLAUDE.md's package table: no platform channel of our
/// own). A failed pick (no camera app, permission denied, cancelled) shows
/// an honest inline message rather than crashing or silently doing
/// nothing - the farmer should not be left wondering whether the tap
/// registered.
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  String? _pickError;

  Future<void> _pick(ImageSource source) async {
    setState(() => _pickError = null);
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (file == null) return; // user cancelled - not an error
      ref.read(fieldReportDraftProvider.notifier).setPhoto(file.path);
    } catch (_) {
      setState(() => _pickError = 'reporting.photoPickFailed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localisationProvider);
    final photoPath = ref.watch(fieldReportDraftProvider).photoPath;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
              ],
            ),
            Text(
              l10n.translate('reporting.takePicture'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                height: 236,
                width: double.infinity,
                color: AppColors.glass,
                child: photoPath == null
                    ? const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: AppColors.ink3),
                      )
                    : Image.file(File(photoPath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('reporting.photoShrunkNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_pickError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate(_pickError!),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.severe),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(ImageSource.gallery),
                    child: Text(l10n.translate('action.gallery')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _pick(ImageSource.camera),
                    child: Text(l10n.translate('action.capture')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
              ),
              child: Text(l10n.translate(photoPath == null ? 'action.skip' : 'action.next')),
            ),
          ],
        ),
      ),
    );
  }
}

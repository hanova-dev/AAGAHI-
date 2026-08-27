import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'photo_screen.dart';

/// Screen F3 (screens_v2.html flow F) - voice note.
///
/// Ships the same honest "not available" state as E2's audio player
/// (agreed 2026-08-26): no recording is ever attempted here, push-to-talk
/// or otherwise (CON-09 rules out voice activity detection, but real
/// push-to-talk capture is a separate, unbuilt feature - not something
/// this screen fakes). Tapping the mic reveals that plainly; nothing is
/// written to the draft or the database for it.
class VoiceNoteScreen extends StatefulWidget {
  const VoiceNoteScreen({super.key});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  bool _tried = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);

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
                  l10n.translate('reporting.sayWhatYouSee'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.translate('reporting.holdToTalkInstructions'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: InkWell(
                    onTap: () => setState(() => _tried = true),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.seed.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎙️', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_tried)
                  GlassCard(
                    child: Text(
                      l10n.translate('voice.notAvailable'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const PhotoScreen()),
                  ),
                  child: Text(l10n.translate('action.skipVoiceNote')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

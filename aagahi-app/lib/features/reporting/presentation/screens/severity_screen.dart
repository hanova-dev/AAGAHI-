import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../providers/reporting_providers.dart';
import 'voice_note_screen.dart';

/// Screen F2 (screens_v2.html flow F) - severity, 1 (mild) to 5 (worst).
class SeverityScreen extends ConsumerWidget {
  const SeverityScreen({super.key});

  static const _levels = ['🙂', '😐', '😟', '😣', '😖'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final selected = ref.watch(fieldReportDraftProvider).severity;

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
            ListenPill(
              label: l10n.listen,
              isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
              onPressed: () => ref
                  .read(briefingPlaybackProvider.notifier)
                  .speakText(l10n.translate('reporting.howBadIsIt')),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('reporting.howBadIsIt'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
              children: [
                for (var level = 1; level <= 5; level++)
                  _SeverityTile(
                    icon: _levels[level - 1],
                    label: level == 5
                        ? '5 · ${l10n.translate('reporting.worstSuffix')}'
                        : '$level',
                    selected: selected == level,
                    onTap: () => ref
                        .read(fieldReportDraftProvider.notifier)
                        .setSeverity(level),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const VoiceNoteScreen()),
                      ),
              child: Text(l10n.translate('action.next')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityTile extends StatelessWidget {
  const _SeverityTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.seed.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.seed : AppColors.edge,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

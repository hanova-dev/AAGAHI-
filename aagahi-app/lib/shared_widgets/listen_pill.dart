import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The persistent "listen" affordance (UI-EXT-04): every screen carrying
/// spoken content exposes it through this same pill, so a non-literate user
/// learns one control rather than a different one per screen.
class ListenPill extends StatelessWidget {
  const ListenPill({
    required this.label,
    required this.onPressed,
    this.isPlaying = false,
    this.duration,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPlaying;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
            minWidth: AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.seed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.seed.withValues(alpha: 0.38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                size: 18,
                color: AppColors.seed,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.seed,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

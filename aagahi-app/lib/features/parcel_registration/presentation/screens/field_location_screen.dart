import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../providers/parcel_registration_providers.dart';
import 'field_size_screen.dart';

enum _LocationState { idle, fetching, captured, unavailable }

/// Screen B1 (screens_v2.html flow B) - field location.
///
/// The map is illustrative, same convention as `RiskRing`: no maps SDK for
/// a static backdrop image. What "Use this spot" reads is a real GPS fix
/// via geolocator. A farmer who declined location in A4, or whose device
/// has it disabled, is not blocked here - "Continue without location"
/// saves the parcel with null coordinates, which `Parcel.hasLocation`
/// makes an explicit, checkable state rather than a silently wrong (0, 0).
class FieldLocationScreen extends ConsumerStatefulWidget {
  const FieldLocationScreen({super.key});

  @override
  ConsumerState<FieldLocationScreen> createState() =>
      _FieldLocationScreenState();
}

class _FieldLocationScreenState extends ConsumerState<FieldLocationScreen> {
  _LocationState _state = _LocationState.idle;

  Future<void> _useThisSpot() async {
    setState(() => _state = _LocationState.fetching);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      ref.read(parcelDraftProvider.notifier).setLocation(
            position.latitude,
            position.longitude,
          );
      if (!mounted) return;
      setState(() => _state = _LocationState.captured);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LocationState.unavailable);
    }
  }

  void _advance() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const FieldSizeScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localisationProvider);
    final draft = ref.watch(parcelDraftProvider);
    final captured = draft.latitude != null && draft.longitude != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListenPill(
                label: l10n.listen,
                isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                onPressed: () => ref
                    .read(briefingPlaybackProvider.notifier)
                    .speakText(l10n.translate('registration.locationTitle')),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('registration.locationTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  height: 196,
                  width: double.infinity,
                  color: AppColors.canopy,
                  alignment: Alignment.center,
                  child: const Icon(Icons.location_pin,
                      size: 40, color: AppColors.seed),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_state == _LocationState.fetching)
                Text(
                  l10n.translate('registration.locationFetching'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else if (captured)
                Text(
                  '${l10n.translate('registration.locationCaptured')}: '
                  '${draft.latitude!.toStringAsFixed(5)}, '
                  '${draft.longitude!.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else if (_state == _LocationState.unavailable)
                Text(
                  l10n.translate('registration.locationUnavailable'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Text(
                  l10n.translate('registration.locationBody'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const Spacer(),
              if (!captured) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _state == _LocationState.fetching ? null : _useThisSpot,
                    child: Text(l10n.translate('action.useThisSpot')),
                  ),
                ),
                if (_state == _LocationState.unavailable) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _advance,
                      child: Text(
                          l10n.translate('action.continueWithoutLocation')),
                    ),
                  ),
                ],
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _advance,
                    child: Text(l10n.translate('action.next')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

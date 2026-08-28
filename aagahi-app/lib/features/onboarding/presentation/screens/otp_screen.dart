import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'role_screen.dart';

/// Screen A8 (screens_v2.html flow A) - OTP verification.
///
/// Skipped per instruction (2026-08-27): there is no SMS backend, so any
/// 6 digits are accepted rather than faking a real verification check -
/// the on-screen note says exactly that, rather than pretending to verify
/// something with nothing behind it. The reference's custom in-app keypad
/// is dropped for the OS's own numeric keyboard: it already does this, so
/// building a second one would be exactly the "stop and justify it" case
/// CLAUDE.md's minimalism rule warns about.
///
/// "Verify" is also where the phone number is actually persisted (H1 needs
/// it later) - not on A7's "Confirm number", since that step only moves to
/// this screen, it doesn't yet treat the number as accepted.
class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(BuildContext context, WidgetRef ref) async {
    final current =
        await ref.read(settingsRepositoryProvider).watchSettings().first;
    await ref.read(settingsRepositoryProvider).save(
          current.copyWith(phoneNumber: widget.phoneNumber),
        );
    if (!context.mounted) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RoleScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final canVerify = _controller.text.length == 6;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.translate('onboarding.otpTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n
                        .translate('onboarding.otpSentTo')
                        .replaceFirst('{phone}', widget.phoneNumber),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.glass,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.edge)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.translate('onboarding.otpDemoNote'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canVerify ? () => _verify(context, ref) : null,
                      child: Text(l10n.translate('action.verify')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

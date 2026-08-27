import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'otp_screen.dart';

/// Screen A7 (screens_v2.html flow A) - phone number.
///
/// The reference has this spoken, with a live transcript and a confidence
/// chip. Voice input is manual-entry only this phase, so this is a plain
/// text field instead, and the mic button ships the same "not available"
/// state as F3's - agreed (2026-08-27), not silently dropped.
class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _controller = TextEditingController();
  bool _micTried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
        final canConfirm = digits.length >= 7;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.translate('onboarding.phoneTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d +]'))
                    ],
                    style: const TextStyle(color: AppColors.ink, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: '+92 3XX XXXXXXX',
                      hintStyle: TextStyle(color: AppColors.ink3),
                      filled: true,
                      fillColor: AppColors.glass,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.edge)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () => setState(() => _micTried = true),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.edge),
                      ),
                      child: Row(
                        children: [
                          const Text('🎙️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _micTried
                                  ? l10n.translate('voice.notAvailable')
                                  : l10n.translate('onboarding.phoneTitle'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canConfirm
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      OtpScreen(phoneNumber: _controller.text),
                                ),
                              )
                          : null,
                      child: Text(l10n.translate('action.confirmNumber')),
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

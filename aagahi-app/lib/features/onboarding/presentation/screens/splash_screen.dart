import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'language_screen.dart';

/// Screen A1 (screens_v2.html flow A) - branding splash, shown only when
/// this device has no registered parcel yet (see `main.dart`'s first-launch
/// gate). Advances to A2 on its own after a short, fixed delay - there is
/// nothing here for the farmer to act on.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 42, color: AppColors.seed),
              const SizedBox(height: AppSpacing.sm),
              Text('AAGAHI', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 2),
              const Text(
                'آگاہی',
                style: TextStyle(color: AppColors.seed, fontSize: 19),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Know before the field dries',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'Institut Ekosains Borneo · VIICER 2026',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

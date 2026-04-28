// lib/src/presentation/pages/splash/splash_page.dart

import 'package:flutter/material.dart';
import '../onboarding/onboarding_page.dart';
import 'signin_prompt_modal.dart';
import 'splash_modal.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final ValueNotifier<bool> _heroReady = ValueNotifier(false);
  bool _showLoadingSplash = true;
  bool _showGreetingSplash = false;

  void _onLoadingSplashComplete() {
    if (!mounted) return;
    setState(() {
      _showLoadingSplash = false;
      _showGreetingSplash = true;
    });
  }

  void _onGreetingSplashComplete() {
    if (!mounted) return;
    setState(() {
      _showGreetingSplash = false;
    });
  }

  @override
  void dispose() {
    _heroReady.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Onboarding page behind (non-interactive while splash is showing)
        AbsorbPointer(
          absorbing: _showLoadingSplash || _showGreetingSplash,
          child: OnboardingPage(
            onHeroReady: () => _heroReady.value = true,
          ),
        ),

        // 1. Initial Animated Splash (Branding + Circling Triangle)
        if (_showLoadingSplash)
          SplashModal(
            heroReady: _heroReady,
            onComplete: _onLoadingSplashComplete,
          ),

        // 2. African Greetings Modal (Ask if member)
        if (_showGreetingSplash)
          SignInPromptModal(
            onSignIn: () {
              _onGreetingSplashComplete();
              // Navigate to login or show side sheet
            },
            onExplore: _onGreetingSplashComplete,
            onClose: _onGreetingSplashComplete,
          ),
      ],
    );
  }
}

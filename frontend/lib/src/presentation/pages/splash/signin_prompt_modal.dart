// lib/src/presentation/pages/splash/signin_prompt_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Second splash modal: Asks if user is a Hosi Academy member.
/// Members can skip onboarding and go straight to Sign In.
/// New users can explore the onboarding page.
/// Shows a localised greeting in the user's country language.
class SignInPromptModal extends StatefulWidget {
  final VoidCallback onSignIn;
  final VoidCallback onExplore; // "I'm new" → close modal, stay on onboarding
  final VoidCallback onClose;

  const SignInPromptModal({
    super.key,
    required this.onSignIn,
    required this.onExplore,
    required this.onClose,
  });

  @override
  State<SignInPromptModal> createState() => _SignInPromptModalState();
}

class _SignInPromptModalState extends State<SignInPromptModal> {
  GreetingData? _greeting;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGreeting();
  }

  Future<void> _loadGreeting() async {
    final g = await LocalizationService.fetchGreeting();
    if (mounted) setState(() { _greeting = g; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final modalWidth = isSmall ? screenWidth * 0.92 : 420.0;

    final g = _greeting ?? GreetingData.fallback();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: const Color(0xFF050C14).withValues(alpha: 0.75),
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          // Modal card
          Center(
            child: Container(
              width: modalWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF132030), AppTheme.hosiMidnight],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.hosiPeach.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmall ? 28 : 36,
                        32,
                        isSmall ? 28 : 36,
                        32,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.hosiPeach,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── LOGO ──
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: isSmall ? 80 : 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school_rounded,
                                    color: AppTheme.hosiPeach,
                                    size: 40,
                                  ),
                                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(duration: 600.ms),

                                const SizedBox(height: 12),

                                Text(
                                  'The Future of Learning',
                                  textAlign: TextAlign.center,
                                  style: TextStyle( 
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ).animate().fadeIn(delay: 200.ms),

                                const SizedBox(height: 24),

                                // Flag + country greeting
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      g.flag,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.localGreeting,
                                          style: TextStyle( 
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.hosiPeach,
                                          ),
                                        ),
                                        Text(
                                          '${g.officialGreeting}  ·  ${g.localLanguage}',
                                          style: TextStyle( 
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1, end: 0),

                                const SizedBox(height: 32),

                                Text(
                                  'Are you a Hosi Academy member?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle( 
                                    fontSize: isSmall ? 17 : 19,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ).animate().fadeIn(delay: 400.ms),

                                const SizedBox(height: 8),

                                Text(
                                  'Members go straight to their portal.\nNew here? Explore our programmes first.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle( 
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                    height: 1.5,
                                  ),
                                ).animate().fadeIn(delay: 450.ms),

                                const SizedBox(height: 28),

                                // Yes → Sign In
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: widget.onSignIn,
                                    icon: const Icon(Icons.login_rounded, size: 18),
                                    label: const Text(
                                      'Yes, sign me in',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.hosiPeach,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.15, end: 0),

                                const SizedBox(height: 12),

                                // No → Explore
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onExplore,
                                    icon: Icon(
                                      Icons.explore_rounded,
                                      size: 18,
                                      color: AppTheme.hosiPeach.withValues(alpha: 0.8),
                                    ),
                                    label: Text(
                                      "No, I'm new — let me explore",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.hosiPeach.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppTheme.hosiPeach.withValues(alpha: 0.3),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.15, end: 0),

                                const SizedBox(height: 16),

                                TextButton(
                                  onPressed: widget.onClose,
                                  child: Text(
                                    'Maybe later',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 750.ms),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _kenteBlock(Color color, double width) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 1),
      );
}

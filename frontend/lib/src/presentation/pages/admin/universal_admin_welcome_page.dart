import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UniversalAdminWelcomePage extends StatelessWidget {
  final String userName;

  const UniversalAdminWelcomePage({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5, end: 0, duration: 600.ms),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back, $userName',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0, duration: 600.ms),
                  const SizedBox(height: 12),
                  Text(
                    'UNIVERSAL MISSION CONTROL',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 4.0,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0, duration: 600.ms),
                  const SizedBox(height: 48),
                  
                  // Portal Selection Grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPortalCard(
                        context,
                        title: 'System Administration',
                        subtitle: 'Core Settings & Infrastructure',
                        icon: Icons.settings_applications_outlined,
                        color: Colors.redAccent,
                        route: '/admin/dashboard',
                        delay: 300,
                      ),
                      _buildPortalCard(
                        context,
                        title: 'Payment Operations',
                        subtitle: 'Finance & Global Revenue',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.teal,
                        route: '/admin/payments',
                        delay: 400,
                      ),
                      _buildPortalCard(
                        context,
                        title: 'HR & Jurisdictions',
                        subtitle: 'Staffing & Compliance',
                        icon: Icons.people_alt_outlined,
                        color: Colors.blueAccent,
                        route: '/admin/hr',
                        delay: 500,
                      ),
                      _buildPortalCard(
                        context,
                        title: 'Sales & Marketing',
                        subtitle: 'Growth & Outreach',
                        icon: Icons.campaign_outlined,
                        color: Colors.orange,
                        route: '/admin/marketing',
                        delay: 600,
                      ),
                      _buildPortalCard(
                        context,
                        title: 'Executive Insights',
                        subtitle: 'Global Metrics & KPIs',
                        icon: Icons.insights_outlined,
                        color: Colors.indigo,
                        route: '/admin/executive',
                        delay: 700,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 64),
                  
                  TextButton.icon(
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ).animate(delay: 1000.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required int delay,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Access Portal',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0, duration: 600.ms);
  }
}

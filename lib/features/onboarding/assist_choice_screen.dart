import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import '../home/home_screen.dart';
import '../chat/ai_help_screen.dart';

class AssistChoiceScreen extends StatelessWidget {
  const AssistChoiceScreen({super.key});
  static const String route = '/assist-choice';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Back'),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 48),
                  const SizedBox(width: 12),
                  Text(
                    'House of Sheelaa',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'How would you like to start?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              _OptionCard(
                icon: Icons.explore,
                title: 'Continue on my own',
                subtitle:
                    'For experienced users who are ready to navigate without help.',
                gradient: const [
                  BrandColors.jacaranda,
                  BrandColors.cardinalPink,
                ],
                onTap: () {
                  Navigator.of(context).pushReplacementNamed(HomeScreen.route);
                },
              ),
              const SizedBox(height: 16),
              _OptionCard(
                icon: Icons.support_agent,
                title: 'Help me get started',
                subtitle: 'For users who want clear direction and support.',
                gradient: const [BrandColors.ecstasy, BrandColors.cardinalPink],
                onTap: () {
                  Navigator.of(context).pushNamed(AiHelpScreen.route);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

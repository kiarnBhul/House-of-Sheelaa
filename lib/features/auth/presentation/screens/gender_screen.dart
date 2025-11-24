import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import 'details_screen.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});
  static const String route = '/gender';
  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? gender;
  final genders = const ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    gender = context.read<AuthState>().gender;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: cs.onPrimary),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary.withValues(alpha: .8), cs.secondary.withValues(alpha: .8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(4, (i) {
                              final active = i <= 2;
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFFFFD85E) : cs.onPrimary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Gender',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: BrandColors.ecstasy,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This helps us personalize your experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onPrimary.withValues(alpha: .9),
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (final g in genders)
                      _radioCard(
                        context,
                        title: g,
                        selected: gender == g,
                        onTap: () => setState(() => gender = g),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFFD85E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [const Color(0xFFFFD85E), BrandColors.ecstasy]),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.ecstasy.withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: gender == null
                                  ? null
                                  : () {
                                      final a = context.read<AuthState>();
                                      a.updateGender(gender);
                                      Navigator.of(context).pushNamed(DetailsScreen.route);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioCard(BuildContext context, {required String title, required bool selected, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: BrandColors.jacaranda.withValues(alpha: 0.65),
        border: Border.all(
          color: selected ? const Color(0xFFFFD85E) : cs.onPrimary.withValues(alpha: 0.25),
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(title),
        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? const Color(0xFFFFD85E) : cs.onPrimary),
        onTap: onTap,
      ),
    );
  }
}

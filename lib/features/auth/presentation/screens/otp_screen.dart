import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import 'details_screen.dart';
import 'language_screen.dart';
import 'gender_screen.dart';
import '../../../onboarding/assist_choice_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  static const String route = '/otp';
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final controllers = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get code => controllers.map((c) => c.text).join();

  Future<void> submit() async {
    final auth = context.read<AuthState>();
    final ok = await auth.verifyOtp(code);
    if (!mounted) return;
    
    if (ok) {
      // Check if user is fully authenticated (existing user)
      if (auth.status == AuthStatus.authenticated &&
          auth.firstName != null &&
          auth.firstName!.isNotEmpty) {
        // Existing user - go directly to home
        Navigator.of(context).pushNamedAndRemoveUntil(
          AssistChoiceScreen.route,
          (route) => false,
        );
        return;
      }
      
      // New user - go through onboarding flow
      if (auth.language == null) {
        Navigator.of(context).pushNamed(LanguageScreen.route);
        return;
      }
      if (auth.gender == null) {
        Navigator.of(context).pushNamed(GenderScreen.route);
        return;
      }
      
      // Need to complete profile details
      Navigator.of(context).pushNamed(DetailsScreen.route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthState>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: .75),
                    cs.secondary.withValues(alpha: .75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cs2 = Theme.of(context).colorScheme;
                  final w = constraints.maxWidth;
                  const horizontal = 24.0;
                  const spacing = 8.0;
                  final boxW = ((w - (horizontal * 2) - (spacing * 5)) / 6)
                      .clamp(42.0, 56.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/logo.png', height: 64),
                        const SizedBox(height: 8),
                        Text(
                          'Verify OTP',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: BrandColors.ecstasy,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: BrandColors.ecstasy.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the 6-digit code sent to ${auth.phone ?? ''}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: .9),
                              ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: BrandColors.jacaranda.withValues(
                              alpha: 0.60,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFFFD85E),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (i) {
                                  return SizedBox(
                                    width: boxW,
                                    height: boxW,
                                    child: TextField(
                                      controller: controllers[i],
                                      focusNode: nodes[i],
                                      textAlign: TextAlign.center,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      maxLength: 1,
                                      maxLengthEnforcement:
                                          MaxLengthEnforcement.enforced,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: cs2.onPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                        fillColor: BrandColors.alabaster
                                            .withAlpha((255 * 0.12).round()),
                                        filled: true,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: cs2.onPrimary.withValues(
                                              alpha: 0.25,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: BrandColors.ecstasy,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        if (v.isNotEmpty && i < 5) {
                                          nodes[i + 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD85E),
                                      BrandColors.ecstasy,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BrandColors.ecstasy.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: auth.loading ? null : submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: auth.loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Verify & Continue'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: auth.loading
                                    ? null
                                    : () async {
                                        await auth.sendOtp(auth.phone ?? '');
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('OTP resent'),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Resend OTP'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

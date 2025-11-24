import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import '../../state/auth_state.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  static const String route = '/phone-login';
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  String? phoneE164;

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final input = (phoneE164 ?? phoneCtrl.text.trim());
    await auth.sendOtp(input);
    if (!mounted) return;
    Navigator.of(context).pushNamed(OtpScreen.route);
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
        leading: BackButton(color: cs.onPrimary),
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
                    BrandColors.jacaranda.withValues(alpha: .95),
                    BrandColors.cardinalPink.withValues(alpha: .92),
                    BrandColors.persianRed.withValues(alpha: .90),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BrandColors.ecstasy.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BrandColors.goldAccent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
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
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset('assets/images/logo.png', height: 90),
                        const SizedBox(height: 24),
                        Text(
                          'WELCOME',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: BrandColors.ecstasy,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                fontSize: 38,
                                shadows: [
                                  Shadow(
                                    color: BrandColors.codGrey.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter your phone number to begin\nyour spiritual journey',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: cs.onPrimary.withValues(alpha: .95),
                                fontSize: 16,
                                height: 1.5,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Glassmorphism card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BrandColors.alabaster.withValues(alpha: 0.18),
                            BrandColors.alabaster.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: BrandColors.ecstasy.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.codGrey.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            IntlPhoneField(
                              controller: phoneCtrl,
                              initialCountryCode: 'IN',
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(
                                  color: BrandColors.alabaster,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: BrandColors.codGrey.withValues(
                                  alpha: 0.4,
                                ),
                                prefixIcon: Icon(
                                  Icons.phone_android_rounded,
                                  color: BrandColors.ecstasy,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: BrandColors.ecstasy.withValues(alpha: 0.7),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: BrandColors.ecstasy,
                                    width: 3,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: BrandColors.persianRed.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: BrandColors.persianRed,
                                    width: 3,
                                  ),
                                ),
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              dropdownTextStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: cs.onPrimary),
                              onChanged: (phone) =>
                                  phoneE164 = phone.completeNumber,
                              validator: (phone) {
                                final raw = phone?.number ?? '';
                                return raw.trim().length < 8
                                    ? 'Please enter a valid phone number'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 28),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    BrandColors.ecstasy,
                                    BrandColors.persianRed,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: BrandColors.ecstasy.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: auth.loading ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: auth.loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                        Text(
                                          'Send OTP',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: BrandColors.alabaster,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: BrandColors.alabaster,
                                        ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: cs.onPrimary.withValues(
                                        alpha: .8,
                                      ),
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

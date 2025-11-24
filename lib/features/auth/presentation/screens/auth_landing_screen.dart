import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import 'otp_screen.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});
  static const String route = '/auth';
  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  String phone = '';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    await auth.sendOtp(phone);
    if (!mounted) return;
    Navigator.of(context).push(_createRoute(OtpScreen.route));
  }

  Route _createRoute(String route) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const OtpScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: tween, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
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
                    cs.primary.withValues(alpha: .85),
                    cs.secondary.withValues(alpha: .85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/logo.png', height: 48),
                        const SizedBox(width: 12),
                        Text(
                          'House of Sheelaa',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BrandColors.jacaranda.withAlpha(
                          (255 * 0.9).round(),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  IntlPhoneField(
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    initialCountryCode: 'IN',
                                    onChanged: (p) => phone = p.completeNumber,
                                    invalidNumberMessage:
                                        'Invalid phone number',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed:
                                        context.watch<AuthState>().loading
                                        ? null
                                        : submit,
                                    child: context.watch<AuthState>().loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Continue'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: AnimatedOpacity(
                              opacity: _fadeAnim.value,
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'House of Sheelaa',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onPrimary.withValues(alpha: .8),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
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

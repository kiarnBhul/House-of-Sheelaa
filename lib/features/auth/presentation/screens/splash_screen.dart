import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import 'phone_login_screen.dart';
import '../../../home/home_screen.dart';
import '../../../../theme/brand_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const String route = '/';
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // Initialize auth (quick, with error handling)
      try {
        await context.read<AuthState>().initialize();
      } catch (e) {
        debugPrint('[SplashScreen] Auth init error: $e');
      }
      
      // Show UI after animation
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      
      final status = context.read<AuthState>().status;
      if (status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.route);
      } else {
        Navigator.of(context).pushReplacementNamed(PhoneLoginScreen.route);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
              BrandColors.persianRed,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple logo without glow
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Simple title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'House of Sheelaa',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Simple subtitle
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Your Spiritual Journey Begins',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BrandColors.alabaster.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Simple loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      BrandColors.ecstasy,
                    ),
                    backgroundColor: BrandColors.alabaster.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

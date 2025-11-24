import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../../onboarding/assist_choice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String route = '/login';
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailOrPhoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    emailOrPhoneCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final ok = await auth.login(
      emailOrPhoneCtrl.text.trim(),
      passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AssistChoiceScreen.route, (route) => false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextFormField(
                controller: emailOrPhoneCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email or Phone'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.loading ? null : submit,
                child: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: cs.tertiary),
                child: const Text('Forgot password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

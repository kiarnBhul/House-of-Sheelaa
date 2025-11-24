import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../../onboarding/assist_choice_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});
  static const String route = '/details';
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  DateTime? dob;
  final options = const [
    'Numerology',
    'Healing',
    'Rituals',
    'Card Reading',
    'Other Services',
    'Specials',
  ];
  final selected = <String>[];

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      confirmText: 'OK',
      cancelText: 'CANCEL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: BrandColors.ecstasy,
              onPrimary: BrandColors.codGrey,
              surface: BrandColors.jacaranda,
              onSurface: BrandColors.alabaster,
              secondary: BrandColors.cardinalPink,
              onSecondary: BrandColors.alabaster,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: BrandColors.jacaranda,
              surfaceTintColor: BrandColors.jacaranda,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.alabaster,
                backgroundColor: BrandColors.cardinalPink,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: BrandColors.ecstasy.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => dob = picked);
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (dob == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select date of birth')));
      return;
    }
    final auth = context.read<AuthState>();
    final ok = await auth.saveProfile(
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      dob: dob!,
      interests: selected,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AssistChoiceScreen.route, (route) => false);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/logo.png', height: 40),
                        const SizedBox(width: 12),
                        Text(
                          'Tell us about you',
                          style: Theme.of(context).textTheme.headlineSmall
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Expanded(
                            child: Container(
                              height: 6,
                              margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                              decoration: BoxDecoration(
                                color: i <= 3
                                    ? const Color(0xFFFFD85E)
                                    : Theme.of(context).colorScheme.onPrimary
                                          .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: BrandColors.jacaranda.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFFD85E),
                          width: 2,
                        ),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final small = constraints.maxWidth < 360;
                                final first = TextFormField(
                                  controller: firstNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                );
                                final last = TextFormField(
                                  controller: lastNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                );
                                if (small) {
                                  return Column(
                                    children: [
                                      first,
                                      const SizedBox(height: 12),
                                      last,
                                    ],
                                  );
                                } else {
                                  return Row(
                                    children: [
                                      Expanded(child: first),
                                      const SizedBox(width: 12),
                                      Expanded(child: last),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: pickDob,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
                                ),
                                child: Text(
                                  dob == null
                                      ? 'Select date'
                                      : '${dob!.day}/${dob!.month}/${dob!.year}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Interests',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((o) {
                                final sel = selected.contains(o);
                                return ChoiceChip(
                                  label: Text(o),
                                  selected: sel,
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        selected.add(o);
                                      } else {
                                        selected.remove(o);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
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
                                    : const Text('Continue'),
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

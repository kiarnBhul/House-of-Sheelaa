import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/features/auth/state/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  static const String route = '/edit-profile';
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
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
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    firstNameCtrl.text = auth.firstName ?? '';
    lastNameCtrl.text = auth.lastName ?? '';
    emailCtrl.text = auth.email ?? '';
    phoneCtrl.text = auth.phone ?? '';
    dob = auth.dob;
    selected.addAll(auth.interests);
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      confirmText: 'OK',
      cancelText: 'Cancel',
      builder: (context, child) {
        final base = Theme.of(context);
        final scheme = ColorScheme.dark(
          primary: BrandColors.ecstasy,
          onPrimary: BrandColors.codGrey,
          surface: BrandColors.jacaranda,
          onSurface: BrandColors.alabaster,
          secondary: BrandColors.cardinalPink,
          onSecondary: BrandColors.alabaster,
        );
        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogTheme: DialogThemeData(
              backgroundColor: BrandColors.jacaranda,
              surfaceTintColor: BrandColors.jacaranda,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.alabaster,
                backgroundColor: BrandColors.cardinalPink,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      dob: dob!,
      interests: selected,
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Edit Profile',
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
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: firstNameCtrl,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: BrandColors.alabaster,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: BrandColors.alabaster
                                                .withValues(alpha: 0.85),
                                          ),
                                      filled: true,
                                      fillColor: BrandColors.alabaster
                                          .withValues(alpha: 0.08),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: BrandColors.alabaster
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                          color: BrandColors.ecstasy,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: lastNameCtrl,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: BrandColors.alabaster,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: BrandColors.alabaster
                                                .withValues(alpha: 0.85),
                                          ),
                                      filled: true,
                                      fillColor: BrandColors.alabaster
                                          .withValues(alpha: 0.08),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: BrandColors.alabaster
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                          color: BrandColors.ecstasy,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: BrandColors.alabaster,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: BrandColors.alabaster
                                          .withValues(alpha: 0.85),
                                    ),
                                filled: true,
                                fillColor: BrandColors.alabaster
                                    .withValues(alpha: 0.08),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: BrandColors.alabaster
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: BrandColors.ecstasy,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: BrandColors.alabaster,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: BrandColors.alabaster
                                          .withValues(alpha: 0.85),
                                    ),
                                filled: true,
                                fillColor: BrandColors.alabaster
                                    .withValues(alpha: 0.08),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: BrandColors.alabaster
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: BrandColors.ecstasy,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (v.length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: pickDob,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth',
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: BrandColors.alabaster.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                  filled: true,
                                  fillColor: BrandColors.alabaster.withValues(
                                    alpha: 0.08,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: BrandColors.alabaster.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: BrandColors.ecstasy,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  dob == null
                                      ? 'Select date'
                                      : '${dob!.day}/${dob!.month}/${dob!.year}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: BrandColors.alabaster),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Interests',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: cs.onPrimary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((o) {
                                final sel = selected.contains(o);
                                return ChoiceChip(
                                  label: Text(
                                    o,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: sel
                                              ? BrandColors.alabaster
                                              : BrandColors.alabaster
                                                    .withValues(alpha: 0.9),
                                        ),
                                  ),
                                  selected: sel,
                                  selectedColor: BrandColors.ecstasy.withValues(
                                    alpha: 0.85,
                                  ),
                                  backgroundColor: BrandColors.alabaster
                                      .withValues(alpha: 0.12),
                                  side: BorderSide(
                                    color: BrandColors.alabaster.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
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
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: auth.loading ? null : submit,
                              child: auth.loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
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
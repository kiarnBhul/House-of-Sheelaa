import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/features/auth/state/auth_state.dart';
import 'package:house_of_sheelaa/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:house_of_sheelaa/features/profile/edit_profile_screen.dart';
import 'package:house_of_sheelaa/features/home/home_screen.dart';
import 'package:house_of_sheelaa/features/admin/admin_entry_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthState>();
    final fname = auth.firstName ?? '';
    final lname = auth.lastName ?? '';
    final displayName = auth.name?.trim().isNotEmpty == true
        ? auth.name!
        : [fname, lname].where((e) => e.trim().isNotEmpty).join(' ').trim();
    final phone = auth.phone ?? '';
    final initials = _initials(fname, lname, auth.name);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: BrandColors.alabaster),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: BrandColors.alabaster),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(HomeScreen.route, (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.alabaster.withValues(alpha: 0.3),
                      BrandColors.alabaster.withValues(alpha: 0.2),
                      BrandColors.alabaster.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.alabaster.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.codGrey.withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: BrandColors.goldAccent.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                  ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                  children: [
                    Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                BrandColors.ecstasy,
                                BrandColors.persianRed,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BrandColors.ecstasy.withValues(alpha: 0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                                  BrandColors.alabaster.withValues(alpha: 0.25),
                                  BrandColors.alabaster.withValues(alpha: 0.15),
                          ],
                        ),
                        border: Border.all(
                                color: BrandColors.alabaster.withValues(alpha: 0.5),
                                width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                              style: tt.headlineMedium?.copyWith(
                          color: BrandColors.alabaster,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                        ),
                      ),
                    ),
                        const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isEmpty ? 'Your Profile' : displayName,
                            style: tt.titleLarge?.copyWith(
                              color: BrandColors.alabaster,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                          ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 16,
                                      color: BrandColors.ecstasy,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                              phone,
                              style: tt.bodyMedium?.copyWith(
                                color: BrandColors.alabaster.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            BrandColors.ecstasy,
                            BrandColors.persianRed,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.ecstasy.withValues(alpha: 0.6),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(EditProfileScreen.route),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        foregroundColor: BrandColors.alabaster,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                        icon: const Icon(Icons.edit_rounded, size: 20, color: BrandColors.alabaster),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            color: BrandColors.alabaster,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Interests',
                style: tt.titleLarge?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: auth.interests
                    .map(
                      (o) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BrandColors.alabaster.withValues(alpha: 0.25),
                              BrandColors.alabaster.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: BrandColors.alabaster.withValues(alpha: 0.4),
                            width: 1.5,
                        ),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.goldAccent.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          o,
                          style: tt.bodyMedium?.copyWith(
                            color: BrandColors.alabaster,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.alabaster.withValues(alpha: 0.28),
                      BrandColors.alabaster.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.alabaster.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.codGrey.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                  ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.shopping_bag_rounded,
                      title: 'Orders',
                      subtitle: 'View past orders and status',
                      onTap: () {},
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            BrandColors.alabaster.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'Notifications, privacy, preferences',
                      onTap: () {},
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            BrandColors.alabaster.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                    ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Panel',
                      subtitle: 'Manage services, analytics, and integrations',
                      onTap: () {
                        Navigator.of(context).pushNamed(AdminEntryScreen.route);
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            BrandColors.alabaster.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                    ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      subtitle: null,
                      onTap: () {
                        context.read<AuthState>().logout();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          PhoneLoginScreen.route,
                          (route) => false,
                        );
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isDestructive
                      ? LinearGradient(
                          colors: [
                            BrandColors.persianRed.withValues(alpha: 0.3),
                            BrandColors.persianRed.withValues(alpha: 0.2),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            BrandColors.ecstasy.withValues(alpha: 0.3),
                            BrandColors.persianRed.withValues(alpha: 0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDestructive
                        ? BrandColors.persianRed.withValues(alpha: 0.6)
                        : BrandColors.ecstasy.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? BrandColors.persianRed
                      : BrandColors.ecstasy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        color: isDestructive
                            ? BrandColors.persianRed
                            : BrandColors.alabaster,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: BrandColors.alabaster.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isDestructive
                    ? BrandColors.persianRed.withValues(alpha: 0.8)
                    : BrandColors.alabaster.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? f, String? l, String? full) {
    final parts = <String>[];
    if (f != null && f.trim().isNotEmpty) parts.add(f.trim());
    if (l != null && l.trim().isNotEmpty) parts.add(l.trim());
    if (parts.isEmpty && full != null && full.trim().isNotEmpty) {
      final t = full.trim().split(' ');
      parts.addAll(t.take(2));
    }
    final s = parts.map((e) => e[0].toUpperCase()).join();
    return s.isEmpty ? '🙂' : s;
  }
}
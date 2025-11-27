import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/auth/admin_auth_state.dart';
import '../../theme/brand_theme.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: BrandColors.codGrey,
      body: Row(
        children: [
          // Side Navigation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarExpanded ? 280 : 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandColors.jacaranda,
                    BrandColors.jacaranda.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo and Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _isSidebarExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BrandColors.cardinalPink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      secondChild: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BrandColors.cardinalPink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _NavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/dashboard') &&
                              !location.startsWith('/hofs-admin/dashboard/numero'),
                          onTap: () => context.go('/hofs-admin/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.numbers_rounded,
                          label: 'Numero Dashboard',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/dashboard/numero'),
                          onTap: () => context.go('/hofs-admin/dashboard/numero'),
                        ),
                        _NavItem(
                          icon: Icons.integration_instructions_rounded,
                          label: 'Integration',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/integration'),
                          onTap: () => context.go('/hofs-admin/integration'),
                        ),
                        _NavItem(
                          icon: Icons.miscellaneous_services_rounded,
                          label: 'Services',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/services'),
                          onTap: () => context.go('/hofs-admin/services'),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        _NavItem(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/settings'),
                          onTap: () {},
                        ),
                        _NavItem(
                          icon: Icons.analytics_rounded,
                          label: 'Analytics',
                          isExpanded: _isSidebarExpanded,
                          isSelected: location.startsWith('/hofs-admin/analytics'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  // Toggle Button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isSidebarExpanded
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  onMenuTap: isMobile
                      ? () {
                          Scaffold.of(context).openDrawer();
                        }
                      : null,
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A1A2E),
                            Color(0xFF16213E),
                            Color(0xFF0F3460),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? BrandColors.cardinalPink.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: BrandColors.cardinalPink.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const _TopBar({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthState>();
    final theme = Theme.of(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuTap,
            )
          else
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // Navigate back to main app
                Navigator.of(context).pop();
              },
              tooltip: 'Back to App',
            ),
          const Spacer(),
          // Search Bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: BrandColors.persianRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          // User Profile
          Container(
            decoration: BoxDecoration(
              color: BrandColors.cardinalPink,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sign Out
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                auth.signOut();
              context.go('/hofs-admin/login');
            },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: BrandColors.persianRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BrandColors.persianRed,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout, color: BrandColors.persianRed, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: BrandColors.persianRed,
                        fontWeight: FontWeight.w600,
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

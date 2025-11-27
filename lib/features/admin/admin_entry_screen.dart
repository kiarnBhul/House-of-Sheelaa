import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../admin/core/auth/admin_auth_state.dart';
import '../../admin/features/auth/login_page.dart';
import '../../admin/features/dashboard/dashboard_page.dart';
import '../../admin/features/dashboard/numero_dashboard_page.dart';
import '../../admin/features/integration/integration_page.dart';
import '../../admin/layout/admin_shell.dart';
import '../../admin/features/services/services_list_page.dart';
import '../../admin/features/services/services_edit_page.dart';
import '../../core/odoo/odoo_state.dart';

/// Entry screen that wraps the admin panel and integrates it with the main app
class AdminEntryScreen extends StatelessWidget {
  const AdminEntryScreen({super.key});

  static const String route = '/admin';

  @override
  Widget build(BuildContext context) {
    // Initialize admin auth state
    final auth = AdminAuthState();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthState>.value(value: auth),
        ChangeNotifierProvider(create: (_) => OdooState()),
      ],
      child: MaterialApp.router(
        title: 'Admin Panel',
        routerConfig: _buildAdminRouter(auth),
        theme: Theme.of(context).copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  GoRouter _buildAdminRouter(AdminAuthState auth) {
    return GoRouter(
      initialLocation: '/hofs-admin/dashboard',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final goingToLogin = state.matchedLocation.startsWith('/hofs-admin/login');
        if (!loggedIn && !goingToLogin) return '/hofs-admin/login';
        if (loggedIn && goingToLogin) return '/hofs-admin/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/hofs-admin/login',
          name: 'admin-login',
          builder: (context, state) => LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/hofs-admin/dashboard',
              name: 'admin-dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/hofs-admin/dashboard/numero',
              name: 'numero-dashboard',
              builder: (context, state) => const NumeroDashboardPage(),
            ),
            GoRoute(
              path: '/hofs-admin/integration',
              name: 'integration',
              builder: (context, state) => const IntegrationPage(),
            ),
            GoRoute(
              path: '/hofs-admin/services',
              name: 'services-list',
              builder: (context, state) => ServicesListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'services-new',
                  builder: (context, state) => ServicesEditPage(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'services-edit',
                  builder: (context, state) => ServicesEditPage(id: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

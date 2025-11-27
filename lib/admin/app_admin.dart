import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/auth/admin_auth_state.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/dashboard/numero_dashboard_page.dart';
import 'features/integration/integration_page.dart';
import 'layout/admin_shell.dart';
import 'features/services/services_list_page.dart';
import 'features/services/services_edit_page.dart';
import '../theme/brand_theme.dart';
import '../core/odoo/odoo_state.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AdminAuthState();
    final router = _buildRouter(auth);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthState>.value(value: auth),
        ChangeNotifierProvider(create: (_) => OdooState()),
      ],
      child: MaterialApp.router(
        title: 'House of Sheelaa Admin',
        routerConfig: router,
        theme: BrandTheme.dark.copyWith(
          // Ensure buttons are visible
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.cardinalPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          // Ensure text buttons are visible
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: BrandColors.ecstasy,
            ),
          ),
          // Ensure outlined buttons are visible
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          // Ensure input fields are visible
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BrandColors.ecstasy, width: 2),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  GoRouter _buildRouter(AdminAuthState auth) {
    return GoRouter(
      initialLocation: '/hofs-admin/dashboard',
      refreshListenable: auth,
      // Optimize navigation transitions
      observers: [
        // Add route observer for performance monitoring if needed
      ],
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
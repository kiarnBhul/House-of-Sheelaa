import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/odoo/odoo_state.dart';
import '../../../theme/brand_theme.dart';
import '../../../features/admin/odoo_config_screen.dart';
import 'odoo_categories_page.dart';

class IntegrationPage extends StatelessWidget {
  const IntegrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              RepaintBoundary(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [BrandColors.jacaranda, BrandColors.cardinalPink],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.integration_instructions_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integrations',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your third-party integrations and API connections',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Integration Cards
              const _IntegrationCards(),
              const SizedBox(height: 20),
              // Quick link to manage categories in Odoo
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const OdooCategoriesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.category_rounded),
                    label: const Text('Manage Odoo Categories'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.jacaranda,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // API Status
              const _ApiStatusSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntegrationCards extends StatelessWidget {
  const _IntegrationCards();

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when connection status changes
    final odooState = context.watch<OdooState>();
    final isConnected = odooState.isAuthenticated;
    
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1200;
          final crossAxisCount = isWide ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.1,
            children: [
              _IntegrationCard(
                title: 'Odoo ERP',
                description: 'Manage services, products, orders, and inventory (except Numerology)',
                icon: Icons.inventory_2_rounded,
                gradient: const [BrandColors.jacaranda, BrandColors.cardinalPink],
                isConnected: isConnected,
                onConfigure: () {
                  // Navigate to Odoo configuration
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OdooConfigScreen(),
                    ),
                  );
                },
              ),
              _IntegrationCard(
                title: 'Firebase',
                description: 'Authentication and cloud storage',
                icon: Icons.cloud_rounded,
                gradient: const [BrandColors.cardinalPink, BrandColors.persianRed],
                isConnected: true,
                onConfigure: () {},
              ),
              _IntegrationCard(
                title: 'Payment Gateway',
                description: 'Razorpay payment processing',
                icon: Icons.payment_rounded,
                gradient: const [BrandColors.persianRed, BrandColors.ecstasy],
                isConnected: false,
                onConfigure: () {},
              ),
          ],
        );
      },
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final bool isConnected;
  final VoidCallback onConfigure;

  const _IntegrationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.isConnected,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient.map((c) => c.withValues(alpha: 0.2)).toList(),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient.first.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Connected' : 'Not Connected',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfigure,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradient.first,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Configure',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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

class _ApiStatusSection extends StatelessWidget {
  const _ApiStatusSection();

  @override
  Widget build(BuildContext context) {
    // Use read instead of watch to avoid unnecessary rebuilds
    final odooState = context.read<OdooState>();

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _ApiStatusItem(
              label: 'Odoo API',
              status: odooState.isAuthenticated ? 'Connected' : 'Disconnected',
              isActive: odooState.isAuthenticated,
              lastSync: '2 hours ago',
              icon: Icons.api_rounded,
            ),
            const SizedBox(height: 16),
            const _ApiStatusItem(
              label: 'Firebase',
              status: 'Connected',
              isActive: true,
              lastSync: 'Just now',
              icon: Icons.cloud_done_rounded,
            ),
            const SizedBox(height: 16),
            const _ApiStatusItem(
              label: 'Analytics',
              status: 'Connected',
              isActive: true,
              lastSync: '5 minutes ago',
              icon: Icons.analytics_rounded,
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Sync all integrations
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.cardinalPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Test connections
                  },
                  icon: const Icon(Icons.bug_report_rounded),
                  label: const Text('Test Connections'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiStatusItem extends StatelessWidget {
  final String label;
  final String status;
  final bool isActive;
  final String lastSync;
  final IconData icon;

  const _ApiStatusItem({
    required this.label,
    required this.status,
    required this.isActive,
    required this.lastSync,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last sync: $lastSync',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


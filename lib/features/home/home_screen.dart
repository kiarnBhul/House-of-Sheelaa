// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/features/auth/state/auth_state.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/features/services/service_detail_screen.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_state.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';
import 'package:house_of_sheelaa/features/store/shop_screen_new.dart';
import 'package:house_of_sheelaa/features/store/cart_screen.dart';
import 'package:house_of_sheelaa/features/store/state/cart_state.dart';
import 'package:house_of_sheelaa/features/profile/profile_screen.dart';
import 'package:house_of_sheelaa/features/policies/privacy_policy_screen.dart';
import 'package:house_of_sheelaa/features/policies/refund_policy_screen.dart';
import 'package:house_of_sheelaa/features/policies/shipping_policy_screen.dart';
import 'package:house_of_sheelaa/features/events/events_screen.dart';
import 'package:house_of_sheelaa/features/services/odoo_diagnostic_screen.dart';

// Improved, modern and cleaner HomeScreen design.
// - Replaced external carousel dependency with native PageView
// - Fixed analyzer warnings and deprecated API usage
// - Stateful widget to manage carousel and bottom nav state

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _carouselIndex = 0;
  int _bottomIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoPlayTimer;

  // --- Data (kept concise) ---
  // Demo events removed
  final List<Map<String, String>> _events = [];

  // If Odoo is configured and provides events, the UI will prefer those.

  // Demo consultants removed
  final List<Map<String, dynamic>> _topConsultants = [];

  // Demo products removed
  final List<Map<String, String>> _products = [];

  // --- Layout constants ---
  static const double _outerPadding = 20;
  static const double _cardRadius = 20;

  @override
  void initState() {
    super.initState();
    // simple autoplay for the pageview
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients && _events.isNotEmpty) {
        final next = (_carouselIndex + 1) % _events.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: cs.surface,
      drawer: _buildNavigationDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.jacaranda.withValues(alpha: 0.95),
              BrandColors.cardinalPink.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 18)),
              SliverToBoxAdapter(child: _buildEventsCarousel()),
              SliverToBoxAdapter(child: const SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _outerPadding,
                  ),
                  child: _buildSearchBar(context),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildExploreDesires(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              // SliverToBoxAdapter(child: _buildTopConsultants(context)),
              // SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildServicesSection(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildStoreSection(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthState>();
    final greetName = (auth.firstName?.isNotEmpty ?? false)
        ? auth.firstName!
        : ((auth.name?.isNotEmpty ?? false) ? auth.name! : 'Seeker');
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _outerPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.alabaster.withValues(alpha: 0.3),
            BrandColors.alabaster.withValues(alpha: 0.18),
            BrandColors.alabaster.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.codGrey.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: BrandColors.goldAccent.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              BrandColors.alabaster.withValues(alpha: 0.12),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Top Row: Menu Button and Action Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            // Drawer Menu Button
            Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      BrandColors.alabaster.withValues(alpha: 0.25),
                      BrandColors.alabaster.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.alabaster.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.alabaster.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.menu_rounded,
                        size: 24,
                        color: BrandColors.alabaster,
                      ),
                    ),
                  ),
                ),
              ),
            ),
                // Action Icons Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.alabaster.withValues(alpha: 0.25),
                        BrandColors.alabaster.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                      color: BrandColors.alabaster.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.alabaster.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 22,
                          color: BrandColors.alabaster,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Cart Button with Badge
                Consumer<CartState>(
                  builder: (context, cart, child) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.alabaster.withValues(alpha: 0.25),
                                BrandColors.alabaster.withValues(alpha: 0.15),
                              ],
                            ),
                            border: Border.all(
                              color: BrandColors.alabaster.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BrandColors.alabaster.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).pushNamed(CartScreen.route),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 22,
                                  color: BrandColors.alabaster,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: BrandColors.ecstasy,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                                style: TextStyle(
                                  color: BrandColors.alabaster,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(width: 10),
                Container(
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
                        color: BrandColors.ecstasy.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 22,
                              color: BrandColors.alabaster,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: BrandColors.alabaster,
                                  border: Border.all(
                                    color: BrandColors.persianRed,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Greeting and Name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste,',
                        style: tt.bodyLarge?.copyWith(
                          color: BrandColors.alabaster.withValues(alpha: 0.85),
                          fontSize: 16,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              greetName,
                              style: tt.headlineMedium?.copyWith(
                                color: BrandColors.alabaster,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  BrandColors.ecstasy,
                                  BrandColors.persianRed,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.ecstasy.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text('🌙', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCarousel() {
    final odooState = context.watch<OdooState>();
    final odooEvents = odooState.events;
    final sourceEvents = odooEvents.map((e) => {
            'title': e.name,
            'subtitle': e.description ?? '',
            'date': e.dateBegin?.toIso8601String() ?? '',
            'image': e.imageUrl ?? 'assets/images/background.jpg',
          }).toList();

    if (sourceEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: sourceEvents.length,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            itemBuilder: (ctx, idx) {
              final e = sourceEvents[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_cardRadius + 4),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.codGrey.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: BrandColors.goldAccent.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_cardRadius + 4),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            e['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/background.jpg',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          // Top gradient for better contrast
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: [
                                  BrandColors.jacaranda.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(
                                      e['title'] ?? '',
                                  style: const TextStyle(
                                    color: BrandColors.alabaster,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                        Text(
                                          e['subtitle'] ?? '',
                                  style: TextStyle(
                                    color: BrandColors.alabaster.withValues(
                                      alpha: 0.95,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            BrandColors.alabaster.withValues(
                                              alpha: 0.25,
                                            ),
                                            BrandColors.alabaster.withValues(
                                              alpha: 0.15,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: BrandColors.alabaster.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: BrandColors.ecstasy,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            e['date'] ?? '',
                                            style: const TextStyle(
                                              color: BrandColors.alabaster,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            BrandColors.ecstasy,
                                            BrandColors.persianRed,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: BrandColors.ecstasy.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: BrandColors.alabaster,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Book Now',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: BrandColors.alabaster,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _events.length,
            (i) => _buildDot(i == _carouselIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: active ? 18 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: active
          ? BrandColors.alabaster
          : BrandColors.alabaster.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.alabaster.withValues(alpha: 0.28),
            BrandColors.alabaster.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.codGrey.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: BrandColors.goldAccent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                BrandColors.alabaster.withValues(alpha: 0.12),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      BrandColors.goldAccent,
                      BrandColors.ecstasy,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.ecstasy.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: BrandColors.codGrey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Search consultants, desires, remedies...',
                    hintStyle: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      BrandColors.alabaster.withValues(alpha: 0.25),
                      BrandColors.alabaster.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.alabaster.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.alabaster.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: BrandColors.alabaster,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildDailyCard removed (no longer used)

  // Removed legacy categories widget (replaced by _buildExploreDesires)

  Widget _buildExploreDesires(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final items = [
      {"icon": Icons.favorite, "label": 'Love'},
      {"icon": Icons.people, "label": 'Relationship'},
      {"icon": Icons.work, "label": 'Career'},
      {"icon": Icons.business_center, "label": 'Business'},
      {"icon": Icons.attach_money, "label": 'Money'},
      {"icon": Icons.health_and_safety, "label": 'Health'},
      {"icon": Icons.school, "label": 'Education'},
      {"icon": Icons.family_restroom, "label": 'Family'},
      {"icon": Icons.flight_takeoff, "label": 'Travel'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Explore Desires',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: BrandColors.codGrey.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.alabaster.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BrandColors.alabaster.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 500 ? 3 : 2;
              const spacing = 10.0;
              final itemWidth = (w - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items.map((c) {
                  return SizedBox(
                    width: itemWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {},
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: BrandColors.alabaster.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: BrandColors.alabaster.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                c['icon'] as IconData,
                                size: 20,
                                color: BrandColors.ecstasy,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  c['label'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    color: BrandColors.alabaster,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTopConsultants(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
          child:           Row(
            children: [
              Expanded(
                child: Text(
                  'Top Consultants',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: BrandColors.codGrey.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.alabaster.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BrandColors.alabaster.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 340,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
            scrollDirection: Axis.horizontal,
            itemCount: _topConsultants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final a = _topConsultants[i];
              return _consultantCard(context, a);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final odooState = context.watch<OdooState>();
    final bool hasCategories = odooState.isAuthenticated && odooState.categories.isNotEmpty;
    final cats = hasCategories
            ? odooState.categories.map((cat) {
            // find services under this category (match internal category or public ecommerce categories)
            final services = odooState.services.where((s) {
              final byPublic = s.publicCategoryIds != null && s.publicCategoryIds!.contains(cat.id);
              final byInternal = s.categoryId != null && s.categoryId == cat.id;
              return byPublic || byInternal;
            }).toList();

            // also find products (goods) attached to this ecommerce category
            final products = odooState.products.where((p) {
              final byPublic = p.publicCategoryIds != null && p.publicCategoryIds!.contains(cat.id);
              final byInternal = p.categoryId != null && p.categoryId == cat.id;
              return byPublic || byInternal;
            }).toList();

            // combine services and products into subs (products will have price and no duration)
            final subs = <Map<String, dynamic>>[];
            for (var s in services) {
              subs.add({
                'type': 'service',
                'id': s.id,
                'name': s.name,
                'durationMin': null,
                'price': s.price,
                'image': s.imageUrl ?? 'assets/images/background.jpg',
              });
            }
            for (var p in products) {
              subs.add({
                'type': 'product',
                'id': p.id,
                'name': p.name,
                'durationMin': null,
                'price': p.price,
                'image': p.imageUrl ?? 'assets/images/background.jpg',
              });
            }

            return {
              'name': cat.name,
              'subtitle': '',
              'id': cat.id,
              'image': cat.imageUrl ?? (subs.isNotEmpty ? subs.first['image'] as String : 'assets/images/background.jpg'),
              'icon': Icons.miscellaneous_services_rounded,
              'subs': subs,
            };
          }).toList()
        : []; // No fallback demo data

    if (cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _outerPadding, vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.spa_outlined, size: 48, color: BrandColors.alabaster.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No services available',
                style: TextStyle(color: BrandColors.alabaster.withValues(alpha: 0.7)),
              ),
              if (!odooState.isAuthenticated)
                 TextButton(
                   onPressed: () {
                     // Navigate to config? Or just show message
                   },
                   child: const Text('Connect to Odoo', style: TextStyle(color: BrandColors.ecstasy)),
                 ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
          child:           Row(
            children: [
              Expanded(
                child: Text(
                  'Services',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: BrandColors.codGrey.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.alabaster.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BrandColors.alabaster.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 700 ? 3 : 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: cats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (ctx, i) => _serviceCard(context, cats[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _serviceCard(BuildContext context, Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(ServiceDetailScreen.route, arguments: cat);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: BrandColors.alabaster.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.codGrey.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                cat['image'] as String,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x4030012F),
                          Color(0x407E0562),
                          Color(0x20F9751E),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x8030012F),
                          Color(0x807E0562),
                          Color(0x40F9751E),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x8030012F),
                      Color(0x807E0562),
                      Color(0x40F9751E),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: BrandColors.alabaster.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: BrandColors.alabaster,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      cat['name'] as String,
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['subtitle'] as String,
                      style: TextStyle(
                        color: BrandColors.alabaster.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _consultantCard(BuildContext context, Map<String, dynamic> astro) {
    return Container(
      width: 230,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.alabaster.withValues(alpha: 0.3),
            BrandColors.alabaster.withValues(alpha: 0.2),
            BrandColors.alabaster.withValues(alpha: 0.14),
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
            spreadRadius: 2,
          ),
          BoxShadow(
            color: BrandColors.goldAccent.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      BrandColors.ecstasy.withValues(alpha: 0.5),
                      BrandColors.persianRed.withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.ecstasy.withValues(alpha: 0.6),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      astro['image'] as String,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.ecstasy.withValues(alpha: 0.3),
                                BrandColors.persianRed.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.ecstasy.withValues(alpha: 0.3),
                                BrandColors.persianRed.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_rounded,
                            color: BrandColors.alabaster.withValues(alpha: 0.8),
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                astro['name'] as String,
                style: TextStyle(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      BrandColors.ecstasy,
                      BrandColors.persianRed,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.ecstasy.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  astro['specialty'] as String,
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (astro['rating'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.alabaster.withValues(alpha: 0.2),
                        BrandColors.alabaster.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: BrandColors.alabaster.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: BrandColors.ecstasy,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${astro['rating']}',
                        style: const TextStyle(
                          color: BrandColors.ecstasy,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 1,
                        height: 12,
                        color: BrandColors.alabaster.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          astro['experience'] ?? '',
                          style: const TextStyle(
                            color: BrandColors.alabaster,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (astro['price'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  astro['price'] as String,
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  BrandColors.ecstasy,
                  BrandColors.persianRed,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BrandColors.ecstasy.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: BrandColors.alabaster,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: BrandColors.alabaster,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chat Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: BrandColors.alabaster,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection(BuildContext context) {
    final odooState = context.watch<OdooState>();
    final bool hasOdooProducts = odooState.isAuthenticated && odooState.products.isNotEmpty;
    final sourceProducts = hasOdooProducts
        ? odooState.products
        : _products.map((p) => OdooProduct(
            id: -1,
            name: p['name']!,
            description: null,
            price: double.tryParse(p['price']!.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0.0,
          )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
          child:           Row(
            children: [
              Expanded(
                child: Text(
                  'Spiritual Store',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: BrandColors.codGrey.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(ShopScreenNew.route),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.alabaster.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BrandColors.alabaster.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
            scrollDirection: Axis.horizontal,
            itemCount: sourceProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final p = sourceProducts[i];
              // p may be OdooProduct or our fallback OdooProduct stub
              final name = p.name;
              final price = p.price > 0 ? '₹${p.price.toStringAsFixed(0)}' : '₹0';
              final image = p.imageUrl ?? 'assets/images/background.jpg';
              return _productCard(context, {'name': name, 'price': price, 'image': image});
            },
          ),
        ),
      ],
    );
  }

  Widget _productCard(BuildContext context, Map<String, String> p) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: (p['image']!.startsWith('assets/')
                  ? Image.asset(
                      p['image']!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return _productImageFallback(p);
                      },
                    )
                  : Image.network(
                      p['image']!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x4030012F),
                                Color(0x407E0562),
                                Color(0x20F9751E),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _productImageFallback(p);
                      },
                    )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name']!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      p['price']!,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImageFallback(Map<String, String> p) {
    IconData icon;
    final name = (p['name'] ?? '').toLowerCase();
    if (name.contains('bracelet')) {
      icon = Icons.link;
    } else if (name.contains('spray')) {
      icon = Icons.water_drop;
    } else if (name.contains('salt')) {
      icon = Icons.grain;
    } else if (name.contains('shop')) {
      icon = Icons.store;
    } else {
      icon = Icons.self_improvement;
    }
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8030012F), Color(0x807E0562), Color(0x40F9751E)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 8),
          Text(
            p['name'] ?? 'Product',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Consumer<CartState>(
      builder: (context, cart, child) {
        return Container(
          margin: const EdgeInsets.all(16),
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
                color: BrandColors.codGrey.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: BrandColors.goldAccent.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.alabaster.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: _bottomIndex,
                selectedItemColor: BrandColors.ecstasy,
                unselectedItemColor: BrandColors.alabaster.withValues(alpha: 0.7),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
            onTap: (i) {
              if (i == 4) {
                Navigator.of(context).pushNamed(ShopScreenNew.route);
              } else {
                setState(() => _bottomIndex = i);
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_rounded, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home, size: 28),
                ),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_rounded, size: 28),
                ),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.menu_book_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.menu_book_rounded, size: 28),
                ),
                label: 'E-learn',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.self_improvement_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.self_improvement_rounded, size: 28),
                ),
                label: 'Meditate',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Stack(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 26),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: BrandColors.persianRed,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${cart.itemCount > 99 ? "99+" : cart.itemCount}',
                              style: const TextStyle(
                                color: BrandColors.alabaster,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Stack(
                    children: [
                      const Icon(Icons.shopping_bag_rounded, size: 28),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: BrandColors.persianRed,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${cart.itemCount > 99 ? "99+" : cart.itemCount}',
                              style: const TextStyle(
                                color: BrandColors.alabaster,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                label: 'Shop',
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthState>();
    final displayName = auth.name?.trim().isNotEmpty == true ? auth.name! : 'Spiritual Seeker';
    final initials = displayName.split(' ').map((name) => name[0]).take(2).join();

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
              BrandColors.persianRed,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [BrandColors.ecstasy, BrandColors.persianRed],
                        ),
                        border: Border.all(color: BrandColors.alabaster.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.ecstasy.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: tt.titleLarge?.copyWith(
                            color: BrandColors.alabaster,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: tt.titleLarge?.copyWith(
                              color: BrandColors.alabaster,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Welcome to your spiritual journey',
                            style: tt.bodyMedium?.copyWith(
                              color: BrandColors.alabaster.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: BrandColors.alabaster.withValues(alpha: 0.3),
                thickness: 1,
                indent: 24,
                endIndent: 24,
              ),
              const SizedBox(height: 8),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.event_rounded,
                      title: 'Events',
                      subtitle: 'Upcoming spiritual events',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EventsScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.book_rounded,
                      title: 'Learning Resources',
                      subtitle: 'Spiritual guidance & knowledge',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to learning screen
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'My Appointments',
                      subtitle: 'Consultant bookings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my_appointments');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.favorite_rounded,
                      title: 'Favorites',
                      subtitle: 'Saved products & services',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to favorites screen
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Policies & Support',
                        style: tt.titleMedium?.copyWith(
                          color: BrandColors.alabaster.withValues(alpha: 0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.assignment_return_rounded,
                      title: 'Refund Policy',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RefundPolicyScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.local_shipping_rounded,
                      title: 'Shipping Policy',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShippingPolicyScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.bug_report_rounded,
                      title: 'Odoo Diagnostic',
                      subtitle: 'Check appointment configuration',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OdooDiagnosticScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance with your queries',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Contact us at support@houseofsheelaa.com'),
                            backgroundColor: BrandColors.ecstasy,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: BrandColors.alabaster,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      subtitle: 'Learn more about House of Sheelaa',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: BrandColors.jacaranda.withValues(alpha: 0.95),
                            title: Text(
                              'About House of Sheelaa',
                              style: tt.titleLarge?.copyWith(color: BrandColors.alabaster),
                            ),
                            content: Text(
                              'House of Sheelaa is a spiritual wellness platform offering consultations, products, and events to help you on your spiritual journey. We provide authentic spiritual guidance, healing services, and high-quality spiritual products.',
                              style: tt.bodyMedium?.copyWith(color: BrandColors.alabaster.withValues(alpha: 0.9)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: tt.labelLarge?.copyWith(color: BrandColors.ecstasy),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BrandColors.alabaster.withValues(alpha: 0.15),
                            BrandColors.alabaster.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.25),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.logout_rounded,
                          color: BrandColors.persianRed,
                        ),
                        title: Text(
                          'Sign Out',
                          style: tt.titleMedium?.copyWith(
                            color: BrandColors.alabaster,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          auth.logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/phone-login',
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2024 House of Sheelaa\nSpiritual Wellness & Guidance',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(
                        color: BrandColors.alabaster.withValues(alpha: 0.6),
                      ),
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final tt = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.ecstasy.withValues(alpha: 0.3),
                        BrandColors.persianRed.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: BrandColors.alabaster,
                    size: 20,
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
                          color: BrandColors.alabaster,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: BrandColors.alabaster.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: BrandColors.alabaster.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}


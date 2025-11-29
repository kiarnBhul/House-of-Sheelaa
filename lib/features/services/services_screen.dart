import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_state.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/features/services/service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  final String? initialCategory;
  const ServicesScreen({super.key, this.initialCategory});

  static const String route = '/services';

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchServices();
    });
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      debugPrint('Auto-refreshing services...');
      _fetchServices();
    });
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final odooState = Provider.of<OdooState>(context, listen: false);
      // Use loadServices to fetch services specifically and avoid conflict with products list
      await odooState.loadServices();
      _extractCategories();
    } catch (e) {
      debugPrint('Error fetching services: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _extractCategories() {
    final odooState = Provider.of<OdooState>(context, listen: false);
    
    // Debug: Print all services
    debugPrint('Total services fetched: ${odooState.services.length}');
    
    // Use services list directly
    final services = odooState.services;
    
    for (var s in services) {
      debugPrint('Service: ${s.name}, Category: ${s.categoryName}');
    }
    
    debugPrint('Total services to display: ${services.length}');
    
    final categories = <String>{'All'};
    for (var service in services) {
      if (service.categoryName != null && service.categoryName!.isNotEmpty) {
        categories.add(service.categoryName!);
      }
    }
    
    setState(() {
      _categories = categories.toList()..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });
      
      // Dispose old tab controller before creating new one
      if (_tabController.length != _categories.length) {
        _tabController.dispose();
        _tabController = TabController(length: _categories.length, vsync: this);
      }
      
      // Set initial tab if selected category exists
      final index = _categories.indexOf(_selectedCategory);
      if (index != -1 && index < _categories.length) {
        _tabController.animateTo(index);
      } else {
        _selectedCategory = 'All';
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final odooState = context.watch<OdooState>();
    // Use services list directly as it's already filtered and processed with categories
    final allServices = odooState.services;
    
    // Filter services based on selected category
    final displayedServices = _selectedCategory == 'All'
        ? allServices
        : allServices.where((s) => s.categoryName == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: BrandColors.jacaranda,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: BrandColors.ecstasy),
                  ),
                )
              else if (allServices.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_outlined, size: 64, color: BrandColors.alabaster.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No services found',
                          style: TextStyle(color: BrandColors.alabaster.withValues(alpha: 0.7), fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      _buildCategoryTabs(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchServices,
                          color: BrandColors.ecstasy,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: displayedServices.length,
                            itemBuilder: (context, index) {
                              return _buildServiceCard(context, displayedServices[index]);
                            },
                          ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: BrandColors.alabaster),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Services',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: BrandColors.alabaster),
            onPressed: _isLoading ? null : _fetchServices,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: BrandColors.alabaster),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: BrandColors.ecstasy,
        indicatorWeight: 3,
        labelColor: BrandColors.ecstasy,
        unselectedLabelColor: BrandColors.alabaster.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        onTap: (index) {
          setState(() {
            _selectedCategory = _categories[index];
          });
        },
        tabs: _categories.map((cat) => Tab(text: cat)).toList(),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, OdooService service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(),
            settings: RouteSettings(arguments: {
              'name': service.name,
              'subtitle': service.categoryName ?? '',
              'image': service.imageUrl ?? '',
              'subs': service.subServices?.map((s) => {
                    'name': s.name,
                    'image': s.imageUrl ?? '',
                    'price': s.price,
                    'priceMin': null,
                    'priceMax': null,
                    'durationMin': s.durationMinutes,
                  }).toList() ?? [],
            }),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: BrandColors.alabaster.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrandColors.alabaster.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: service.imageUrl != null
                    ? Image.network(
                        service.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: BrandColors.codGrey,
                            child: const Center(child: Icon(Icons.spa, color: BrandColors.alabaster)),
                          );
                        },
                      )
                    : Container(
                        color: BrandColors.codGrey,
                        child: const Center(child: Icon(Icons.spa, color: BrandColors.alabaster)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: BrandColors.ecstasy,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

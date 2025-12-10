import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_state.dart';
import 'package:provider/provider.dart';
import '../healing/healing_appointment_booking_screen.dart';
import '../healing/healing_purchase_screen.dart';

/// A detailed view screen for a healing/service item.
/// Shows service image, name, price, description, duration, and booking options.
class HealingDetailScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;
  final String? serviceImage;
  final double? price;
  final double? priceMin;
  final double? priceMax;
  final int? durationMinutes;
  final String? categoryName;

  const HealingDetailScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.serviceImage,
    this.price,
    this.priceMin,
    this.priceMax,
    this.durationMinutes,
    this.categoryName,
  });

  static const String route = '/healing_detail';

  @override
  State<HealingDetailScreen> createState() => _HealingDetailScreenState();
}

class _HealingDetailScreenState extends State<HealingDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OdooService? _serviceDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    final odooState = Provider.of<OdooState>(context, listen: false);
    
    try {
      // Try to find service in already loaded data
      OdooService? service;
      try {
        service = odooState.services.firstWhere((s) => s.id == widget.serviceId);
      } catch (_) {
        // Not found in services, check if it's a sub-service
        for (var s in odooState.services) {
          if (s.subServices != null) {
            for (var sub in s.subServices!) {
              if (sub.id == widget.serviceId) {
                // Found as sub-service, create a temporary OdooService from it
                service = OdooService(
                  id: sub.id,
                  name: sub.name,
                  description: s.description, // Use parent's description
                  price: sub.price ?? s.price,
                  categoryId: s.categoryId,
                  categoryName: s.categoryName,
                  imageUrl: sub.imageUrl ?? s.imageUrl,
                );
                break;
              }
            }
          }
          if (service != null) break;
        }
      }

      if (service == null) {
        // Try products as fallback
        try {
          final product = odooState.products.firstWhere((p) => p.id == widget.serviceId);
          service = OdooService(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            categoryId: product.categoryId,
            categoryName: product.categoryName,
            imageUrl: product.imageUrl,
          );
        } catch (_) {
          // Not found anywhere
        }
      }

      setState(() {
        _serviceDetails = service;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidImageUrl(String? u) {
    if (u == null || u.isEmpty) return false;
    final low = u.toLowerCase();
    if (!(low.startsWith('http') || low.startsWith('data:'))) return false;
    if (low.contains('unsplash.com')) return false;
    return true;
  }

  String _formatPrice() {
    if (widget.priceMin != null && widget.priceMax != null && widget.priceMin != widget.priceMax) {
      return '₹${widget.priceMin!.toStringAsFixed(0)} – ₹${widget.priceMax!.toStringAsFixed(0)}';
    } else if (widget.price != null && widget.price! > 0) {
      return '₹${widget.price!.toStringAsFixed(0)}';
    } else if (_serviceDetails?.price != null && _serviceDetails!.price > 0) {
      return '₹${_serviceDetails!.price.toStringAsFixed(0)}';
    }
    return 'Price on request';
  }

  Future<void> _handleBookAppointment() async {
    if (_serviceDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service details not available')),
      );
      return;
    }

    // Debug logging
    print('[HealingDetail] Service: ${_serviceDetails!.name}');
    print('[HealingDetail] hasAppointment: ${_serviceDetails!.hasAppointment}');
    print('[HealingDetail] appointmentTypeId: ${_serviceDetails!.appointmentTypeId}');
    print('[HealingDetail] appointmentLink: ${_serviceDetails!.appointmentLink}');

    // TEMPORARY FIX: For Healing category services, always show appointment booking
    final isHealingService = _serviceDetails!.categoryName?.toLowerCase().contains('healing') ?? false;
    
    // Check if service has appointment booking
    if ((_serviceDetails!.hasAppointment && _serviceDetails!.appointmentTypeId != null) || isHealingService) {
      // For testing: use a dummy appointment type ID if not set
      final appointmentTypeId = _serviceDetails!.appointmentTypeId ?? 1;
      
      print('[HealingDetail] Navigating to appointment screen with typeId: $appointmentTypeId');
      
      // Navigate to appointment booking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HealingAppointmentBookingScreen(
            service: _serviceDetails!,
            appointmentTypeId: appointmentTypeId,
          ),
        ),
      );
    } else {
      // Navigate to purchase/add to cart screen
      print('[HealingDetail] Navigating to purchase screen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HealingPurchaseScreen(
            service: _serviceDetails!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // Check if service has appointment available based on sub-services
    bool hasAppointment = false;
    OdooAppointmentType? appointment;
    
    // First check: service-level appointment flag
    if (_serviceDetails != null) {
      hasAppointment = _serviceDetails!.hasAppointment && _serviceDetails!.appointmentTypeId != null;
      
      // Second check: sub-services with appointments
      if (!hasAppointment && _serviceDetails!.subServices != null) {
        hasAppointment = _serviceDetails!.subServices!.any((sub) => sub.hasAppointment);
      }
    }
    
    // TEMPORARY: Always show appointment button for Healing category services
    final categoryName = widget.categoryName ?? _serviceDetails?.categoryName ?? '';
    if (categoryName.toLowerCase().contains('healing')) {
      hasAppointment = true;
      print('[HealingDetail] Forcing hasAppointment=true for Healing category: $categoryName');
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: BrandColors.alabaster),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.categoryName ?? 'Service Details',
                        style: tt.titleMedium?.copyWith(
                          color: BrandColors.alabaster,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: BrandColors.ecstasy))
                    : CustomScrollView(
                        slivers: [
                          // Hero Image
                          SliverToBoxAdapter(
                            child: Container(
                              height: 280,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFFFD85E),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _isValidImageUrl(widget.serviceImage)
                                        ? Image.network(
                                            widget.serviceImage!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (ctx, child, progress) {
                                              if (progress == null) return child;
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
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    color: BrandColors.ecstasy,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (ctx, error, stack) => _buildPlaceholderImage(),
                                          )
                                        : _buildPlaceholderImage(),
                                    // Gradient overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                          stops: const [0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                    // Title overlay
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      bottom: 20,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.serviceName,
                                            style: tt.headlineSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: BrandColors.ecstasy,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _formatPrice(),
                                                  style: tt.titleMedium?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (widget.durationMinutes != null) ...[
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: Colors.white54),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.timer, color: Colors.white, size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${widget.durationMinutes} min',
                                                        style: tt.bodyMedium?.copyWith(color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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

                          // Tabs
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: BrandColors.ecstasy,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: const EdgeInsets.all(4),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'About'),
                                  Tab(text: 'Details'),
                                  Tab(text: 'Reviews'),
                                ],
                              ),
                            ),
                          ),

                          // Tab Content
                          SliverFillRemaining(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // About Tab
                                  _buildAboutTab(tt),
                                  // Details Tab
                                  _buildDetailsTab(tt, hasAppointment, appointment),
                                  // Reviews Tab
                                  _buildReviewsTab(tt),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A051D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasAppointment ? BrandColors.ecstasy : const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: (hasAppointment ? BrandColors.ecstasy : const Color(0xFF25D366)).withOpacity(0.5),
                      ),
                      onPressed: _handleBookAppointment,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(hasAppointment ? Icons.calendar_today : Icons.shopping_cart, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            hasAppointment ? 'Book Appointment' : 'Purchase Now',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

  Widget _buildPlaceholderImage() {
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
      child: const Center(
        child: Icon(Icons.healing, size: 80, color: Colors.white54),
      ),
    );
  }

  Widget _buildAboutTab(TextTheme tt) {
    final description = _serviceDetails?.description;
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BrandColors.ecstasy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: BrandColors.ecstasy, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'About This Service',
                  style: tt.titleMedium?.copyWith(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description ?? 
              'This healing service is designed to help you achieve balance, harmony, and well-being. '
              'Our experienced practitioners use time-tested techniques to address your specific needs.\n\n'
              'Each session is personalized to ensure you receive the most effective treatment for your journey '
              'towards physical, emotional, and spiritual wellness.\n\n'
              'Contact us to learn more about how this service can benefit you.',
              style: tt.bodyLarge?.copyWith(
                color: BrandColors.alabaster.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(TextTheme tt, bool hasAppointment, OdooAppointmentType? appointment) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              tt,
              Icons.category,
              'Category',
              widget.categoryName ?? 'Healing',
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildDetailRow(
              tt,
              Icons.attach_money,
              'Price',
              _formatPrice(),
            ),
            if (widget.durationMinutes != null) ...[
              const Divider(color: Colors.white24, height: 32),
              _buildDetailRow(
                tt,
                Icons.timer,
                'Duration',
                '${widget.durationMinutes} minutes',
              ),
            ],
            if (hasAppointment && appointment != null) ...[
              if (appointment.duration != null) ...[
                const Divider(color: Colors.white24, height: 32),
                _buildDetailRow(
                  tt,
                  Icons.schedule,
                  'Session Duration',
                  '${appointment.duration} hours',
                ),
              ],
              if (appointment.location != null) ...[
                const Divider(color: Colors.white24, height: 32),
                _buildDetailRow(
                  tt,
                  Icons.location_on,
                  'Location',
                  appointment.location!,
                ),
              ],
            ],
            const Divider(color: Colors.white24, height: 32),
            _buildDetailRow(
              tt,
              hasAppointment ? Icons.event_available : Icons.shopping_bag,
              'Booking Type',
              hasAppointment ? 'Appointment Based' : 'Direct Purchase',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(TextTheme tt, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: BrandColors.ecstasy, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodySmall?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tt.titleSmall?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(TextTheme tt) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: BrandColors.ecstasy,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reviews Yet',
              style: tt.titleLarge?.copyWith(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share your experience\nwith this healing service!',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/core/models/review_model.dart';
import 'package:house_of_sheelaa/core/services/review_service.dart';
import 'package:house_of_sheelaa/features/auth/state/auth_state.dart';
import '../../theme/brand_theme.dart';
import '../../core/odoo/odoo_state.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';
import 'package:house_of_sheelaa/core/cart/cart_service.dart';
import '../store/state/cart_state.dart';
import '../store/models/product_model.dart';
import 'unified_appointment_booking_screen.dart';
import 'widgets/service_type_badge.dart';
import '../../core/odoo/odoo_api_service.dart';

/// Premium redesigned service detail page for healing/appointment services
/// Uses the brand color palette: Jacaranda, Cardinal Pink, Persian Red, Ecstasy, Alabaster, Cod Grey
class ServiceDetailPageNew extends StatefulWidget {
  final String serviceName;
  final int serviceId;
  final String? serviceImage;
  final double? price;
  final int? durationMinutes;
  final String? categoryName;
  final int? appointmentId;
  final String? appointmentLink;
  final bool hasAppointment;

  const ServiceDetailPageNew({
    super.key,
    required this.serviceName,
    required this.serviceId,
    this.serviceImage,
    this.price,
    this.durationMinutes,
    this.categoryName,
    this.appointmentId,
    this.appointmentLink,
    required this.hasAppointment,
  });

  @override
  State<ServiceDetailPageNew> createState() => _ServiceDetailPageNewState();
}

class _ServiceDetailPageNewState extends State<ServiceDetailPageNew>
    with SingleTickerProviderStateMixin {
  OdooService? _serviceDetails;
  bool _isLoading = true;
  int? _durationMinutes; // Resolved duration from widget or appointment type
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Product variant selection state
  List<OdooProductVariant> _variants = [];
  OdooProductVariant? _selectedVariant;
  bool _loadingVariants = false;
  int _quantity = 1; // Quantity selector
  String _attributeName = 'Select Option'; // Dynamic attribute name from Odoo

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServiceDetails();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    final odooState = Provider.of<OdooState>(context, listen: false);

    try {
      try {
        // Force fresh load with longer timeout to get updated appointment type data
        await Future.wait([
          odooState.ensureServicesFresh(force: true).timeout(const Duration(seconds: 10)),
          odooState
              .ensureAppointmentTypesFresh(force: true)
              .timeout(const Duration(seconds: 10)),
        ]);
        debugPrint('✅ Fresh data loaded successfully');
      } catch (e) {
        debugPrint('⚠️ Error loading fresh data: $e (continuing with cached)');
      }

      OdooService? service;

      if (odooState.services.isNotEmpty) {
        try {
          service =
              odooState.services.firstWhere((s) => s.id == widget.serviceId);
        } catch (_) {
          service = null;
        }
      }

      // Resolve duration: use widget.durationMinutes or fetch from appointment type
      int? resolvedDuration = widget.durationMinutes;
      if (resolvedDuration == null && widget.appointmentId != null) {
        try {
          final appointmentType = odooState.appointmentTypes.firstWhere(
            (apt) => apt.id == widget.appointmentId,
          );
          if (appointmentType.duration != null) {
            resolvedDuration = (appointmentType.duration! * 60).round();
            debugPrint('Fetched duration from appointment type: $resolvedDuration minutes');
          }
        } catch (e) {
          debugPrint('Could not find appointment type for duration: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _serviceDetails = service;
        _durationMinutes = resolvedDuration;
        _isLoading = false;
      });
      _animationController.forward();

      // Load product variants for non-appointment services
      if (!widget.hasAppointment) {
        _loadProductVariants();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
      debugPrint('Error loading service details: $e');
    }
  }

  Future<void> _loadProductVariants() async {
    if (_loadingVariants) return;
    
    setState(() {
      _loadingVariants = true;
    });

    try {
      final apiService = OdooApiService();
      final variants = await apiService.getProductVariants(widget.serviceId);
      
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _selectedVariant = variants.isNotEmpty ? variants.first : null;
        _loadingVariants = false;
        
        // Extract attribute name from first variant if available
        if (variants.isNotEmpty && variants.first.attributes.isNotEmpty) {
          _attributeName = variants.first.attributes.keys.first;
        }
      });

      if (kDebugMode) {
        debugPrint('[ServiceDetail] Loaded ${variants.length} variants');
        if (variants.isNotEmpty && variants.first.attributes.isNotEmpty) {
          debugPrint('[ServiceDetail] Attribute name: $_attributeName');
        }
      }
    } catch (e) {
      debugPrint('[ServiceDetail] Error loading variants: $e');
      if (!mounted) return;
      setState(() {
        _loadingVariants = false;
      });
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final low = url.toLowerCase();
    if (!(low.startsWith('http') || low.startsWith('data:'))) return false;
    if (low.contains('unsplash.com')) return false;
    return true;
  }

  String _formatPrice() {
    final price = _selectedVariant?.price ?? widget.price ?? 0.0;
    if (price > 0) {
      return '₹${price.toStringAsFixed(0)}';
    }
    return 'Price on request';
  }
  
  String _formatTotalPrice() {
    final price = _selectedVariant?.price ?? widget.price ?? 0.0;
    final total = price * _quantity;
    if (total > 0) {
      return '₹${total.toStringAsFixed(0)}';
    }
    return 'Price on request';
  }

  String _formatDuration() {
    if (_durationMinutes == null) return 'Duration varies';
    
    if (_durationMinutes! >= 60) {
      final hours = _durationMinutes! ~/ 60;
      final minutes = _durationMinutes! % 60;
      if (minutes == 0) {
        return '$hours ${hours == 1 ? "hour" : "hours"}';
      }
      return '$hours ${hours == 1 ? "hr" : "hrs"} $minutes min';
    }
    return '$_durationMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAppointmentId =
        widget.appointmentId ?? _serviceDetails?.appointmentTypeId;
    
    // CRITICAL LOGIC: If we have a valid appointmentId, show calendar!
    // The presence of appointmentId means this service is linked to an appointment type
    // Don't rely on hasAppointment flag when services API fails
    final effectiveHasAppointment = effectiveAppointmentId != null;

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📄 ServiceDetailPageNew Build');
    debugPrint('   Service: ${widget.serviceName} (ID: ${widget.serviceId})');
    debugPrint('   Widget hasAppointment: ${widget.hasAppointment}');
    debugPrint('   Widget appointmentId: ${widget.appointmentId}');
    debugPrint('   Loaded service hasAppointment: ${_serviceDetails?.hasAppointment}');
    debugPrint('   Effective appointmentId: $effectiveAppointmentId');
    debugPrint('   Effective hasAppointment: $effectiveHasAppointment');
    debugPrint('   Flow: ${effectiveHasAppointment ? "APPOINTMENT (Calendar)" : "PRODUCT (Cart)"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrandColors.jacaranda,
              Color(0xFF1A0119), // Darker shade for depth
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: effectiveHasAppointment
                    ? _buildAppointmentServiceDetail(effectiveAppointmentId)
                    : _buildProductServiceDetail(),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BrandColors.cardinalPink.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: BrandColors.ecstasy,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading service details...',
            style: TextStyle(
              color: BrandColors.alabaster.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentServiceDetail(int appointmentId) {
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero Section with Back Button
        SliverToBoxAdapter(
          child: _buildHeroSection(tt),
        ),

        // Service Details Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Quick Info Cards (Price & Duration)
                _buildQuickInfoCards(tt),
                const SizedBox(height: 28),

                // What You'll Get Section
                _buildBenefitsSection(tt),
                const SizedBox(height: 28),

                // Embedded Booking Widget
                _buildBookingSection(tt, appointmentId),
                const SizedBox(height: 28),

                // Contact Section
                _buildContactSection(tt),
                const SizedBox(height: 28),

                // Reviews Section
                _buildReviewsSection(tt),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(TextTheme tt) {
    return Stack(
      children: [
        // Background gradient with image overlay
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BrandColors.jacaranda,
                BrandColors.cardinalPink.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.ecstasy.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.cardinalPink.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Back button and title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildBackButton(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Details',
                            style: tt.bodyMedium?.copyWith(
                              color: BrandColors.alabaster.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.categoryName != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: BrandColors.ecstasy.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: BrandColors.ecstasy.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                widget.categoryName!,
                                style: tt.labelSmall?.copyWith(
                                  color: BrandColors.ecstasy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Service Image Circle
              _buildServiceImage(),

              const SizedBox(height: 16),

              // Service Name
              Text(
                widget.serviceName,
                style: tt.headlineSmall?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Service Type Badge
              Center(
                child: ServiceTypeBadge(
                  hasAppointment: widget.hasAppointment,
                  durationMinutes: _durationMinutes,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BrandColors.alabaster.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BrandColors.alabaster.withOpacity(0.2),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: BrandColors.alabaster,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildServiceImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.ecstasy.withOpacity(0.3),
            BrandColors.cardinalPink.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: BrandColors.goldAccent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.ecstasy.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: _isValidImageUrl(widget.serviceImage)
            ? Image.network(
                widget.serviceImage!,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: BrandColors.jacaranda,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: BrandColors.ecstasy,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, error, stack) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.cardinalPink.withOpacity(0.5),
            BrandColors.jacaranda,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.healing,
          color: BrandColors.alabaster,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildQuickInfoCards(TextTheme tt) {
    return Row(
      children: [
        // Price Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandColors.ecstasy.withOpacity(0.15),
                  BrandColors.ecstasy.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BrandColors.ecstasy.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BrandColors.ecstasy.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: BrandColors.ecstasy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Price',
                      style: tt.bodySmall?.copyWith(
                        color: BrandColors.alabaster.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatPrice(),
                  style: tt.titleLarge?.copyWith(
                    color: BrandColors.ecstasy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_quantity > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    '× $_quantity = ${_formatTotalPrice()}',
                    style: tt.bodyMedium?.copyWith(
                      color: BrandColors.ecstasy.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Duration Card - Always show for appointment services
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandColors.cardinalPink.withOpacity(0.15),
                  BrandColors.cardinalPink.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BrandColors.cardinalPink.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BrandColors.cardinalPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: BrandColors.cardinalPink,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Duration',
                      style: tt.bodySmall?.copyWith(
                        color: BrandColors.alabaster.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(),
                  style: tt.titleLarge?.copyWith(
                    color: BrandColors.cardinalPink,
                    fontWeight: FontWeight.bold,
                    fontSize: _durationMinutes != null && _durationMinutes! >= 60 ? 18 : 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(TextTheme tt) {
    final benefits = [
      {'icon': Icons.verified_user, 'text': 'Expert Consultation'},
      {'icon': Icons.auto_awesome, 'text': 'Personalized Healing'},
      {'icon': Icons.videocam, 'text': 'Online Sessions'},
      {'icon': Icons.schedule, 'text': 'Flexible Scheduling'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.ecstasy.withOpacity(0.2),
                    BrandColors.persianRed.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: BrandColors.ecstasy,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "What You'll Get",
              style: tt.titleMedium?.copyWith(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Benefits List
        ...benefits.asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.alabaster.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BrandColors.alabaster.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BrandColors.ecstasy,
                          BrandColors.persianRed,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.ecstasy.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      benefit['icon'] as IconData,
                      color: BrandColors.alabaster,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    benefit['text'] as String,
                    style: tt.bodyLarge?.copyWith(
                      color: BrandColors.alabaster.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingSection(TextTheme tt, int appointmentId) {
    // Get the correct product ID from appointment type
    final odooState = Provider.of<OdooState>(context, listen: false);
    int? correctProductId;
    
    try {
      final appointmentType = odooState.appointmentTypes.firstWhere(
        (apt) => apt.id == appointmentId,
      );
      correctProductId = appointmentType.productId;
      debugPrint('✓ Using appointment type productId: $correctProductId for appointment: $appointmentId');
    } catch (e) {
      // Fallback to widget.serviceId if appointment type not found
      correctProductId = widget.serviceId;
      debugPrint('⚠️ Appointment type not found, using widget.serviceId: $correctProductId');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.cardinalPink.withOpacity(0.2),
                    BrandColors.jacaranda.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: BrandColors.cardinalPink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Book Your Session',
              style: tt.titleMedium?.copyWith(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Embedded Booking Widget
        Container(
          decoration: BoxDecoration(
            color: BrandColors.alabaster,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: BrandColors.cardinalPink.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 680,
              child: UnifiedAppointmentBookingScreen(
                appointmentTypeId: appointmentId,
                serviceName: widget.serviceName,
                price: widget.price,
                serviceImage: widget.serviceImage,
                durationMinutes: widget.durationMinutes,
                productId: correctProductId ?? widget.serviceId,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.alabaster.withOpacity(0.08),
            BrandColors.alabaster.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BrandColors.alabaster.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrandColors.ecstasy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: BrandColors.ecstasy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Questions?',
                style: tt.titleMedium?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email
          _buildContactRow(
            icon: Icons.mail_outline_rounded,
            text: 'support@houseofsheelaa.com',
            tt: tt,
          ),
          const SizedBox(height: 16),

          // Phone
          _buildContactRow(
            icon: Icons.phone_outlined,
            text: '+91 98765 43210',
            tt: tt,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required TextTheme tt,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: BrandColors.ecstasy,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: tt.bodyMedium?.copyWith(
              color: BrandColors.alabaster.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Product-based service detail (non-appointment services)
  Widget _buildProductServiceDetail() {
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeroSection(tt),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildQuickInfoCards(tt),
                const SizedBox(height: 28),

                // Description
                if (_serviceDetails?.description != null &&
                    _serviceDetails!.description!.isNotEmpty) ...[
                  _buildDescriptionSection(tt),
                  const SizedBox(height: 28),
                ],

                // What's Included
                _buildIncludedSection(tt),
                const SizedBox(height: 28),

                // Product Variants Selector (show loading or variants)
                if (_loadingVariants || _variants.isNotEmpty) ...[
                  _buildVariantSelector(tt),
                  const SizedBox(height: 28),
                ],

                // Quantity Selector
                _buildQuantitySelector(tt),
                const SizedBox(height: 28),

                // CTA Buttons
                _buildProductCTAButtons(tt),
                const SizedBox(height: 28),

                // Contact
                _buildContactSection(tt),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BrandColors.cardinalPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: BrandColors.cardinalPink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'About This Service',
              style: tt.titleMedium?.copyWith(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BrandColors.alabaster.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BrandColors.alabaster.withOpacity(0.1),
            ),
          ),
          child: Text(
            _serviceDetails!.description!,
            style: tt.bodyMedium?.copyWith(
              color: BrandColors.alabaster.withOpacity(0.85),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedSection(TextTheme tt) {
    final included = [
      'Digital Service Access',
      'Professional Materials',
      'Email Support',
      'Certificate of Completion',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: BrandColors.ecstasy,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "What's Included",
              style: tt.titleMedium?.copyWith(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: included.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.ecstasy.withOpacity(0.15),
                    BrandColors.persianRed.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BrandColors.ecstasy.withOpacity(0.3),
                ),
              ),
              child: Text(
                item,
                style: tt.bodySmall?.copyWith(
                  color: BrandColors.ecstasy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.ecstasy.withOpacity(0.15),
            BrandColors.persianRed.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.alabaster.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BrandColors.ecstasy.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: BrandColors.ecstasy,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Quantity',
            style: tt.titleMedium?.copyWith(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: BrandColors.alabaster.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BrandColors.ecstasy.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: BrandColors.alabaster),
                  onPressed: _quantity > 1 ? () {
                    setState(() {
                      _quantity--;
                    });
                  } : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: tt.titleLarge?.copyWith(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: BrandColors.ecstasy),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.persianRed.withOpacity(0.15),
            BrandColors.cardinalPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.alabaster.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrandColors.ecstasy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: BrandColors.ecstasy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                _attributeName,
                style: tt.titleMedium?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Loading or Variant Dropdown
          if (_loadingVariants)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: BrandColors.alabaster.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BrandColors.ecstasy.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(BrandColors.ecstasy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading options...',
                    style: tt.bodyMedium?.copyWith(
                      color: BrandColors.alabaster.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else if (_variants.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: BrandColors.alabaster.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BrandColors.ecstasy.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BrandColors.ecstasy,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Standard option (no variants available)',
                      style: tt.bodyMedium?.copyWith(
                        color: BrandColors.alabaster.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: BrandColors.alabaster.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BrandColors.ecstasy.withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<OdooProductVariant>(
                  value: _selectedVariant,
                  isExpanded: true,
                  dropdownColor: BrandColors.jacaranda,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: BrandColors.ecstasy),
                  style: tt.bodyMedium?.copyWith(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _variants.map((variant) {
                    // Get the attribute value (e.g., "Without Feedback") instead of full display name
                    String displayText = variant.displayName ?? variant.name;
                    if (variant.attributes.isNotEmpty) {
                      displayText = variant.attributes.values.first;
                    }
                    
                    return DropdownMenuItem<OdooProductVariant>(
                      value: variant,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: tt.bodyMedium?.copyWith(
                                color: BrandColors.alabaster,
                              ),
                            ),
                          ),
                          Text(
                            '₹${variant.price.toStringAsFixed(0)}',
                            style: tt.bodySmall?.copyWith(
                              color: BrandColors.ecstasy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (OdooProductVariant? newValue) {
                    setState(() {
                      _selectedVariant = newValue;
                    });
                  },
                ),
              ),
            ),
          
          // Show attributes if available
          if (_selectedVariant != null && _selectedVariant!.attributes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedVariant!.attributes.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrandColors.ecstasy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: BrandColors.ecstasy.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: tt.labelSmall?.copyWith(
                      color: BrandColors.ecstasy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCTAButtons(TextTheme tt) {
    final cart = context.watch<CartState>();
    final isInCart = cart.isInCart(widget.serviceId.toString());

    return Column(
      children: [
        // Add to Cart / View Cart Button (Primary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isInCart ? _navigateToCart : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInCart ? BrandColors.cardinalPink : BrandColors.ecstasy,
              foregroundColor: BrandColors.alabaster,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: (isInCart ? BrandColors.cardinalPink : BrandColors.ecstasy).withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isInCart ? Icons.shopping_bag_rounded : Icons.shopping_cart_rounded,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  isInCart ? 'View Cart' : 'Add to Cart - ${_formatTotalPrice()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onBookNow() {
    // Navigate to booking step 1 with service details
    Navigator.of(context).pushNamed(
      '/booking_step1_select_consultant',
      arguments: {
        'appointmentTypeId': widget.appointmentId ?? 0,
        'serviceName': widget.serviceName,
        'price': widget.price ?? 0.0,
        'serviceImage': widget.serviceImage,
        'durationMinutes': widget.durationMinutes ?? 30,
        'productId': widget.serviceId,
      },
    );
  }

  Widget _buildReviewsSection(TextTheme tt) {
    // If no service name provided (shouldn't happen), don't show reviews
    if (widget.serviceName.isEmpty) return const SizedBox.shrink();

    final reviewService = ReviewService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BrandColors.ecstasy, BrandColors.cardinalPink],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: BrandColors.alabaster,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Reviews',
                  style: tt.titleMedium?.copyWith(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // Add Review Button
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context),
              icon: const Icon(Icons.edit, size: 16, color: BrandColors.ecstasy),
              label: Text(
                'Write Review',
                style: tt.labelLarge?.copyWith(
                  color: BrandColors.ecstasy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: BrandColors.ecstasy.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        StreamBuilder<List<ReviewModel>>(
          stream: reviewService.getReviews(widget.serviceName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: BrandColors.ecstasy),
                ),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Could not load reviews.',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: tt.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to share your experience!',
                      style: tt.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: BrandColors.ecstasy.withOpacity(0.2),
                            child: Text(
                              review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: BrandColors.ecstasy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName,
                                  style: tt.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 14,
                                      color: BrandColors.goldAccent,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(review.createdAt),
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      if (review.comment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          review.comment,
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Basic formatting without intl dependency if preferred, or use intl
    // Using simple logic for now
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddReviewDialog(BuildContext context) {
    final commentController = TextEditingController();
    double rating = 5.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: BrandColors.codGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: const Text(
                'Write a Review',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: BrandColors.goldAccent,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Comment',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            // Optionally show error
                            return;
                          }

                          setState(() => isSubmitting = true);

                          try {
                            final auth = context.read<AuthState>();
                            final fname = auth.firstName ?? '';
                            final lname = auth.lastName ?? '';
                            String userName = auth.name?.trim() ?? '';
                            if (userName.isEmpty) {
                              userName = [fname, lname].where((e) => e.trim().isNotEmpty).join(' ').trim();
                            }
                            if (userName.isEmpty) {
                              userName = 'Anonymous User';
                            }

                            final review = ReviewModel(
                              id: '', // Generated by service
                              userName: userName,
                              rating: rating,
                              comment: commentController.text.trim(),
                              createdAt: DateTime.now(),
                              userId: auth.userId,
                            );

                            await ReviewService().addReview(widget.serviceName, review);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review submitted successfully!'),
                                  backgroundColor: BrandColors.ecstasy,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.ecstasy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Add service to cart
  Future<void> _addToCart() async {
    final cart = Provider.of<CartState>(context, listen: false);
    
    // Convert OdooService to Product for cart compatibility
    final product = Product(
      id: (_selectedVariant?.id ?? widget.serviceId).toString(),
      name: _selectedVariant?.displayName ?? widget.serviceName,
      subtitle: widget.categoryName ?? '',
      description: _serviceDetails?.description ?? '',
      price: '₹${(_selectedVariant?.price ?? widget.price ?? 0.0).toStringAsFixed(0)}',
      priceValue: (_selectedVariant?.price ?? widget.price ?? 0.0).toInt(),
      image: widget.serviceImage ?? '',
      category: widget.categoryName ?? 'Services',
      benefits: [],
    );
    
    // Add multiple times based on quantity
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(product);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${widget.serviceName} added to cart'),
            ),
          ],
        ),
        backgroundColor: BrandColors.cardinalPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: BrandColors.ecstasy,
          onPressed: _navigateToCart,
        ),
      ),
    );

    setState(() {}); // Refresh to show "View Cart" button
  }

  /// Navigate to cart screen
  void _navigateToCart() {
    Navigator.pushNamed(context, '/cart');
  }

  /// Get or create Odoo partner for the user
  Future<int?> _getOrCreatePartner(AuthState authState) async {
    try {
      final apiService = OdooApiService();
      
      // Use email or phone to find/create partner
      final email = authState.email ?? '';
      final phone = authState.phone ?? '';
      final name = authState.name ?? authState.firstName ?? 'Customer';
      
      if (email.isEmpty && phone.isEmpty) {
        return null;
      }
      
      // Try to find existing partner
      List<List<dynamic>> domain = [];
      if (email.isNotEmpty) {
        domain.add(['email', '=', email]);
      } else if (phone.isNotEmpty) {
        domain.add(['phone', '=', phone]);
      }
      
      final partners = await apiService.searchRead(
        model: 'res.partner',
        domain: domain,
        fields: ['id'],
        limit: 1,
      );
      
      if (partners.isNotEmpty) {
        return partners.first['id'] as int;
      }
      
      // Create new partner
      final created = await apiService.executeRpc(
        model: 'res.partner',
        method: 'create',
        args: [
          {
            'name': name,
            if (email.isNotEmpty) 'email': email,
            if (phone.isNotEmpty) 'phone': phone,
          }
        ],
      );
      
      if (created is int) {
        return created;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ServiceDetail] Failed to get/create partner: $e');
      }
      return null;
    }
  }


}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/brand_theme.dart';
import '../../core/models/odoo_models.dart';
import '../../core/odoo/odoo_api_service.dart';
import '../auth/state/auth_state.dart';

/// Unified appointment booking screen showing calendar, time slots, consultant selection,
/// and service details all in a single view as per design screenshot.
///
/// **IMPORTANT**: This screen is designed specifically for HEALING CATEGORY services only.
/// Other service categories (Numerology, Card Reading, Rituals, etc.) will have their own
/// unique booking workflows and should NOT use this unified booking screen.
///
/// This design provides:
/// - Calendar grid with month navigation
/// - Time slot chips with real-time availability
/// - Consultant selection (when multiple consultants available)
/// - Service details with price/duration
/// - Single-screen UX for fast, clear booking experience
class UnifiedAppointmentBookingScreen extends StatefulWidget {
  final int appointmentTypeId;
  final String serviceName;
  final double? price;
  final String? serviceImage;
  final int? durationMinutes;
  final int? productId;

  const UnifiedAppointmentBookingScreen({
    super.key,
    required this.appointmentTypeId,
    required this.serviceName,
    this.price,
    this.serviceImage,
    this.durationMinutes,
    this.productId,
  });

  static const String route = '/unified_appointment_booking';

  @override
  State<UnifiedAppointmentBookingScreen> createState() =>
      _UnifiedAppointmentBookingScreenState();
}

class _UnifiedAppointmentBookingScreenState
    extends State<UnifiedAppointmentBookingScreen> {
  final OdooApiService _apiService = OdooApiService();
  bool _isDisposed = false;

  // Loading and error states
  bool _isLoading = false;
  bool _isSlotsLoading = false;
  String? _errorMessage;

  // Slots caching and debounce
  final Map<String, List<OdooAppointmentSlot>> _slotCache = {};
  final Map<String, DateTime> _slotCacheTimestamps = {};
  final Duration _slotCacheTtl = const Duration(minutes: 10);
  Timer? _slotDebounce;

  // Data
  List<OdooStaff> _staffMembers = [];
  List<OdooAppointmentSlot> _availableSlots = [];

  // Selected values
  DateTime _selectedDate = DateTime.now();
  OdooAppointmentSlot? _selectedSlot;
  int? _selectedStaffId;
  String _selectedTimezone = 'Asia/Kolkata';

  static const List<String> _timezones = ['Asia/Kolkata', 'UTC'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _slotDebounce?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  Future<void> _loadInitialData() async {
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load staff members
      await _loadStaffMembers();

      // Load slots for today
      await _loadAvailableSlots();

      // ⚡ OPTIMIZATION: Pre-cache upcoming 7 days in background
      _preCacheUpcomingDates();

      if (!_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _errorMessage = 'Failed to load booking data: $e';
        _isLoading = false;
      });
    }
  }
  
  /// ⚡ Pre-cache slots for next 7 days for instant loading
  void _preCacheUpcomingDates() {
    Future.delayed(Duration.zero, () async {
      try {
        final upcomingDates = List.generate(7, (index) {
          return DateTime.now().add(Duration(days: index + 1));
        });
        
        for (final date in upcomingDates) {
          if (_isDisposed) break;
          
          // Pre-cache for selected staff (if any)
          try {
            await _apiService.getAppointmentSlots(
              appointmentTypeId: widget.appointmentTypeId,
              date: date,
              staffId: _selectedStaffId,
            );
            
            // Add small delay to avoid overwhelming the server
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            // Silently fail for background caching
            debugPrint('Pre-cache failed for $date: $e');
          }
        }
        debugPrint('⚡ Pre-caching complete for ${upcomingDates.length} upcoming dates');
      } catch (e) {
        debugPrint('Pre-cache error: $e');
      }
    });
  }

  Future<void> _loadStaffMembers() async {
    try {
      final staff = await _apiService.getAppointmentStaff(widget.appointmentTypeId);
      if (_isDisposed) return;
      _safeSetState(() {
        _staffMembers = staff;
        // Auto-select first staff if only one available
        if (staff.length == 1) {
          _selectedStaffId = staff.first.id;
        }
      });
    } catch (e) {
      debugPrint('Failed to load staff: $e');
      if (!_isDisposed) {
        _safeSetState(() {
          _errorMessage = 'Failed to load consultants';
        });
      }
    }
  }

  String _slotCacheKey(DateTime date, int? staffId) {
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    return '$dayKey:${staffId ?? 0}';
  }

  Future<void> _loadAvailableSlots() async {
    if (widget.appointmentTypeId <= 0) return;

    final cacheKey = _slotCacheKey(_selectedDate, _selectedStaffId);
    final cachedSlots = _slotCache[cacheKey];
    final cacheStamp = _slotCacheTimestamps[cacheKey];
    final isCacheFresh = cacheStamp != null && DateTime.now().difference(cacheStamp) < _slotCacheTtl;

    // If we have fresh cache, show it immediately (optimistic UI)
    if (cachedSlots != null && isCacheFresh) {
      _safeSetState(() {
        _availableSlots = cachedSlots;
        _selectedSlot = null;
        _isSlotsLoading = false;
        _errorMessage = cachedSlots.isEmpty ? 'No available slots for this date' : null;
      });
    } else {
      _safeSetState(() {
        _isSlotsLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final slots = await _apiService.getAppointmentSlots(
        appointmentTypeId: widget.appointmentTypeId,
        date: _selectedDate,
        staffId: _selectedStaffId,
      );

      if (_isDisposed) return;
      _safeSetState(() {
        _availableSlots = slots;
        _selectedSlot = null;
        _isSlotsLoading = false;

        // Cache the result
        _slotCache[cacheKey] = slots;
        _slotCacheTimestamps[cacheKey] = DateTime.now();

        if (slots.isEmpty) {
          _errorMessage = 'No available slots for this date';
        }
      });
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _availableSlots = [];
        _selectedSlot = null;
        _isSlotsLoading = false;
        _errorMessage = 'Failed to load available slots: $e';
      });
    }
  }

  void _onDateSelected(DateTime date) {
    _safeSetState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    _debouncedLoadSlots();
  }

  void _onStaffSelected(int staffId) {
    _safeSetState(() {
      _selectedStaffId = staffId;
      _selectedSlot = null;
    });
    _debouncedLoadSlots();
  }

  void _debouncedLoadSlots() {
    _slotDebounce?.cancel();
    _slotDebounce = Timer(const Duration(milliseconds: 50), _loadAvailableSlots); // Reduced from 120ms to 50ms for faster response
  }

  void _onSlotSelected(OdooAppointmentSlot slot) {
    _safeSetState(() {
      _selectedSlot = slot;
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time'),
          backgroundColor: BrandColors.persianRed,
        ),
      );
      return;
    }

    if (_staffMembers.isNotEmpty && _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a consultant'),
          backgroundColor: BrandColors.persianRed,
        ),
      );
      return;
    }

    // Navigate to review/checkout page instead of directly confirming
    // Find the selected consultant object
    OdooStaff? selectedConsultant;
    if (_selectedStaffId != null) {
      try {
        selectedConsultant = _staffMembers.firstWhere(
          (staff) => staff.id == _selectedStaffId,
        );
      } catch (e) {
        // If not found, create a basic staff object
        selectedConsultant = OdooStaff(
          id: _selectedStaffId!,
          name: 'Consultant',
        );
      }
    } else if (_staffMembers.isNotEmpty) {
      selectedConsultant = _staffMembers.first;
    } else {
      // No consultant - create default
      selectedConsultant = OdooStaff(
        id: _selectedSlot!.staffId,
        name: _selectedSlot!.staffName ?? 'Consultant',
      );
    }

    // Navigate to Step 2: Review Details
    Navigator.of(context).pushNamed(
      '/booking_step2_review',
      arguments: {
        'appointmentTypeId': widget.appointmentTypeId,
        'serviceName': widget.serviceName,
        'price': widget.price ?? 0.0,
        'serviceImage': widget.serviceImage,
        'durationMinutes': widget.durationMinutes ?? 30,
        'productId': widget.productId ?? 0,
        'selectedConsultant': selectedConsultant,
        'selectedSlot': _selectedSlot!,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: BrandColors.jacaranda,
      body: Stack(
        children: [
          // Dark gradient backdrop matching the app theme
          Container(
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
          ),
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    BrandColors.ecstasy.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.cardinalPink.withOpacity(0.2),
                                BrandColors.ecstasy.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CircularProgressIndicator(
                            color: BrandColors.cardinalPink,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your booking...',
                          style: tt.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeader(tt, size),
                        const SizedBox(height: 20),
                        if (_errorMessage != null && _selectedSlot == null)
                          _buildErrorWidget(tt),
                        _buildServiceInfoCard(tt),
                        const SizedBox(height: 20),
                        if (_staffMembers.isNotEmpty)
                          _buildConsultantDropdown(tt),
                        const SizedBox(height: 20),
                        _buildCalendarSection(tt),
                        const SizedBox(height: 20),
                        _buildTimeSlotsSection(tt),
                        const SizedBox(height: 20),
                        if (_selectedSlot != null)
                          _buildBookingSummaryCard(tt),
                        const SizedBox(height: 24),
                        _buildConfirmButton(tt),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds the hero header block with back button, title, and service name
  Widget _buildHeroHeader(TextTheme tt, Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      // Removed specific decoration to blend with main background
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Appointment',
                  style: tt.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.serviceName,
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the consultant dropdown selector styled as a card
  Widget _buildConsultantDropdown(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: BrandColors.ecstasy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Select Consultant',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedStaffId,
              isExpanded: true,
              dropdownColor: BrandColors.jacaranda,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              items: _staffMembers.map((staff) {
                return DropdownMenuItem<int>(
                  value: staff.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: BrandColors.cardinalPink.withOpacity(0.15),
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0] : '?',
                          style: tt.titleSmall?.copyWith(
                            color: BrandColors.cardinalPink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          staff.name,
                          style: tt.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) _onStaffSelected(id);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(TextTheme tt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.persianRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.persianRed.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.persianRed.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrandColors.persianRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: BrandColors.persianRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _errorMessage!,
              style: tt.bodyMedium?.copyWith(
                color: BrandColors.persianRed,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  BrandColors.cardinalPink.withOpacity(0.15),
                  BrandColors.ecstasy.withOpacity(0.15),
                ],
              ),
            ),
            child: Icon(
              Icons.healing_rounded,
              color: BrandColors.cardinalPink,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceName,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.price != null) ...[
                      Text(
                        '₹${widget.price!.toStringAsFixed(0)}',
                        style: tt.labelSmall?.copyWith(
                          color: BrandColors.ecstasy,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.durationMinutes != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.durationMinutes} min',
                                style: tt.labelSmall?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else if (widget.durationMinutes != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.durationMinutes} min',
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConsultantSection(TextTheme tt) {
    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BrandColors.jacaranda.withOpacity(0.1),
                  BrandColors.ecstasy.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: BrandColors.jacaranda,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Choose Your Consultant',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BrandColors.codGrey,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _staffMembers.map((staff) {
          final isSelected = _selectedStaffId == staff.id;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => _onStaffSelected(staff.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BrandColors.cardinalPink,
                            BrandColors.persianRed,
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BrandColors.alabaster.withOpacity(0.95),
                            BrandColors.alabaster.withOpacity(0.85),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? BrandColors.ecstasy.withOpacity(0.5)
                        : BrandColors.cardinalPink.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? BrandColors.cardinalPink.withOpacity(0.3)
                          : BrandColors.codGrey.withOpacity(0.08),
                      blurRadius: isSelected ? 16 : 8,
                      offset: Offset(0, isSelected ? 6 : 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.15),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  BrandColors.cardinalPink.withOpacity(0.15),
                                  BrandColors.ecstasy.withOpacity(0.15),
                                ],
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: isSelected
                            ? BrandColors.alabaster
                            : BrandColors.cardinalPink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        staff.name,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected ? BrandColors.alabaster : BrandColors.codGrey,
                          letterSpacing: 0.3,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: BrandColors.alabaster,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 28),
    ];
  }

  Widget _buildCalendarSection(TextTheme tt) {
    final selected = _selectedDate;
    final monthStart = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final leading = monthStart.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: BrandColors.ecstasy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Select Date',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Calendar grid - transparent background blending with page
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Month Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.cardinalPink.withOpacity(0.1),
                          BrandColors.ecstasy.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: BrandColors.cardinalPink),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final prev = DateTime(selected.year, selected.month - 1, 1);
                        if (!prev.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                          _onDateSelected(prev);
                        }
                      },
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(selected),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.cardinalPink.withOpacity(0.1),
                          BrandColors.ecstasy.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, color: BrandColors.cardinalPink),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final next = DateTime(selected.year, selected.month + 1, 1);
                        _onDateSelected(next);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekday labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.2,
                ),
                itemCount: leading + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leading) return const SizedBox.shrink();
                  
                  final day = index - leading + 1;
                  final date = DateTime(selected.year, selected.month, day);
                  final isSelected = DateUtils.isSameDay(_selectedDate, date);
                  final isToday = DateUtils.isSameDay(DateTime.now(), date);
                  final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

                  return GestureDetector(
                    onTap: isPast ? null : () => _onDateSelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BrandColors.cardinalPink,
                                  BrandColors.persianRed,
                                ],
                              )
                            : (isToday && !isPast)
                                ? LinearGradient(
                                    colors: [
                                      BrandColors.ecstasy.withOpacity(0.2),
                                      BrandColors.ecstasy.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                        color: (!isSelected && !isToday) 
                            ? (isPast ? Colors.transparent : Colors.white.withOpacity(0.1))
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : (isToday && !isPast)
                                  ? BrandColors.ecstasy.withOpacity(0.5)
                                  : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: BrandColors.cardinalPink.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : isPast
                                    ? Colors.white30
                                    : Colors.white,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
                color: BrandColors.ecstasy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Select Time Slot',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: BrandColors.codGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isSlotsLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: BrandColors.ecstasy,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading available slots...',
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: BrandColors.persianRed.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.persianRed.withOpacity(0.2),
                        BrandColors.persianRed.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    color: BrandColors.persianRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Slots Available',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Try another date or consultant',
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedSlot == slot;
              final timeStr = DateFormat('h:mm a').format(slot.startTime);

              return GestureDetector(
                onTap: () => _onSlotSelected(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BrandColors.cardinalPink,
                              BrandColors.persianRed,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? BrandColors.cardinalPink.withOpacity(0.3)
                            : Colors.transparent,
                        blurRadius: isSelected ? 12 : 0,
                        offset: Offset(0, isSelected ? 4 : 0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: isSelected 
                              ? Colors.white 
                              : Colors.white70,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeStr,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected 
                                ? Colors.white 
                                : Colors.white70,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTimezoneSection(TextTheme tt) {
    return Row(
      children: [
        Text(
          'Timezone:',
          style: tt.bodyMedium?.copyWith(
            color: BrandColors.codGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedTimezone,
            isExpanded: true,
            items: _timezones
                .map((tz) => DropdownMenuItem(
                      value: tz,
                      child: Text(tz),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                _safeSetState(() => _selectedTimezone = val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummaryCard(TextTheme tt) {
    if (_selectedSlot == null) return const SizedBox.shrink();

    final selectedStaffName = _staffMembers.isNotEmpty
        ? _staffMembers
            .firstWhere(
              (s) => s.id == (_selectedStaffId ?? _selectedSlot!.staffId),
              orElse: () => _staffMembers.first,
            )
            .name
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.ecstasy.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BrandColors.ecstasy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: BrandColors.ecstasy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Session',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            tt,
            icon: Icons.event,
            label: 'Date',
            value: DateFormat('MMM dd').format(_selectedDate),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            tt,
            icon: Icons.access_time,
            label: 'Time',
            value: DateFormat('h:mm a').format(_selectedSlot!.startTime),
          ),
          if (_staffMembers.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              tt,
              icon: Icons.person,
              label: 'Consultant',
              value: selectedStaffName,
            ),
          ],
          if (widget.price != null) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              tt,
              icon: Icons.currency_rupee,
              label: 'Amount',
              value: '₹${widget.price!.toStringAsFixed(0)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    TextTheme tt, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: tt.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(TextTheme tt) {
    final isEnabled = _selectedSlot != null && !_isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? BrandColors.ecstasy : Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnabled ? 4 : 0,
        ),
        onPressed: isEnabled ? _confirmBooking : null,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Proceed to Checkout',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

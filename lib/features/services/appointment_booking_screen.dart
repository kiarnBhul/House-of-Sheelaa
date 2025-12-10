import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_api_service.dart';

/// Screen for booking appointments with calendar and time slot selection
class AppointmentBookingScreen extends StatefulWidget {
  final int appointmentTypeId;
  final String appointmentName;
  final String? serviceImage;
  final double? price;
  final double? durationHours;
  final String? location;
  final int? productId;

  const AppointmentBookingScreen({
    super.key,
    required this.appointmentTypeId,
    required this.appointmentName,
    this.serviceImage,
    this.price,
    this.durationHours,
    this.location,
    this.productId,
  });

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _apiService = OdooApiService();
  bool _isDisposed = false;
  
  // State
  bool _isLoadingStaff = true;
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  List<OdooStaff> _staff = [];
  OdooStaff? _selectedStaff;
  DateTime _selectedDate = DateTime.now();
  List<OdooAppointmentSlot> _availableSlots = [];
  OdooAppointmentSlot? _selectedSlot;
  String? _error;

  // Customer form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  Future<void> _loadStaff() async {
    _safeSetState(() {
      _isLoadingStaff = true;
      _error = null;
    });

    try {
      final staff = await _apiService.getAppointmentStaff(widget.appointmentTypeId);
      if (_isDisposed) return;
      _safeSetState(() {
        _staff = staff;
        if (staff.isNotEmpty) {
          _selectedStaff = staff.first;
          _loadSlots();
        }
        _isLoadingStaff = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _error = 'Failed to load consultants: $e';
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedStaff == null) return;

    _safeSetState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final slots = await _apiService.getAppointmentSlots(
        appointmentTypeId: widget.appointmentTypeId,
        date: _selectedDate,
        staffId: _selectedStaff!.id,
      );
      if (_isDisposed) return;
      _safeSetState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _error = 'Failed to load available slots';
        _isLoadingSlots = false;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    _safeSetState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    _loadSlots();
  }

  void _onStaffSelected(OdooStaff? staff) {
    _safeSetState(() {
      _selectedStaff = staff;
      _selectedSlot = null;
    });
    _loadSlots();
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _safeSetState(() => _isBooking = true);

    try {
      final result = await _apiService.createAppointmentBooking(
        appointmentTypeId: widget.appointmentTypeId,
        dateTime: _selectedSlot!.startTime,
        staffId: _selectedStaff!.id,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        productId: widget.productId,
        price: widget.price,
      );

      if (!_isDisposed) _safeSetState(() => _isBooking = false);

      if (result != null && result['error'] == null) {
        if (mounted) {
          _showBookingConfirmation();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking failed: ${result?['error'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed) _safeSetState(() => _isBooking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A051D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Appointment Booked!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.appointmentName}\n'
              '${_formatFullDate(_selectedSlot!.startTime)}\n'
              '${_selectedSlot!.formattedTime}\n'
              'with ${_selectedStaff?.name ?? "Consultant"}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'A confirmation email will be sent to ${_emailController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done', style: TextStyle(color: BrandColors.ecstasy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.jacaranda, BrandColors.cardinalPink],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Book Appointment',
                        style: tt.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoadingStaff
                    ? const Center(child: CircularProgressIndicator(color: BrandColors.ecstasy))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Info Card
                            _buildServiceCard(tt),
                            const SizedBox(height: 24),

                            // Consultant Selection
                            if (_staff.isNotEmpty) ...[
                              _buildSectionTitle(tt, Icons.person, 'Select Consultant'),
                              const SizedBox(height: 12),
                              _buildStaffSelector(tt),
                              const SizedBox(height: 24),
                            ],

                            // Calendar
                            _buildSectionTitle(tt, Icons.calendar_today, 'Select Date'),
                            const SizedBox(height: 12),
                            _buildCalendar(tt),
                            const SizedBox(height: 24),

                            // Time Slots
                            _buildSectionTitle(tt, Icons.access_time, 'Available Time Slots'),
                            const SizedBox(height: 12),
                            _buildTimeSlots(tt),
                            const SizedBox(height: 24),

                            // Customer Details Form
                            _buildSectionTitle(tt, Icons.person_outline, 'Your Details'),
                            const SizedBox(height: 12),
                            _buildCustomerForm(tt),
                            const SizedBox(height: 100), // Space for button
                          ],
                        ),
                      ),
              ),

              // Book Button
              if (!_isLoadingStaff)
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
                          backgroundColor: _selectedSlot != null 
                              ? BrandColors.ecstasy 
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _selectedSlot != null && !_isBooking
                            ? _bookAppointment
                            : null,
                        child: _isBooking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedSlot != null
                                    ? 'Confirm Booking'
                                    : 'Select a Time Slot',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildServiceCard(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD85E).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD85E), width: 2),
              image: widget.serviceImage != null
                  ? DecorationImage(
                      image: NetworkImage(widget.serviceImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: widget.serviceImage == null ? const Color(0xFF30012F) : null,
            ),
            child: widget.serviceImage == null
                ? const Icon(Icons.healing, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointmentName,
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.price != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrandColors.ecstasy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${widget.price!.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.durationHours != null)
                      Text(
                        '${(widget.durationHours! * 60).round()} min',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                  ],
                ),
                if (widget.location != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          widget.location!,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme tt, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: BrandColors.ecstasy, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSelector(TextTheme tt) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final staff = _staff[index];
          final isSelected = _selectedStaff?.id == staff.id;

          return GestureDetector(
            onTap: () => _onStaffSelected(staff),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? BrandColors.ecstasy.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? BrandColors.ecstasy : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF30012F),
                    backgroundImage: staff.imageUrl != null
                        ? NetworkImage(staff.imageUrl!)
                        : null,
                    child: staff.imageUrl == null
                        ? Text(
                            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    staff.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Date formatting helpers
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdaysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsFull = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String _formatWeekday(DateTime date) => _weekdays[date.weekday - 1];
  String _formatMonth(DateTime date) => _months[date.month - 1];
  String _formatFullDate(DateTime date) {
    return '${_weekdaysFull[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Current month for calendar navigation
  DateTime _currentMonth = DateTime.now();

  Widget _buildCalendar(TextTheme tt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get first day of the current display month
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Get the weekday of the first day (0 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sun-Sat)
    
    // Calculate total cells needed (previous month days + current month days)
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7; // Round up to complete weeks
    
    // Days of week headers
    const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          // Month/Year header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_monthsFull[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) => SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 0,
              childAspectRatio: 1.2,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              // Calculate the date for this cell
              final dayOffset = index - firstWeekday;
              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayOffset + 1);
              
              // Check if this date is in the current month
              final isCurrentMonth = cellDate.month == _currentMonth.month && 
                                     cellDate.year == _currentMonth.year;
              
              // Check if this is a past date (before today)
              final isPast = cellDate.isBefore(today);
              
              // Check if this date is selected
              final isSelected = _selectedDate.year == cellDate.year &&
                  _selectedDate.month == cellDate.month &&
                  _selectedDate.day == cellDate.day;
              
              // Check if this is today
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              
              // Only show dates within a reasonable range
              if (!isCurrentMonth) {
                return const SizedBox();
              }
              
              // Determine if the date is selectable
              final isSelectable = !isPast || isToday;
              
              return GestureDetector(
                onTap: isSelectable ? () => _onDateSelected(cellDate) : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE85A4F), Color(0xFFFF8E53)],
                          )
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cellDate.day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isPast && !isToday
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(TextTheme tt) {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: BrandColors.ecstasy),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No available slots for this date',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try another date',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Group slots by morning, afternoon, evening
    final morning = _availableSlots.where((s) => s.startTime.hour < 12).toList();
    final afternoon = _availableSlots.where((s) => s.startTime.hour >= 12 && s.startTime.hour < 17).toList();
    final evening = _availableSlots.where((s) => s.startTime.hour >= 17).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty) _buildSlotSection('Morning', morning, tt),
        if (afternoon.isNotEmpty) _buildSlotSection('Afternoon', afternoon, tt),
        if (evening.isNotEmpty) _buildSlotSection('Evening', evening, tt),
      ],
    );
  }

  Widget _buildSlotSection(String title, List<OdooAppointmentSlot> slots, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BrandColors.ecstasy
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? BrandColors.ecstasy : Colors.white24,
                  ),
                ),
                child: Text(
                  slot.formattedTime,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomerForm(TextTheme tt) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Full Name *', Icons.person),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email *', Icons.email),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Phone (optional)', Icons.phone),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Notes (optional)', Icons.note),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: BrandColors.ecstasy),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.ecstasy),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

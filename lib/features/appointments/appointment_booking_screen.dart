import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/brand_theme.dart';
import '../../core/odoo/odoo_api_service.dart';
import '../../core/models/odoo_models.dart';
import '../auth/state/auth_state.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});
  static const String route = '/appointment_booking';

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? _selectedDate;
  OdooAppointmentSlot? _selectedSlot;
  int? _selectedStaffId;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<OdooAppointmentSlot> _availableSlots = [];
  List<OdooStaff> _staffMembers = [];
  int? _appointmentTypeId;

  final List<String> _timezones = const ['Asia/Kolkata', 'UTC'];
  String _selectedTimezone = 'Asia/Kolkata';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
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

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final appointmentId = args?['appointmentId'] as int?;
    final serviceId = args?['serviceId'] as int?;

    if (appointmentId != null) {
      _appointmentTypeId = appointmentId;
    } else if (serviceId != null) {
      try {
        final odooApi = OdooApiService();
        final appointmentTypes = await odooApi.getAppointmentTypes();
        final matchingType = appointmentTypes.firstWhere(
          (apt) => apt.productId == serviceId,
          orElse: () => throw Exception('No appointment type found for this service'),
        );
        _appointmentTypeId = matchingType.id;
      } catch (e) {
        _safeSetState(() {
          _errorMessage = 'Appointment booking not available for this service';
          _isLoading = false;
        });
        return;
      }
    } else {
      _safeSetState(() {
        _errorMessage = 'Invalid appointment configuration';
        _isLoading = false;
      });
      return;
    }

    await _loadStaffMembers();
    await _loadAvailableSlots();
    _safeSetState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadStaffMembers() async {
    if (_appointmentTypeId == null) return;
    try {
      final odooApi = OdooApiService();
      final staff = await odooApi.getAppointmentStaff(_appointmentTypeId!);
      if (_isDisposed) return;
      _safeSetState(() {
        _staffMembers = staff;
        if (staff.length == 1) _selectedStaffId = staff.first.id;
      });
    } catch (e) {
      debugPrint('Failed to load staff members: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_appointmentTypeId == null || _selectedDate == null) return;
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final odooApi = OdooApiService();
      final slots = await odooApi.getAppointmentSlots(
        appointmentTypeId: _appointmentTypeId!,
        date: _selectedDate!,
        staffId: _selectedStaffId,
      );
      if (_isDisposed) return;
      _safeSetState(() {
        _availableSlots = slots;
        _selectedSlot = null;
        _isLoading = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _errorMessage = 'Failed to load available slots: $e';
        _availableSlots = [];
        _selectedSlot = null;
        _isLoading = false;
      });
    }
  }

  void _selectDate(DateTime date) {
    _safeSetState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    _loadAvailableSlots();
  }

  void _selectSlot(OdooAppointmentSlot slot) {
    _safeSetState(() {
      _selectedSlot = slot;
      if (slot.staffId != 0) _selectedStaffId = slot.staffId;
    });
  }

  Future<void> _confirmBooking() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final serviceName = args?['serviceName'] as String? ?? 'Service';
    final serviceId = args?['serviceId'] as int?;
    final price = args?['price'] as double?;

    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time'), backgroundColor: BrandColors.persianRed),
      );
      return;
    }
    if (_staffMembers.isNotEmpty && _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a consultant'), backgroundColor: BrandColors.persianRed),
      );
      return;
    }

    _safeSetState(() => _isLoading = true);
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final userName = authState.firstName ?? 'Guest';
      final userEmail = authState.email ?? '';
      final userPhone = authState.phoneNumber ?? '';

      final odooApi = OdooApiService();
      final result = await odooApi.createAppointmentBooking(
        appointmentTypeId: _appointmentTypeId!,
        dateTime: _selectedSlot!.startTime,
        staffId: _selectedStaffId ?? _selectedSlot!.staffId,
        customerName: userName,
        customerEmail: userEmail,
        customerPhone: userPhone,
        notes: 'Booking for $serviceName',
        productId: serviceId,
        price: price,
      );

      if (!mounted || _isDisposed) return;
      if (result?['error'] != null) {
        throw Exception(result!['error']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment booked for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)} at ${DateFormat('h:mm a').format(_selectedSlot!.startTime)}',
          ),
          backgroundColor: BrandColors.ecstasy,
          duration: const Duration(seconds: 3),
        ),
      );

      _safeSetState(() => _isLoading = false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && !_isDisposed) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book appointment: $e'),
          backgroundColor: BrandColors.persianRed,
          duration: const Duration(seconds: 4),
        ),
      );
      _safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BrandColors.ecstasy))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: BrandColors.codGrey),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Select a date & time',
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: BrandColors.codGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(_errorMessage!, style: tt.bodyMedium?.copyWith(color: Colors.red)),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 12),
                        Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildCalendarCard(tt),
                            ),
                            SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                            Expanded(
                              flex: 1,
                              child: _buildTimeCard(tt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_staffMembers.isNotEmpty) _buildStaffDropdown(tt),
                        const SizedBox(height: 20),
                        _buildTimezoneRow(tt),
                        const SizedBox(height: 24),
                        _buildServiceSummary(tt),
                        const SizedBox(height: 16),
                        _buildConfirmButton(tt),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCalendarCard(TextTheme tt) {
    final selected = _selectedDate ?? DateTime.now();
    final monthStart = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final leading = monthStart.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prevMonth = DateTime(selected.year, selected.month - 1, selected.day);
                  final today = DateTime.now();
                  if (DateTime(prevMonth.year, prevMonth.month).isBefore(DateTime(today.year, today.month))) return;
                  _selectDate(DateTime(prevMonth.year, prevMonth.month, 1));
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(selected),
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: BrandColors.codGrey),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextMonth = DateTime(selected.year, selected.month + 1, 1);
                  _selectDate(DateTime(nextMonth.year, nextMonth.month, 1));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = index - leading + 1;
              final date = DateTime(selected.year, selected.month, day);
              final isSelected = _selectedDate != null && DateUtils.isSameDay(_selectedDate, date);
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

              return GestureDetector(
                onTap: isPast ? null : () => _selectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? BrandColors.cardinalPink : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? BrandColors.cardinalPink : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
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

  Widget _buildTimeCard(TextTheme tt) {
    final slots = List<OdooAppointmentSlot>.from(_availableSlots)..sort((a, b) => a.startTime.compareTo(b.startTime));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a time', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: BrandColors.codGrey)),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Text('No slots for this date', style: tt.bodyMedium?.copyWith(color: Colors.grey.shade600))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots.map((slot) {
                final isSelected = _selectedSlot?.startTime == slot.startTime;
                final label = DateFormat('h:mm a').format(slot.startTime);
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : BrandColors.codGrey)),
                  selectedColor: BrandColors.cardinalPink,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => _selectSlot(slot),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? BrandColors.cardinalPink : Colors.grey.shade300)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimezoneRow(TextTheme tt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('Timezone:', style: tt.bodyMedium?.copyWith(color: BrandColors.codGrey, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedTimezone,
          items: _timezones
              .map((tz) => DropdownMenuItem(
                    value: tz,
                    child: Text(tz),
                  ))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            _safeSetState(() => _selectedTimezone = val);
          },
        ),
      ],
    );
  }

  Widget _buildStaffDropdown(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select consultant', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: BrandColors.codGrey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedStaffId,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: _staffMembers
              .map((s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name),
                  ))
              .toList(),
          onChanged: (val) {
            _safeSetState(() {
              _selectedStaffId = val;
              _selectedSlot = null;
            });
            _loadAvailableSlots();
          },
        ),
      ],
    );
  }

  Widget _buildServiceSummary(TextTheme tt) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final serviceName = args?['serviceName'] as String? ?? 'Service';
    final price = args?['price'] as num?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.healing, color: BrandColors.cardinalPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: BrandColors.codGrey)),
                if (price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('₹${price.toStringAsFixed(0)}', style: tt.bodyMedium?.copyWith(color: BrandColors.cardinalPink, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(TextTheme tt) {
    final enabled = _selectedSlot != null && !_isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? BrandColors.cardinalPink : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: enabled ? _confirmBooking : null,
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

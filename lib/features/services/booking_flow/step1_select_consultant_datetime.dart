import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/brand_theme.dart';
import '../../../core/models/odoo_models.dart';
import '../../../core/odoo/odoo_api_service.dart';

/// Step 1 of booking: Select consultant, date, and time slot
/// Shows consultant selection, calendar, and available time slots for chosen date
class BookingStep1SelectConsultantDatetime extends StatefulWidget {
  final int appointmentTypeId;
  final String serviceName;
  final double price;
  final String? serviceImage;
  final int durationMinutes;
  final int productId;

  const BookingStep1SelectConsultantDatetime({
    super.key,
    required this.appointmentTypeId,
    required this.serviceName,
    required this.price,
    this.serviceImage,
    required this.durationMinutes,
    required this.productId,
  });

  static const String route = '/booking_step1_select_consultant';

  @override
  State<BookingStep1SelectConsultantDatetime> createState() =>
      _BookingStep1SelectConsultantDatetimeState();
}

class _BookingStep1SelectConsultantDatetimeState
    extends State<BookingStep1SelectConsultantDatetime> {
  final OdooApiService _apiService = OdooApiService();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<OdooStaff> _consultants = [];
  List<OdooAppointmentSlot> _availableSlots = [];
  bool _isSlotsLoading = false;

  // Selected values
  OdooStaff? _selectedConsultant;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  OdooAppointmentSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadConsultants();
  }

  Future<void> _loadConsultants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consultants =
          await _apiService.getAppointmentStaff(widget.appointmentTypeId);
      
      setState(() {
        _consultants = consultants;
        if (consultants.isNotEmpty) {
          _selectedConsultant = consultants.first;
          _loadAvailableSlots();
        } else {
          _isLoading = false;
          _errorMessage = 'No consultants available for this service';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load consultants: $e';
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedConsultant == null) return;

    setState(() {
      _isSlotsLoading = true;
      _errorMessage = null;
    });

    try {
      final slots = await _apiService.getAppointmentSlots(
        appointmentTypeId: widget.appointmentTypeId,
        date: _selectedDate,
        staffId: _selectedConsultant!.id,
      );

      setState(() {
        _availableSlots = slots;
        _selectedSlot = null;
        _isSlotsLoading = false;
        if (slots.isEmpty) {
          _errorMessage = 'No available slots for ${_selectedConsultant!.name} on this date';
        }
      });
    } catch (e) {
      setState(() {
        _isSlotsLoading = false;
        _errorMessage = 'Failed to load available slots: $e';
      });
    }
  }

  void _onConsultantChanged(OdooStaff? consultant) {
    setState(() {
      _selectedConsultant = consultant;
      _selectedSlot = null;
    });
    if (consultant != null) {
      _loadAvailableSlots();
    }
  }

  void _onDateChanged(DateTime? date) {
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedSlot = null;
      });
      _loadAvailableSlots();
    }
  }

  void _onProceedToReview() {
    if (_selectedConsultant == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a consultant and time slot'),
          backgroundColor: BrandColors.cardinalPink,
        ),
      );
      return;
    }

    // Navigate to step 2 with selected values
    Navigator.of(context).pushNamed(
      '/booking_step2_review',
      arguments: {
        'appointmentTypeId': widget.appointmentTypeId,
        'serviceName': widget.serviceName,
        'price': widget.price,
        'serviceImage': widget.serviceImage,
        'durationMinutes': widget.durationMinutes,
        'productId': widget.productId,
        'selectedConsultant': _selectedConsultant,
        'selectedSlot': _selectedSlot,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.codGrey,
      appBar: AppBar(
        backgroundColor: BrandColors.codGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.alabaster),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Consultant & Date',
          style: TextStyle(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: BrandColors.ecstasy),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service info header
                    _buildServiceHeader(),
                    const SizedBox(height: 24),

                    // Consultant selection
                    if (_consultants.length > 1) ...[
                      _buildConsultantSelector(),
                      const SizedBox(height: 24),
                    ],

                    // Date picker
                    _buildDatePicker(),
                    const SizedBox(height: 24),

                    // Available slots
                    _buildSlotsSection(),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BrandColors.cardinalPink.withValues(alpha: 0.1),
                          border: Border.all(color: BrandColors.cardinalPink),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: BrandColors.cardinalPink,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Proceed button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedSlot != null ? _onProceedToReview : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.ecstasy,
                          disabledBackgroundColor:
                              BrandColors.ecstasy.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Review',
                          style: TextStyle(
                            color: BrandColors.alabaster,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.alabaster.withValues(alpha: 0.08),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (widget.serviceImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.serviceImage!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: BrandColors.ecstasy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.healing,
                      color: BrandColors.ecstasy, size: 30),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: BrandColors.ecstasy.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.healing, color: BrandColors.ecstasy, size: 30),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceName,
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.price.toStringAsFixed(0)} • ${widget.durationMinutes} min',
                  style: TextStyle(
                    color: BrandColors.alabaster.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Consultant',
          style: TextStyle(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _consultants
                .map(
                  (consultant) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildConsultantChip(consultant),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultantChip(OdooStaff consultant) {
    final isSelected = _selectedConsultant?.id == consultant.id;
    return GestureDetector(
      onTap: () => _onConsultantChanged(consultant),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? BrandColors.ecstasy
              : BrandColors.alabaster.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected
                ? BrandColors.ecstasy
                : BrandColors.alabaster.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.ecstasy.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.person,
                size: 14,
                color:
                    isSelected ? BrandColors.alabaster : BrandColors.codGrey,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              consultant.name.split(' ').first,
              style: TextStyle(
                color: isSelected ? BrandColors.alabaster : BrandColors.ecstasy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: BrandColors.ecstasy,
                      surface: BrandColors.codGrey,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              _onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BrandColors.alabaster.withValues(alpha: 0.08),
              border: Border.all(
                color: BrandColors.ecstasy,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: BrandColors.ecstasy),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEE, MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: BrandColors.ecstasy),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Times',
              style: TextStyle(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (_isSlotsLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(BrandColors.ecstasy),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isSlotsLoading && _availableSlots.isEmpty)
          const Center(
            child: CircularProgressIndicator(color: BrandColors.ecstasy),
          )
        else if (_availableSlots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No available slots for this date',
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedSlot?.startTime == slot.startTime;
              return _buildSlotButton(slot, isSelected);
            },
          ),
      ],
    );
  }

  Widget _buildSlotButton(OdooAppointmentSlot slot, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSlot = slot;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? BrandColors.ecstasy
              : BrandColors.alabaster.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected
                ? BrandColors.ecstasy
                : BrandColors.alabaster.withValues(alpha: 0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('h:mm a').format(slot.startTime),
              style: TextStyle(
                color: isSelected ? BrandColors.alabaster : BrandColors.ecstasy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'to',
              style: TextStyle(
                color: isSelected
                    ? BrandColors.alabaster.withValues(alpha: 0.7)
                    : BrandColors.alabaster.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a').format(slot.endTime),
              style: TextStyle(
                color: isSelected ? BrandColors.alabaster : BrandColors.ecstasy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

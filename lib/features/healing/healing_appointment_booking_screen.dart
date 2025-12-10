import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/odoo_models.dart';
import '../../core/odoo/odoo_api_service.dart';
import '../../theme/brand_theme.dart';

/// Complete Healing Appointment Booking Screen
/// Handles appointment-based healing services with consultant selection and time slot booking
class HealingAppointmentBookingScreen extends StatefulWidget {
  final OdooService service;
  final int appointmentTypeId;

  const HealingAppointmentBookingScreen({
    super.key,
    required this.service,
    required this.appointmentTypeId,
  });

  @override
  State<HealingAppointmentBookingScreen> createState() => _HealingAppointmentBookingScreenState();
}

class _HealingAppointmentBookingScreenState extends State<HealingAppointmentBookingScreen> {
  final OdooApiService _odooApi = OdooApiService();
  
  // State variables
  bool _isLoading = true;
  String? _error;
  
  // Appointment details
  Map<String, dynamic>? _appointmentDetails;
  List<OdooStaff> _consultants = [];
  List<OdooAppointmentSlot> _availableSlots = [];
  
  // User selections
  OdooStaff? _selectedConsultant;
  DateTime _selectedDate = DateTime.now();
  OdooAppointmentSlot? _selectedSlot;
  
  // Form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointmentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch appointment type details
      final details = await _odooApi.getAppointmentTypeDetails(widget.appointmentTypeId);
      
      // Fetch available consultants
      final consultants = await _odooApi.getAppointmentStaff(widget.appointmentTypeId);
      
      setState(() {
        _appointmentDetails = details;
        _consultants = consultants;
        _isLoading = false;
        
        // Auto-select first consultant if only one
        if (_consultants.length == 1) {
          _selectedConsultant = _consultants.first;
          _loadAvailableSlots();
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load appointment details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedConsultant == null) return;

    setState(() {
      _isLoading = true;
      _availableSlots = [];
      _selectedSlot = null;
    });

    try {
      final slots = await _odooApi.getAppointmentSlots(
        appointmentTypeId: widget.appointmentTypeId,
        date: _selectedDate,
        staffId: _selectedConsultant!.id,
      );

      setState(() {
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available slots: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null || _selectedConsultant == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _odooApi.createAppointmentBooking(
        appointmentTypeId: widget.appointmentTypeId,
        dateTime: _selectedSlot!.startTime,
        staffId: _selectedConsultant!.id,
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        customerPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        productId: widget.service.id,
        price: widget.service.price,
      );

      if (result != null && result['error'] == null) {
        if (!mounted) return;
        
        // Show success dialog
        _showSuccessDialog();
      } else {
        setState(() {
          _error = result?['error'] ?? 'Booking failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create booking: $e';
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: BrandColors.ecstasy, size: 32),
            const SizedBox(width: 12),
            const Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your healing appointment has been successfully booked.'),
            const SizedBox(height: 16),
            Text('Service: ${widget.service.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Consultant: ${_selectedConsultant!.name}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedSlot!.startTime)}'),
            Text('Time: ${DateFormat('hh:mm a').format(_selectedSlot!.startTime)}'),
            const SizedBox(height: 16),
            const Text('You will receive a confirmation email with the meeting link.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to service list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        backgroundColor: BrandColors.ecstasy,
      ),
      body: _isLoading && _appointmentDetails == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _appointmentDetails == null
              ? _buildErrorView()
              : _buildBookingForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: BrandColors.cardinalPink),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAppointmentData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Info Card
            _buildServiceInfoCard(),
            const SizedBox(height: 24),
            
            // Step 1: Select Consultant
            _buildSectionTitle('1. Select Consultant'),
            const SizedBox(height: 12),
            _buildConsultantSelection(),
            const SizedBox(height: 24),
            
            // Step 2: Select Date
            if (_selectedConsultant != null) ...[
              _buildSectionTitle('2. Select Date'),
              const SizedBox(height: 12),
              _buildDateSelection(),
              const SizedBox(height: 24),
            ],
            
            // Step 3: Select Time Slot
            if (_selectedConsultant != null && _availableSlots.isNotEmpty) ...[
              _buildSectionTitle('3. Select Time Slot'),
              const SizedBox(height: 12),
              _buildTimeSlotSelection(),
              const SizedBox(height: 24),
            ],
            
            // Step 4: Your Details
            if (_selectedSlot != null) ...[
              _buildSectionTitle('4. Your Details'),
              const SizedBox(height: 12),
              _buildCustomerDetailsForm(),
              const SizedBox(height: 24),
            ],
            
            // Booking Summary
            if (_selectedSlot != null) ...[
              _buildBookingSummary(),
              const SizedBox(height: 80), // Space for bottom bar
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    final duration = _appointmentDetails?['appointment_duration'] as num? ?? 0.25;
    final durationMinutes = (duration * 60).round();
    final location = _appointmentDetails?['location'] as String? ?? 'Online Meeting';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.service.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.service.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.ecstasy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Duration: $durationMinutes minutes'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Location: $location'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildConsultantSelection() {
    if (_consultants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No consultants available for this service.'),
        ),
      );
    }

    return Column(
      children: _consultants.map((consultant) {
        final isSelected = _selectedConsultant?.id == consultant.id;
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? BrandColors.ecstasy.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: consultant.imageUrl != null
                  ? NetworkImage(consultant.imageUrl!)
                  : null,
              child: consultant.imageUrl == null
                  ? Text(consultant.name[0].toUpperCase())
                  : null,
            ),
            title: Text(
              consultant.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: consultant.email != null ? Text(consultant.email!) : null,
            trailing: isSelected
                ? Icon(Icons.check_circle, color: BrandColors.ecstasy)
                : null,
            onTap: () {
              setState(() {
                _selectedConsultant = consultant;
                _selectedSlot = null;
                _availableSlots = [];
              });
              _loadAvailableSlots();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelection() {
    final maxDays = _appointmentDetails?['max_schedule_days'] as int? ?? 15;
    final minHours = (_appointmentDetails?['min_schedule_hours'] as num?)?.toDouble() ?? 1.0;
    final earliestDate = DateTime.now().add(Duration(hours: minHours.ceil()));
    final latestDate = DateTime.now().add(Duration(days: maxDays));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Date: ${DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: maxDays,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final isPast = date.isBefore(earliestDate);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: BrandColors.ecstasy,
                      onSelected: isPast
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedSlot = null;
                                });
                                _loadAvailableSlots();
                              }
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableSlots.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text(
                'No available slots for this date.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select a different date.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSlots.map((slot) {
        final isSelected = _selectedSlot?.startTime == slot.startTime;
        final timeFormat = DateFormat('hh:mm a');
        
        return ChoiceChip(
          label: Text(
            '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
          ),
          selected: isSelected,
          selectedColor: BrandColors.ecstasy,
          onSelected: (selected) {
            setState(() {
              _selectedSlot = selected ? slot : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCustomerDetailsForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Special Requests (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      color: BrandColors.ecstasy.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildSummaryRow('Service', widget.service.name),
            _buildSummaryRow('Consultant', _selectedConsultant!.name),
            _buildSummaryRow(
              'Date',
              DateFormat('EEEE, MMM dd, yyyy').format(_selectedSlot!.startTime),
            ),
            _buildSummaryRow(
              'Time',
              '${DateFormat('hh:mm a').format(_selectedSlot!.startTime)} - ${DateFormat('hh:mm a').format(_selectedSlot!.endTime)}',
            ),
            _buildSummaryRow(
              'Location',
              _appointmentDetails?['location'] as String? ?? 'Online Meeting',
            ),
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '₹${widget.service.price.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? BrandColors.ecstasy : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? BrandColors.ecstasy : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_selectedSlot == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _bookAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.ecstasy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Confirm Booking - ₹${widget.service.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/brand_theme.dart';
import '../auth/state/auth_state.dart';
import '../../core/odoo/odoo_api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  static const String route = '/my_appointments';
  
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<AppointmentData> _upcomingAppointments = [];
  List<AppointmentData> _pastAppointments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final email = authState.email;

      if (email == null || email.isEmpty) {
        setState(() {
          _errorMessage = 'Please log in with email to view your appointments';
          _isLoading = false;
        });
        return;
      }

      // Fetch appointments from Odoo
      final odooApi = OdooApiService();
      final odooAppointments = await odooApi.getUserAppointments(
        customerEmail: email,
      );

      final List<AppointmentData> allAppointments = [];
      final now = DateTime.now();

      // Process Odoo appointments
      for (var eventData in odooAppointments) {
        try {
          final appointmentData = AppointmentData.fromOdoo(eventData);
          allAppointments.add(appointmentData);
        } catch (e) {
          debugPrint('[MyAppointments] Error parsing appointment: $e');
        }
      }

      // Sort appointments into upcoming and past
      _upcomingAppointments = allAppointments
          .where((apt) => apt.appointmentDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      _pastAppointments = allAppointments
          .where((apt) => apt.appointmentDate.isBefore(now) || apt.appointmentDate.isAtSameMomentAs(now))
          .toList()
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MyAppointments] Error loading appointments: $e');
      setState(() {
        _errorMessage = 'Failed to load appointments: $e';
        _isLoading = false;
      });
    }
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
              // Header
              _buildHeader(tt),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: BrandColors.ecstasy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: BrandColors.alabaster.withOpacity(0.7),
                  labelStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Pending (${_upcomingAppointments.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Completed (${_pastAppointments.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: BrandColors.ecstasy,
                        ),
                      )
                    : _errorMessage != null
                        ? _buildErrorState(tt)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAppointmentsList(_upcomingAppointments, isUpcoming: true),
                              _buildAppointmentsList(_pastAppointments, isUpcoming: false),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Appointments',
                  style: tt.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track your consultant bookings',
                  style: tt.bodyMedium?.copyWith(
                    color: BrandColors.alabaster.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAppointments,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: BrandColors.ecstasy,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: tt.titleMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.ecstasy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentData> appointments, {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(isUpcoming);
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: BrandColors.ecstasy,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index], isUpcoming);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
              size: 80,
              color: BrandColors.alabaster.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No Upcoming Appointments' : 'No Past Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Book a consultation to get started on your spiritual journey'
                  : 'Your completed appointments will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.alabaster.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to services/home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.ecstasy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Book an Appointment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentData appointment, bool isUpcoming) {
    final tt = Theme.of(context).textTheme;
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAppointmentDetails(appointment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.serviceName,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.codGrey,
                        ),
                      ),
                    ),
                    _buildStatusChip(appointment, isUpcoming),
                  ],
                ),
                const SizedBox(height: 12),

                // Date and time
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  dateFormat.format(appointment.appointmentDate),
                  tt,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  timeFormat.format(appointment.appointmentDate),
                  tt,
                ),

                // Consultant info if available
                if (appointment.consultantName != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person_rounded,
                    'Consultant: ${appointment.consultantName}',
                    tt,
                  ),
                ],

                // Duration if available
                if (appointment.duration != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.timer_outlined,
                    'Duration: ${appointment.duration} minutes',
                    tt,
                  ),
                ],

                // Location if available
                if (appointment.location != null && appointment.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    appointment.location!,
                    tt,
                  ),
                ],

                // Booking ID
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrandColors.alabaster.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Booking ID: ${appointment.id.substring(0, 8).toUpperCase()}',
                    style: tt.bodySmall?.copyWith(
                      color: BrandColors.codGrey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                // Action buttons for upcoming appointments
                if (isUpcoming) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAppointmentDetails(appointment),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandColors.cardinalPink,
                            side: const BorderSide(color: BrandColors.cardinalPink),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCalendar(appointment),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.ecstasy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.event, size: 18),
                          label: const Text('Add to Calendar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppointmentData appointment, bool isUpcoming) {
    Color chipColor;
    String statusText;
    IconData icon;

    if (isUpcoming) {
      final hoursUntil = appointment.appointmentDate.difference(DateTime.now()).inHours;
      if (hoursUntil <= 24) {
        chipColor = Colors.orange;
        statusText = 'Soon';
        icon = Icons.notifications_active;
      } else {
        chipColor = Colors.green;
        statusText = 'Scheduled';
        icon = Icons.check_circle;
      }
    } else {
      chipColor = Colors.grey;
      statusText = 'Completed';
      icon = Icons.check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, TextTheme tt) {
    return Row(
      children: [
        Icon(icon, size: 18, color: BrandColors.cardinalPink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: tt.bodyMedium?.copyWith(
              color: BrandColors.codGrey,
            ),
          ),
        ),
      ],
    );
  }

  void _showAppointmentDetails(AppointmentData appointment) {
    final tt = Theme.of(context).textTheme;
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Appointment Details',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BrandColors.codGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Service
            _buildDetailRow('Service', appointment.serviceName, Icons.healing),
            const Divider(height: 32),

            // Date
            _buildDetailRow(
              'Date',
              dateFormat.format(appointment.appointmentDate),
              Icons.calendar_today,
            ),
            const Divider(height: 32),

            // Time
            _buildDetailRow(
              'Time',
              timeFormat.format(appointment.appointmentDate),
              Icons.access_time,
            ),

            if (appointment.consultantName != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                'Consultant',
                appointment.consultantName!,
                Icons.person,
              ),
            ],

            if (appointment.duration != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                'Duration',
                '${appointment.duration} minutes',
                Icons.timer,
              ),
            ],

            if (appointment.location != null && appointment.location!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildDetailRow(
                'Location',
                appointment.location!,
                Icons.location_on,
              ),
            ],

            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildDetailRow(
                'Notes',
                appointment.notes!,
                Icons.note,
              ),
            ],

            const Divider(height: 32),
            _buildDetailRow(
              'Booking ID',
              appointment.id.substring(0, 12).toUpperCase(),
              Icons.qr_code,
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.ecstasy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BrandColors.cardinalPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: BrandColors.cardinalPink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: tt.bodyLarge?.copyWith(
                  color: BrandColors.codGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addToCalendar(AppointmentData appointment) {
    // This would integrate with device calendar
    // For now, show a simple dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.event, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add to calendar feature coming soon!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: BrandColors.ecstasy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Data model for appointments
class AppointmentData {
  final String id;
  final String serviceName;
  final DateTime appointmentDate;
  final String? consultantName;
  final int? duration;
  final String? notes;
  final String? status;
  final String? location;

  AppointmentData({
    required this.id,
    required this.serviceName,
    required this.appointmentDate,
    this.consultantName,
    this.duration,
    this.notes,
    this.status,
    this.location,
  });

  factory AppointmentData.fromOdoo(Map<String, dynamic> data) {
    DateTime appointmentDate;
    
    // Parse Odoo datetime format (YYYY-MM-DD HH:MM:SS)
    if (data['start'] is String) {
      try {
        appointmentDate = DateTime.parse(data['start'] as String);
      } catch (e) {
        debugPrint('[AppointmentData] Error parsing date: $e');
        appointmentDate = DateTime.now();
      }
    } else {
      appointmentDate = DateTime.now();
    }

    // Extract service name from event name or appointment type
    String serviceName = data['name'] as String? ?? 'Consultation';
    if (data['appointmentTypeName'] != null) {
      serviceName = data['appointmentTypeName'] as String;
    }

    // Duration in minutes (Odoo stores in hours as float)
    int? duration;
    if (data['duration'] != null) {
      final durationHours = data['duration'] as num;
      duration = (durationHours * 60).round();
    }

    return AppointmentData(
      id: (data['id'] ?? 0).toString(),
      serviceName: serviceName,
      appointmentDate: appointmentDate,
      consultantName: data['consultantName'] as String?,
      duration: duration,
      notes: data['description'] as String?,
      status: 'scheduled',
      location: data['location'] as String?,
    );
  }
}

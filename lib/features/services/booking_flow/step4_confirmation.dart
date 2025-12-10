import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/brand_theme.dart';
import '../../../core/models/odoo_models.dart';

/// Step 4 of booking: Confirmation screen showing booking success
/// Displays confirmation details and next steps
class BookingStep4Confirmation extends StatefulWidget {
  final int appointmentTypeId;
  final String serviceName;
  final double price;
  final OdooStaff selectedConsultant;
  final OdooAppointmentSlot selectedSlot;
  final String paymentId;
  final int? saleOrderId;

  const BookingStep4Confirmation({
    super.key,
    required this.appointmentTypeId,
    required this.serviceName,
    required this.price,
    required this.selectedConsultant,
    required this.selectedSlot,
    required this.paymentId,
    this.saleOrderId,
  });

  static const String route = '/booking_step4_confirmation';

  @override
  State<BookingStep4Confirmation> createState() =>
      _BookingStep4ConfirmationState();
}

class _BookingStep4ConfirmationState extends State<BookingStep4Confirmation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: BrandColors.codGrey,
        appBar: AppBar(
          backgroundColor: BrandColors.codGrey,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Booking Confirmed',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Success animation
                _buildSuccessAnimation(),
                const SizedBox(height: 24),

                // Confirmation message
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your appointment has been successfully booked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BrandColors.alabaster.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Confirmation details
                _buildConfirmationCard(),
                const SizedBox(height: 16),

                // Consultant details
                _buildConsultantCard(),
                const SizedBox(height: 16),

                // Booking details
                _buildBookingDetailsCard(),
                const SizedBox(height: 24),

                // What to expect
                _buildWhatToExpectSection(),
                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.ecstasy.withValues(alpha: 0.2),
              BrandColors.persianRed.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(
            color: BrandColors.ecstasy,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.check_circle,
          color: BrandColors.ecstasy,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.ecstasy.withValues(alpha: 0.1),
        border: Border.all(
          color: BrandColors.ecstasy,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Confirmation #',
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'HS${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                style: const TextStyle(
                  color: BrandColors.ecstasy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Date',
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now()),
                style: const TextStyle(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (widget.saleOrderId != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sale Order',
                  style: TextStyle(
                    color: BrandColors.alabaster.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'S${widget.saleOrderId}',
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultantCard() {
    final consultant = widget.selectedConsultant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.alabaster.withValues(alpha: 0.08),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Consultant',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.ecstasy.withValues(alpha: 0.2),
                  border: Border.all(
                    color: BrandColors.ecstasy,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: BrandColors.ecstasy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultant.name,
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (consultant.email != null)
                      Text(
                        consultant.email!,
                        style: TextStyle(
                          color: BrandColors.alabaster.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    final slot = widget.selectedSlot;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.alabaster.withValues(alpha: 0.08),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: BrandColors.ecstasy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: BrandColors.alabaster.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(slot.startTime),
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.event_available,
                color: BrandColors.ecstasy,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatToExpectSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.alabaster.withValues(alpha: 0.08),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What to Expect',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildExpectationItem(
            '📧',
            'Confirmation email',
            'Check your inbox for booking confirmation',
          ),
          const SizedBox(height: 12),
          _buildExpectationItem(
            '⏰',
            'Reminder notification',
            '24 hours before your appointment',
          ),
          const SizedBox(height: 12),
          _buildExpectationItem(
            '📞',
            'Consultant contact',
            'You\'ll receive consultant details soon',
          ),
        ],
      ),
    );
  }

  Widget _buildExpectationItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.ecstasy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/my_appointments');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: BrandColors.alabaster,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'View My Appointments',
              style: TextStyle(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

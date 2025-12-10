import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/brand_theme.dart';
import '../../../core/models/odoo_models.dart';
import '../../auth/state/auth_state.dart';
import 'package:provider/provider.dart';

/// Step 2 of booking: Review all booking details before payment
/// Shows selected consultant, date, time, service details, and total price
class BookingStep2ReviewDetails extends StatefulWidget {
  final int appointmentTypeId;
  final String serviceName;
  final double price;
  final String? serviceImage;
  final int durationMinutes;
  final int productId;
  final OdooStaff selectedConsultant;
  final OdooAppointmentSlot selectedSlot;

  const BookingStep2ReviewDetails({
    super.key,
    required this.appointmentTypeId,
    required this.serviceName,
    required this.price,
    this.serviceImage,
    required this.durationMinutes,
    required this.productId,
    required this.selectedConsultant,
    required this.selectedSlot,
  });

  static const String route = '/booking_step2_review';

  @override
  State<BookingStep2ReviewDetails> createState() =>
      _BookingStep2ReviewDetailsState();
}

class _BookingStep2ReviewDetailsState extends State<BookingStep2ReviewDetails> {
  bool _agreeToTerms = false;

  void _onProceedToPayment() {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: BrandColors.cardinalPink,
        ),
      );
      return;
    }

    // Navigate to payment step
    Navigator.of(context).pushNamed(
      '/booking_step3_payment',
      arguments: {
        'appointmentTypeId': widget.appointmentTypeId,
        'serviceName': widget.serviceName,
        'price': widget.price,
        'serviceImage': widget.serviceImage,
        'durationMinutes': widget.durationMinutes,
        'productId': widget.productId,
        'selectedConsultant': widget.selectedConsultant,
        'selectedSlot': widget.selectedSlot,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

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
          'Review Booking',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 24),
              _buildServiceCard(),
              const SizedBox(height: 16),
              _buildConsultantCard(),
              const SizedBox(height: 16),
              _buildBookingDetailsCard(),
              const SizedBox(height: 16),
              _buildCustomerInfoCard(authState),
              const SizedBox(height: 16),
              _buildPriceBreakdown(),
              const SizedBox(height: 16),
              _buildTermsCheckbox(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onProceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.ecstasy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Payment',
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

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle('1', true),
        Expanded(
          child: Container(
            height: 2,
            color: BrandColors.ecstasy,
          ),
        ),
        _buildStepCircle('2', true),
        Expanded(
          child: Container(
            height: 2,
            color: BrandColors.alabaster.withValues(alpha: 0.2),
          ),
        ),
        _buildStepCircle('3', false),
        Expanded(
          child: Container(
            height: 2,
            color: BrandColors.alabaster.withValues(alpha: 0.2),
          ),
        ),
        _buildStepCircle('4', false),
      ],
    );
  }

  Widget _buildStepCircle(String number, bool completed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? BrandColors.ecstasy : BrandColors.alabaster.withValues(alpha: 0.1),
        border: Border.all(
          color: completed ? BrandColors.ecstasy : BrandColors.alabaster.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: completed ? BrandColors.alabaster : BrandColors.alabaster.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
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
            'Service',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.serviceImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.serviceImage!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  ),
                )
              else
                _buildPlaceholderImage(),
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
                      '${widget.durationMinutes} minutes',
                      style: TextStyle(
                        color: BrandColors.alabaster.withValues(alpha: 0.6),
                        fontSize: 13,
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: BrandColors.ecstasy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.healing, color: BrandColors.ecstasy, size: 30),
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
            'Consultant',
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
              Column(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(slot.startTime),
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.event,
                color: BrandColors.ecstasy,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(AuthState authState) {
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
            'Your Details',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Name',
            authState.name ?? 'Guest User',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Email',
            authState.email ?? 'Not provided',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Phone',
            authState.phone ?? 'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: BrandColors.alabaster.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    final subtotal = widget.price;
    const tax = 0.0; // Tax calculation can be added later
    final total = subtotal + tax;

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
          _buildPriceRow('Service', subtotal),
          const SizedBox(height: 8),
          if (tax > 0) ...[
            _buildPriceRow('Tax', tax),
            const SizedBox(height: 8),
          ],
          Container(
            height: 1,
            color: BrandColors.alabaster.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          _buildPriceRow(
            'Total Amount',
            total,
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? BrandColors.ecstasy : BrandColors.alabaster.withValues(alpha: 0.7),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isTotal ? BrandColors.ecstasy : BrandColors.alabaster,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _agreeToTerms = !_agreeToTerms;
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: _agreeToTerms ? BrandColors.ecstasy : BrandColors.alabaster.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              color: _agreeToTerms ? BrandColors.ecstasy : Colors.transparent,
            ),
            child: _agreeToTerms
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: BrandColors.alabaster,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'I agree to the ',
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: const TextStyle(
                      color: BrandColors.ecstasy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.8),
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: BrandColors.ecstasy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

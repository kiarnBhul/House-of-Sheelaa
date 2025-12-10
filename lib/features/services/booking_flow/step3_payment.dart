import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/brand_theme.dart';
import '../../../core/models/odoo_models.dart';
import '../../../core/odoo/odoo_api_service.dart';
import '../../auth/state/auth_state.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Step 3 of booking: Payment processing with Razorpay
/// Handles payment initiation, success, and failure cases
class BookingStep3Payment extends StatefulWidget {
  final int appointmentTypeId;
  final String serviceName;
  final double price;
  final String? serviceImage;
  final int durationMinutes;
  final int productId;
  final OdooStaff selectedConsultant;
  final OdooAppointmentSlot selectedSlot;

  const BookingStep3Payment({
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

  static const String route = '/booking_step3_payment';

  @override
  State<BookingStep3Payment> createState() => _BookingStep3PaymentState();
}

class _BookingStep3PaymentState extends State<BookingStep3Payment> {
  late Razorpay _razorpay;
  final OdooApiService _apiService = OdooApiService();
  bool _isProcessing = false;
  String? _paymentStatus;
  String? _paymentErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
      _paymentStatus = 'processing';
    });

    try {
      // Create appointment booking in Odoo
      final authState = context.read<AuthState>();
      final result = await _apiService.createAppointmentBooking(
        appointmentTypeId: widget.appointmentTypeId,
        dateTime: widget.selectedSlot.startTime,
        staffId: widget.selectedConsultant.id,
        customerName: authState.name ?? 'Guest User',
        customerEmail: authState.email ?? 'guest@example.com',
        customerPhone: authState.phone,
        notes: 'Payment ID: ${response.paymentId}',
        productId: widget.productId,
        price: widget.price,
      );

      if (result != null && result['success'] == true) {
        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/booking_step4_confirmation',
            (route) => route.isFirst,
            arguments: {
              'appointmentTypeId': widget.appointmentTypeId,
              'serviceName': widget.serviceName,
              'price': widget.price,
              'selectedConsultant': widget.selectedConsultant,
              'selectedSlot': widget.selectedSlot,
              'paymentId': response.paymentId,
              'saleOrderId': result['sale_order_id'],
            },
          );
        }
      } else {
        // Booking creation failed
        if (mounted) {
          setState(() {
            _paymentStatus = 'error';
            _paymentErrorMessage = 'Failed to create booking. Please contact support.';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Booking creation error: $e');
      if (mounted) {
        setState(() {
          _paymentStatus = 'error';
          _paymentErrorMessage = 'An error occurred: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _paymentStatus = 'failed';
      _paymentErrorMessage = response.message ?? 'Payment failed. Please try again.';
      _isProcessing = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  void _handleManualPayment(AuthState authState) async {
    setState(() {
      _isProcessing = true;
      _paymentStatus = 'processing';
    });

    try {
      // Create appointment booking in Odoo with manual payment note
      final result = await _apiService.createAppointmentBooking(
        appointmentTypeId: widget.appointmentTypeId,
        dateTime: widget.selectedSlot.startTime,
        staffId: widget.selectedConsultant.id,
        customerName: authState.name ?? 'Guest User',
        customerEmail: authState.email ?? 'guest@example.com',
        customerPhone: authState.phone,
        notes: 'Manual Payment (Testing Mode)',
        productId: widget.productId,
        price: widget.price,
      );

      if (result != null && result['success'] == true) {
        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/booking_step4_confirmation',
            (route) => route.isFirst,
            arguments: {
              'appointmentTypeId': widget.appointmentTypeId,
              'serviceName': widget.serviceName,
              'price': widget.price,
              'selectedConsultant': widget.selectedConsultant,
              'selectedSlot': widget.selectedSlot,
              'paymentId': 'MANUAL_TEST_${DateTime.now().millisecondsSinceEpoch}',
              'saleOrderId': result['sale_order_id'],
            },
          );
        }
      } else {
        // Booking creation failed
        if (mounted) {
          setState(() {
            _paymentStatus = 'error';
            _paymentErrorMessage = 'Failed to create booking. Please contact support.';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Booking creation error: $e');
      if (mounted) {
        setState(() {
          _paymentStatus = 'error';
          _paymentErrorMessage = 'An error occurred: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _openRazorpayCheckout(AuthState authState) async {
    // Amount in paise (1 INR = 100 paise)
    final amountInPaise = (widget.price * 100).toInt();

    var options = {
      'key': 'rzp_live_YOUR_KEY_ID', // Replace with your Razorpay key
      'amount': amountInPaise,
      'name': 'House of Sheelaa',
      'description': widget.serviceName,
      'prefill': {
        'contact': authState.phone ?? '',
        'email': authState.email ?? '',
        'name': authState.name ?? 'Guest User',
      },
      'theme': {
        'color': '#FF6B35', // Ecstasy color
      },
      'timeout': 600,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return WillPopScope(
      onWillPop: () async => !_isProcessing,
      child: Scaffold(
        backgroundColor: BrandColors.codGrey,
        appBar: AppBar(
          backgroundColor: BrandColors.codGrey,
          elevation: 0,
          automaticallyImplyLeading: !_isProcessing,
          title: const Text(
            'Payment',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: _buildBody(authState),
      ),
    );
  }

  Widget _buildBody(AuthState authState) {
    if (_paymentStatus == 'processing') {
      return _buildProcessingScreen();
    } else if (_paymentStatus == 'error' || _paymentStatus == 'failed') {
      return _buildErrorScreen();
    } else {
      return _buildPaymentScreen(authState);
    }
  }

  Widget _buildPaymentScreen(AuthState authState) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),

            // Order summary
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Payment method info
            _buildPaymentMethodInfo(),
            const SizedBox(height: 24),

            // Security badge
            _buildSecurityBadge(),
            const SizedBox(height: 32),

            // Payment button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _openRazorpayCheckout(authState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.ecstasy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay with Razorpay',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Payment Button (Testing Mode)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => _handleManualPayment(authState),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BrandColors.ecstasy, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Manual Payment (Testing)',
                  style: TextStyle(
                    color: BrandColors.ecstasy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Other payment methods
            _buildAlternativePaymentMethods(),
            const SizedBox(height: 16),
          ],
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
            color: BrandColors.ecstasy,
          ),
        ),
        _buildStepCircle('3', true),
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

  Widget _buildOrderSummary() {
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
          const Text(
            'Order Summary',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Service', widget.serviceName),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Date & Time',
            '${DateFormat('MMM d, yyyy').format(slot.startTime)} • ${DateFormat('h:mm a').format(slot.startTime)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Consultant', widget.selectedConsultant.name),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: BrandColors.alabaster.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Total Amount', '₹${widget.price.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: BrandColors.alabaster.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: BrandColors.alabaster,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodInfo() {
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
          Row(
            children: [
              Icon(
                Icons.payment,
                color: BrandColors.ecstasy,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Secure Payment via Razorpay',
                style: TextStyle(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We accept all major credit cards, debit cards, UPI, netbanking, and digital wallets through Razorpay.',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrandColors.ecstasy.withValues(alpha: 0.1),
        border: Border.all(
          color: BrandColors.ecstasy,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user,
            color: BrandColors.ecstasy,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Your payment information is secure and encrypted',
            style: TextStyle(
              color: BrandColors.ecstasy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativePaymentMethods() {
    return Center(
      child: Text(
        'Razorpay supports 100+ payment methods',
        style: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.5),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.ecstasy),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing your booking...',
            style: TextStyle(
              color: BrandColors.alabaster,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we confirm your appointment',
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.cardinalPink.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline,
                color: BrandColors.cardinalPink,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _paymentErrorMessage ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BrandColors.alabaster.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _paymentStatus = null;
                    _paymentErrorMessage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.ecstasy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
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
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
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
                  'Go Back',
                  style: TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

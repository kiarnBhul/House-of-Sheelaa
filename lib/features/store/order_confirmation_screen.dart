import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:confetti/confetti.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, String> orderDetails;

  const OrderConfirmationScreen({super.key, required this.orderDetails});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getPaymentMethodName(String id) {
    switch (id) {
      case 'razorpay':
        return 'Razorpay';
      case 'phonepe':
        return 'PhonePe';
      case 'googlepay':
        return 'Google Pay';
      case 'paytm':
        return 'Paytm';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  shouldLoop: false,
                  colors: const [
                    BrandColors.ecstasy,
                    BrandColors.persianRed,
                    BrandColors.alabaster,
                    BrandColors.cardinalPink,
                  ],
                ),
              ),

              // Content
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // Success Icon
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  BrandColors.ecstasy.withValues(alpha: 0.3),
                                  BrandColors.persianRed.withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: BrandColors.ecstasy,
                                width: 3,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: BrandColors.ecstasy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: BrandColors.alabaster,
                                size: 64,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Success Message
                          const Text(
                            'Order Confirmed!',
                            style: TextStyle(
                              color: BrandColors.alabaster,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Thank you for your purchase',
                            style: TextStyle(
                              color: BrandColors.alabaster.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Order Details Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  BrandColors.alabaster.withValues(alpha: 0.2),
                                  BrandColors.alabaster.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: BrandColors.alabaster.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  'Order ID',
                                  widget.orderDetails['orderId'] ?? 'N/A',
                                  Icons.receipt_long_rounded,
                                ),
                                const Divider(
                                  color: BrandColors.alabaster,
                                  thickness: 0.5,
                                  height: 24,
                                ),
                                _buildDetailRow(
                                  'Total Amount',
                                  '₹${widget.orderDetails['totalAmount']}',
                                  Icons.currency_rupee_rounded,
                                  valueColor: BrandColors.ecstasy,
                                ),
                                const Divider(
                                  color: BrandColors.alabaster,
                                  thickness: 0.5,
                                  height: 24,
                                ),
                                _buildDetailRow(
                                  'Items',
                                  '${widget.orderDetails['itemCount']} items',
                                  Icons.shopping_bag_rounded,
                                ),
                                const Divider(
                                  color: BrandColors.alabaster,
                                  thickness: 0.5,
                                  height: 24,
                                ),
                                _buildDetailRow(
                                  'Payment Method',
                                  _getPaymentMethodName(widget.orderDetails['paymentMethod'] ?? ''),
                                  Icons.payment_rounded,
                                ),
                                const Divider(
                                  color: BrandColors.alabaster,
                                  thickness: 0.5,
                                  height: 24,
                                ),
                                _buildDetailRow(
                                  'Order Status',
                                  _getOrderStatusDisplay(widget.orderDetails['orderStatus'] ?? 'pending'),
                                  Icons.track_changes_rounded,
                                  valueColor: _getOrderStatusColor(widget.orderDetails['orderStatus'] ?? 'pending'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Delivery Address Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  BrandColors.alabaster.withValues(alpha: 0.15),
                                  BrandColors.alabaster.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: BrandColors.alabaster.withValues(alpha: 0.3),
                                width: 1.5,
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
                                        color: BrandColors.ecstasy.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: BrandColors.ecstasy,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        color: BrandColors.alabaster,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.orderDetails['name'] ?? '',
                                  style: const TextStyle(
                                    color: BrandColors.alabaster,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.orderDetails['address']}\n'
                                  '${widget.orderDetails['city']}, ${widget.orderDetails['state']} - ${widget.orderDetails['pincode']}\n'
                                  'Phone: ${widget.orderDetails['phone']}',
                                  style: TextStyle(
                                    color: BrandColors.alabaster.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Info Message
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BrandColors.ecstasy.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: BrandColors.ecstasy.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: BrandColors.ecstasy,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Order confirmation has been sent to ${widget.orderDetails['email']}',
                                    style: TextStyle(
                                      color: BrandColors.alabaster.withValues(alpha: 0.9),
                                      fontSize: 13,
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
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Continue Shopping Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  BrandColors.ecstasy,
                                  BrandColors.persianRed,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.ecstasy.withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: BrandColors.alabaster,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Continue Shopping',
                                    style: TextStyle(
                                      color: BrandColors.alabaster,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // View Orders Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  BrandColors.alabaster.withValues(alpha: 0.2),
                                  BrandColors.alabaster.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: BrandColors.alabaster.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Navigate to orders page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Orders page coming soon!'),
                                    backgroundColor: BrandColors.ecstasy,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list_alt_rounded,
                                    color: BrandColors.alabaster,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'View My Orders',
                                    style: TextStyle(
                                      color: BrandColors.alabaster,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: BrandColors.ecstasy,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: BrandColors.alabaster.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? BrandColors.alabaster,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  String _getOrderStatusDisplay(String status) {
    switch (status) {
      case 'draft':
        return '⏳ Pending';
      case 'sale':
        return '✅ Confirmed';
      case 'done':
        return '🎉 Complete';
      case 'cancel':
        return '❌ Cancelled';
      default:
        return '⏳ Pending';
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'sale':
        return Colors.green;
      case 'done':
        return BrandColors.ecstasy;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }}

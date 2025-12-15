import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'state/cart_state.dart';
import 'order_confirmation_screen.dart';
import '../../core/odoo/odoo_api_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> orderDetails;

  const PaymentScreen({super.key, required this.orderDetails});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'razorpay';
  bool _isProcessing = false;
  String _statusMessage = '';

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'razorpay',
      name: 'Razorpay',
      description: 'UPI, Cards, NetBanking & More',
      icon: Icons.payment_rounded,
    ),
    PaymentMethod(
      id: 'phonepe',
      name: 'PhonePe',
      description: 'Pay with PhonePe UPI',
      icon: Icons.phone_android_rounded,
    ),
    PaymentMethod(
      id: 'googlepay',
      name: 'Google Pay',
      description: 'Pay with Google Pay',
      icon: Icons.g_mobiledata_rounded,
    ),
    PaymentMethod(
      id: 'paytm',
      name: 'Paytm',
      description: 'Pay with Paytm Wallet or UPI',
      icon: Icons.account_balance_wallet_rounded,
    ),
    PaymentMethod(
      id: 'cod',
      name: 'Cash on Delivery',
      description: 'Pay when you receive',
      icon: Icons.money_rounded,
    ),
  ];

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing payment...';
    });

    final cart = context.read<CartState>();
    final cartItems = cart.items.values.toList();

    try {
      // Step 1: Simulate payment processing
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Confirming your order...';
      });

      // Step 2: Prepare cart items for Odoo
      final odooCartItems = cartItems.map((item) {
        // Extract product ID from the product.id string
        final productIdStr = item.product.id;
        int? productId;
        
        // Try to parse product ID as integer
        try {
          productId = int.parse(productIdStr);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[Payment] Could not parse product ID: $productIdStr');
          }
          productId = null;
        }

        return {
          'productId': productId,
          'productName': item.product.name,
          'quantity': item.quantity,
          'price': item.product.priceValue.toDouble(),
        };
      }).where((item) => item['productId'] != null).toList();

      if (odooCartItems.isEmpty) {
        throw Exception('No valid products to create order');
      }

      // Step 3: Create sales order in Odoo
      final odooApi = OdooApiService();
      
      if (kDebugMode) {
        debugPrint('[Payment] 📦 Preparing to create order');
        debugPrint('[Payment] Name: ${widget.orderDetails['name']}');
        debugPrint('[Payment] Email: ${widget.orderDetails['email']}');
        debugPrint('[Payment] Phone: ${widget.orderDetails['phone']}');
        debugPrint('[Payment] Address: ${widget.orderDetails['address']}');
      }
      
      final result = await odooApi.createSalesOrderFromCart(
        customerName: widget.orderDetails['name']!,
        customerEmail: widget.orderDetails['email']!,
        customerPhone: widget.orderDetails['phone']!,
        deliveryAddress: widget.orderDetails['address']!,
        city: widget.orderDetails['city']!,
        state: widget.orderDetails['state']!,
        pincode: widget.orderDetails['pincode']!,
        cartItems: odooCartItems,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final saleOrderId = result['saleOrderId'];
        final orderReference = result['orderReference'] ?? 'HOS${DateTime.now().millisecondsSinceEpoch}';
        final orderStatus = result['orderStatus'] ?? 'draft';
        final partnerId = result['partnerId'];

        if (kDebugMode) {
          debugPrint('[Payment] ✅ Sales order created: $orderReference');
          debugPrint('[Payment] 📊 Order status: $orderStatus');
        }

        // Create appointment for each service in the order
        if (partnerId != null && saleOrderId is int) {
          debugPrint('[Payment] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('[Payment] 🎯 STARTING APPOINTMENT CREATION PROCESS');
          debugPrint('[Payment] 📊 Partner ID: $partnerId');
          debugPrint('[Payment] 📊 Sales Order ID: $saleOrderId');
          debugPrint('[Payment] 📊 Order Status: $orderStatus');
          debugPrint('[Payment] ');
          if (orderStatus == 'sale') {
            debugPrint('[Payment] ✅ Order is CONFIRMED - emails WILL be sent');
          } else {
            debugPrint('[Payment] ⏸️  Order is \'$orderStatus\' - emails will NOT be sent yet');
            debugPrint('[Payment] 💡 Confirm the order in Odoo to trigger email notifications');
          }
          debugPrint('[Payment] 📊 Items to process: ${odooCartItems.length}');
          debugPrint('[Payment] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          int successCount = 0;
          int failCount = 0;
          final failedServices = <String>[];
          
          for (var item in odooCartItems) {
            try {
              var serviceName = item['productName'] as String? ?? 'Service';
              final originalName = serviceName;
              
              // Clean up service name to match appointment types
              // E.g., "Manifestation Healing Booking" -> "Manifestation Healing"
              serviceName = serviceName
                  .replaceAll(' Booking', '')
                  .replaceAll(' Service', '')
                  .trim();
              
              debugPrint('[Payment] ');
              debugPrint('[Payment] 🔍 Processing service:');
              debugPrint('[Payment]    Original name: $originalName');
              debugPrint('[Payment]    Cleaned name: $serviceName');
              
              // Schedule appointment for 2 hours from now (can be customized)
              final appointmentDate = DateTime.now().add(const Duration(hours: 2));
              
              debugPrint('[Payment]    Calling createAppointmentFromOrder...');
              
              final appointmentResult = await odooApi.createAppointmentFromOrder(
                partnerId: partnerId,
                customerName: widget.orderDetails['name']!,
                customerEmail: widget.orderDetails['email']!,
                customerPhone: widget.orderDetails['phone']!,
                saleOrderId: saleOrderId,
                serviceName: serviceName,
                appointmentDate: appointmentDate,
                durationMinutes: 15, // Default 15 min duration
                orderStatus: orderStatus, // Pass order status to control email sending
              );

              debugPrint('[Payment]    Response received: ${appointmentResult.keys}');
              
              if (appointmentResult['success'] == true) {
                successCount++;
                debugPrint('[Payment] ✅✅✅ SUCCESS! Appointment created for $serviceName');
                debugPrint('[Payment]    Appointment ID: ${appointmentResult['appointmentId']}');
                debugPrint('[Payment]    Appointment Type ID: ${appointmentResult['appointmentTypeId']}');
                debugPrint('[Payment]    Staff User ID: ${appointmentResult['staffUserId']}');
              } else {
                failCount++;
                failedServices.add(serviceName);
                debugPrint('[Payment] ❌❌❌ FAILED! Could not create appointment');
                debugPrint('[Payment]    Service: $serviceName');
                debugPrint('[Payment]    Error: ${appointmentResult['error']}');
                debugPrint('[Payment]    Full response: $appointmentResult');
              }
            } catch (e, stackTrace) {
              failCount++;
              failedServices.add(item['productName'] as String? ?? 'Unknown');
              debugPrint('[Payment] ❌❌❌ EXCEPTION creating appointment!');
              debugPrint('[Payment]    Service: ${item['productName']}');
              debugPrint('[Payment]    Error: $e');
              debugPrint('[Payment]    Stack: $stackTrace');
            }
          }
          
          debugPrint('[Payment] ');
          debugPrint('[Payment] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('[Payment] 📊 APPOINTMENT CREATION SUMMARY:');
          debugPrint('[Payment]    ✅ Successful: $successCount');
          debugPrint('[Payment]    ❌ Failed: $failCount');
          if (failedServices.isNotEmpty) {
            debugPrint('[Payment]    ⚠️ Failed services: ${failedServices.join(", ")}');
          }
          debugPrint('[Payment] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Show error to user if ALL appointments failed
          if (failCount > 0 && successCount == 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Appointments could not be created. Please contact support. Order ID: $orderReference'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        } else {
          debugPrint('[Payment] ❌ Cannot create appointments - missing partnerId or saleOrderId');
          debugPrint('[Payment]    Partner ID: $partnerId');
          debugPrint('[Payment]    Sale Order ID: $saleOrderId');
        }

        final orderDetails = <String, String>{
          ...widget.orderDetails,
          'paymentMethod': _selectedPaymentMethod,
          'totalAmount': cart.totalAmount.toString(),
          'itemCount': cart.itemCount.toString(),
          'orderDate': DateTime.now().toString(),
          'orderId': orderReference.toString(),
          'saleOrderId': saleOrderId.toString(),
          'orderStatus': orderStatus,
        };

        // Navigate to confirmation and clear cart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderDetails: orderDetails),
          ),
        );

        cart.clearCart();
      } else {
        // Show error but still proceed to confirmation (fallback)
        if (kDebugMode) {
          debugPrint('[Payment] ⚠️ Odoo order creation failed: ${result['error']}');
        }

        final orderDetails = <String, String>{
          ...widget.orderDetails,
          'paymentMethod': _selectedPaymentMethod,
          'totalAmount': cart.totalAmount.toString(),
          'itemCount': cart.itemCount.toString(),
          'orderDate': DateTime.now().toString(),
          'orderId': 'HOS${DateTime.now().millisecondsSinceEpoch}',
        };

        // Show warning dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Placed'),
              content: Text('Your order was placed successfully, but could not be synced to inventory: ${result['error']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    final confirmedOrderDetails = <String, String>{...orderDetails};
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderConfirmationScreen(orderDetails: confirmedOrderDetails),
                      ),
                    );
                    cart.clearCart();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Payment] ❌ Payment processing failed: $e');
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to process order: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BrandColors.alabaster.withValues(alpha: 0.15),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: BrandColors.alabaster),
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Payment',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount to Pay
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
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Amount to Pay',
                              style: TextStyle(
                                color: BrandColors.alabaster.withValues(alpha: 0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${cart.totalAmount}',
                              style: const TextStyle(
                                color: BrandColors.alabaster,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cart.itemCount} items',
                              style: TextStyle(
                                color: BrandColors.alabaster.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Payment Methods Title
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [BrandColors.ecstasy, BrandColors.persianRed],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Select Payment Method',
                            style: TextStyle(
                              color: BrandColors.alabaster,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Payment Methods List
                      ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Pay Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BrandColors.jacaranda.withValues(alpha: 0.0),
                      BrandColors.jacaranda,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Container(
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
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: BrandColors.alabaster,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Text(
                                    _statusMessage.isNotEmpty ? _statusMessage : 'Processing Payment...',
                                    style: const TextStyle(
                                      color: BrandColors.alabaster,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: BrandColors.alabaster,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pay ₹${cart.totalAmount}',
                                  style: const TextStyle(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.id;

    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () {
              setState(() {
                _selectedPaymentMethod = method.id;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    BrandColors.ecstasy.withValues(alpha: 0.3),
                    BrandColors.persianRed.withValues(alpha: 0.2),
                  ]
                : [
                    BrandColors.alabaster.withValues(alpha: 0.15),
                    BrandColors.alabaster.withValues(alpha: 0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? BrandColors.ecstasy
                : BrandColors.alabaster.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? BrandColors.ecstasy.withValues(alpha: 0.3)
                    : BrandColors.alabaster.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method.icon,
                color: isSelected ? BrandColors.ecstasy : BrandColors.alabaster,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      color: BrandColors.alabaster,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: BrandColors.ecstasy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: BrandColors.alabaster,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

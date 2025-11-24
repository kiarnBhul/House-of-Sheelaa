import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

class ShippingPolicyScreen extends StatelessWidget {
  static const String route = '/shipping-policy';
  const ShippingPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                BrandColors.alabaster.withValues(alpha: 0.25),
                BrandColors.alabaster.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: BrandColors.alabaster.withValues(alpha: 0.4),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_rounded,
                color: BrandColors.alabaster,
              ),
            ),
          ),
        ),
        title: Text(
          'Shipping Policy',
          style: tt.headlineSmall?.copyWith(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
              BrandColors.persianRed,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandColors.alabaster.withValues(alpha: 0.15),
                    BrandColors.alabaster.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BrandColors.alabaster.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.codGrey.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipping Policy',
                          style: tt.headlineMedium?.copyWith(
                            color: BrandColors.alabaster,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: November 2024',
                          style: tt.bodyMedium?.copyWith(
                            color: BrandColors.alabaster.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSection(
                          context,
                          'Shipping Locations',
                          'We currently ship to all major cities and towns across India. International shipping may be available for select products. Please contact us for international shipping options and rates.',
                        ),
                        
                        _buildSection(
                          context,
                          'Processing Time',
                          'Orders are typically processed within 1-2 business days after payment confirmation. During peak seasons or special events, processing may take 3-5 business days. You will receive an email confirmation once your order has been shipped.',
                        ),
                        
                        _buildSection(
                          context,
                          'Shipping Methods & Delivery Time',
                          '• Standard Shipping: 5-7 business days\n• Express Shipping: 2-3 business days\n• Same-Day Delivery: Available in select cities (orders placed before 12 PM)\n\nDelivery times are estimates and may vary based on location, weather conditions, and carrier delays.',
                        ),
                        
                        _buildSection(
                          context,
                          'Shipping Costs',
                          'Shipping costs are calculated at checkout based on your location and selected shipping method. Free shipping is available on orders above ₹2,999. Express shipping charges apply as shown during checkout.',
                        ),
                        
                        _buildSection(
                          context,
                          'Order Tracking',
                          'Once your order ships, you will receive a tracking number via email and SMS. You can track your order status in real-time through our app or website using the provided tracking number.',
                        ),
                        
                        _buildSection(
                          context,
                          'Delivery Address',
                          'Please ensure your delivery address is complete and accurate. We are not responsible for delays or failed deliveries due to incorrect addresses. If you need to change your delivery address, please contact us immediately after placing your order.',
                        ),
                        
                        _buildSection(
                          context,
                          'Damaged or Lost Packages',
                          'If your package arrives damaged or is lost in transit, please contact us within 48 hours of delivery. We will investigate and arrange for a replacement or refund. Please keep the original packaging for damaged items.',
                        ),
                        
                        _buildSection(
                          context,
                          'Special Handling',
                          'Some spiritual products may require special handling or packaging. Fragile items like crystals, candles, and ritual tools are carefully packaged to ensure safe delivery. Please handle with care upon receipt.',
                        ),
                        
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.ecstasy.withValues(alpha: 0.3),
                                BrandColors.persianRed.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BrandColors.alabaster.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                color: BrandColors.alabaster,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shipping Inquiries',
                                      style: tt.titleMedium?.copyWith(
                                        color: BrandColors.alabaster,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'For shipping questions, contact us at shipping@houseofsheelaa.com',
                                      style: tt.bodyMedium?.copyWith(
                                        color: BrandColors.alabaster.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final tt = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: tt.bodyLarge?.copyWith(
            color: BrandColors.alabaster.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}



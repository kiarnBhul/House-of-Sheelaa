import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

class RefundPolicyScreen extends StatelessWidget {
  static const String route = '/refund-policy';
  const RefundPolicyScreen({super.key});

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
          'Refund Policy',
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
                          'Refund Policy',
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
                          'Refund Eligibility',
                          'We offer refunds for physical products within 7 days of delivery, provided the item is unused, unopened, and in its original packaging. Digital services and consultations are generally non-refundable once the service has been provided.',
                        ),
                        
                        _buildSection(
                          context,
                          'Refund Process',
                          'To request a refund, please contact our customer support team with your order number and reason for return. We will review your request and provide instructions for returning the item. Once we receive and inspect the returned item, we will process your refund within 5-7 business days.',
                        ),
                        
                        _buildSection(
                          context,
                          'Return Shipping',
                          'Customers are responsible for return shipping costs unless the item was damaged, defective, or incorrect due to our error. In such cases, we will provide a prepaid return label.',
                        ),
                        
                        _buildSection(
                          context,
                          'Non-Refundable Items',
                          'The following items are not eligible for refund: personalized or custom-made products, digital downloads, gift cards, services that have been completed, and items damaged due to misuse or normal wear.',
                        ),
                        
                        _buildSection(
                          context,
                          'Refund Method',
                          'Refunds will be issued to the original payment method used for the purchase. Processing times may vary depending on your payment provider, typically taking 5-10 business days to appear in your account.',
                        ),
                        
                        _buildSection(
                          context,
                          'Cancellations',
                          'You may cancel an order before it ships for a full refund. Once an order has been shipped, standard return and refund policies apply. For event bookings, cancellations must be made at least 48 hours before the scheduled time.',
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
                                Icons.support_agent_rounded,
                                color: BrandColors.alabaster,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need Help?',
                                      style: tt.titleMedium?.copyWith(
                                        color: BrandColors.alabaster,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Contact us at support@houseofsheelaa.com or call +91-XXXXX-XXXXX',
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



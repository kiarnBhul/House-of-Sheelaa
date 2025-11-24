import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String route = '/privacy-policy';
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                          'Privacy Policy',
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
                          'Information We Collect',
                          'We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support. This includes personal information like your name, email address, phone number, and spiritual preferences.',
                        ),
                        
                        _buildSection(
                          context,
                          'How We Use Your Information',
                          'We use your information to provide our spiritual services, process transactions, send you important updates, and improve your experience with House of Sheelaa. We may also use your information to personalize content and recommendations.',
                        ),
                        
                        _buildSection(
                          context,
                          'Information Sharing',
                          'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy. We may share information with trusted partners who assist in operating our platform and providing services.',
                        ),
                        
                        _buildSection(
                          context,
                          'Data Security',
                          'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
                        ),
                        
                        _buildSection(
                          context,
                          'Your Rights',
                          'You have the right to access, update, or delete your personal information. You can also opt-out of certain communications and request that we limit the use of your information.',
                        ),
                        
                        _buildSection(
                          context,
                          'Cookies and Tracking',
                          'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content. You can control cookie preferences through your browser settings.',
                        ),
                        
                        _buildSection(
                          context,
                          'Changes to This Policy',
                          'We may update this privacy policy from time to time. We will notify you of any significant changes by posting the new policy on this page and updating the "Last updated" date.',
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
                                Icons.contact_mail_rounded,
                                color: BrandColors.alabaster,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact Us',
                                      style: tt.titleMedium?.copyWith(
                                        color: BrandColors.alabaster,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'If you have questions about this policy, please contact us at privacy@houseofsheelaa.com',
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

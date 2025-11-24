import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

class NumerologyServiceFormScreen extends StatefulWidget {
  final String serviceName;
  final String serviceImage;

  const NumerologyServiceFormScreen({
    super.key,
    required this.serviceName,
    required this.serviceImage,
  });

  static const String route = '/numerology-service-form';

  @override
  State<NumerologyServiceFormScreen> createState() => _NumerologyServiceFormScreenState();
}

class _NumerologyServiceFormScreenState extends State<NumerologyServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _currentNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _babyNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _timeOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _currentNameController.dispose();
    _businessNameController.dispose();
    _babyNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _placeOfBirthController.dispose();
    _timeOfBirthController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: BrandColors.ecstasy,
              onPrimary: BrandColors.alabaster,
              surface: BrandColors.jacaranda,
              onSurface: BrandColors.alabaster,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: BrandColors.ecstasy,
              onPrimary: BrandColors.alabaster,
              surface: BrandColors.jacaranda,
              onSurface: BrandColors.alabaster,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeOfBirthController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Map<String, dynamic> _getServiceDetails() {
    switch (widget.serviceName) {
      case 'Lucky Name Correction':
        return {
          'title': 'Lucky Name Correction Report',
          'description': 'Discover the perfect name that aligns with your numerology chart to attract success, prosperity, and positive energy into your life.',
          'includes': [
            'Detailed analysis of your current name\'s numerological value',
            'Personalized lucky name suggestions based on your birth date',
            'Compatibility analysis with your life path number',
            'Recommendations for name modifications',
            'Impact assessment of name changes on your destiny',
            'Guidance on when and how to implement the name change',
          ],
          'benefits': [
            'Attract positive energy and opportunities',
            'Enhance personal and professional success',
            'Improve relationships and social connections',
            'Align with your true life purpose',
            'Overcome obstacles and challenges',
          ],
          'icon': Icons.auto_awesome_rounded,
          'color': BrandColors.ecstasy,
        };
      case 'Business Name Correction':
        return {
          'title': 'Business Name Correction Report',
          'description': 'Choose a business name that resonates with numerological principles to ensure success, growth, and prosperity for your venture.',
          'includes': [
            'Analysis of current business name\'s numerological impact',
            'Business name suggestions aligned with your birth date',
            'Compatibility with your business goals and vision',
            'Numerological assessment of brand identity',
            'Recommendations for optimal business naming',
            'Guidance on rebranding strategies if needed',
          ],
          'benefits': [
            'Attract customers and business opportunities',
            'Enhance brand recognition and reputation',
            'Improve financial growth and stability',
            'Create positive business relationships',
            'Align business with success-oriented energy',
          ],
          'icon': Icons.business_rounded,
          'color': BrandColors.persianRed,
        };
      case 'Baby Name Correction':
        return {
          'title': 'Baby Name Correction Report',
          'description': 'Select the perfect name for your baby that brings blessings, good fortune, and a positive life path based on numerology.',
          'includes': [
            'Analysis of baby\'s birth date and numerology chart',
            'Personalized baby name suggestions with lucky numbers',
            'Compatibility with parents\' numerology',
            'Life path number analysis for the baby',
            'Recommendations for middle and last names',
            'Guidance on name selection for optimal future',
          ],
          'benefits': [
            'Ensure a blessed and prosperous future for your child',
            'Attract positive energy and opportunities',
            'Enhance natural talents and abilities',
            'Create harmonious family relationships',
            'Set foundation for success and happiness',
          ],
          'icon': Icons.child_care_rounded,
          'color': BrandColors.goldAccent,
        };
      case 'Lucky Letters for Baby Name':
        return {
          'title': 'Lucky Letters for Baby Name',
          'description': 'Discover the most auspicious letters for your baby\'s name that align with numerology and bring good fortune.',
          'includes': [
            'Analysis of baby\'s birth date numerology',
            'Lucky letter combinations based on birth chart',
            'Personalized letter suggestions for first, middle, and last names',
            'Compatibility analysis with family numerology',
            'Recommendations for name structure',
            'Guidance on combining lucky letters effectively',
          ],
          'benefits': [
            'Choose names with positive numerological energy',
            'Enhance your child\'s natural talents',
            'Attract opportunities and success',
            'Create harmony with family energy',
            'Ensure a blessed life path',
          ],
          'icon': Icons.text_fields_rounded,
          'color': BrandColors.purpleLight,
        };
      default:
        return {
          'title': widget.serviceName,
          'description': 'Get personalized numerology guidance based on your unique birth details.',
          'includes': [
            'Detailed numerology analysis',
            'Personalized recommendations',
            'Comprehensive report',
          ],
          'benefits': [
            'Gain insights into your life path',
            'Make informed decisions',
            'Attract positive energy',
          ],
          'icon': Icons.numbers_rounded,
          'color': BrandColors.ecstasy,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final serviceDetails = _getServiceDetails();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: Colors.transparent,
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
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      serviceDetails['title'] as String,
                      style: tt.titleMedium?.copyWith(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Overview Card
                        Container(
                          padding: const EdgeInsets.all(20),
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
                              width: 1.5,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              (serviceDetails['color'] as Color).withValues(alpha: 0.8),
                                              (serviceDetails['color'] as Color).withValues(alpha: 0.6),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          serviceDetails['icon'] as IconData,
                                          color: BrandColors.alabaster,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              serviceDetails['title'] as String,
                                              style: tt.headlineSmall?.copyWith(
                                                color: BrandColors.alabaster,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Duration: 15 minutes',
                                              style: tt.bodyMedium?.copyWith(
                                                color: BrandColors.alabaster.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    serviceDetails['description'] as String,
                                    style: tt.bodyLarge?.copyWith(
                                      color: BrandColors.alabaster.withValues(alpha: 0.9),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // What's Included Section
                        _buildSection(
                          context,
                          'What\'s Included',
                          serviceDetails['includes'] as List<String>,
                          Icons.check_circle_outline_rounded,
                          BrandColors.ecstasy,
                        ),
                        const SizedBox(height: 20),
                        // Benefits Section
                        _buildSection(
                          context,
                          'Benefits',
                          serviceDetails['benefits'] as List<String>,
                          Icons.star_outline_rounded,
                          BrandColors.goldAccent,
                        ),
                        const SizedBox(height: 20),
                        // Form Section
                        Container(
                          padding: const EdgeInsets.all(20),
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
                              width: 1.5,
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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fill Your Details',
                                      style: tt.headlineSmall?.copyWith(
                                        color: BrandColors.alabaster,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      controller: _fullNameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline_rounded,
                                      required: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _dateOfBirthController,
                                      label: 'Date of Birth',
                                      icon: Icons.calendar_today_outlined,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      required: true,
                                    ),
                                    if (widget.serviceName == 'Lucky Name Correction' ||
                                        widget.serviceName == 'Business Name Correction')
                                      ...[
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: widget.serviceName == 'Lucky Name Correction'
                                              ? _currentNameController
                                              : _businessNameController,
                                          label: widget.serviceName == 'Lucky Name Correction'
                                              ? 'Current Name'
                                              : 'Current Business Name',
                                          icon: Icons.badge_outlined,
                                          required: true,
                                        ),
                                      ],
                                    if (widget.serviceName == 'Baby Name Correction' ||
                                        widget.serviceName == 'Lucky Letters for Baby Name')
                                      ...[
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _babyNameController,
                                          label: 'Baby\'s Name (if already chosen)',
                                          icon: Icons.child_care_outlined,
                                          required: false,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _fatherNameController,
                                          label: 'Father\'s Name',
                                          icon: Icons.man_outlined,
                                          required: true,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _motherNameController,
                                          label: 'Mother\'s Name',
                                          icon: Icons.woman_outlined,
                                          required: true,
                                        ),
                                      ],
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _placeOfBirthController,
                                      label: 'Place of Birth',
                                      icon: Icons.location_on_outlined,
                                      required: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _timeOfBirthController,
                                      label: 'Time of Birth (if known)',
                                      icon: Icons.access_time_outlined,
                                      readOnly: true,
                                      onTap: () => _selectTime(context),
                                      required: false,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      required: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      required: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _additionalInfoController,
                                      label: 'Additional Information (Optional)',
                                      icon: Icons.note_outlined,
                                      maxLines: 4,
                                      required: false,
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [BrandColors.ecstasy, BrandColors.persianRed],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: BrandColors.ecstasy.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            // Handle form submission
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Your numerology request for ${widget.serviceName} has been submitted successfully!'),
                                                backgroundColor: BrandColors.ecstasy,
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: BrandColors.alabaster,
                                          minimumSize: const Size.fromHeight(52),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28),
                                          ),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: const Text(
                                          'Submit Request',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
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
          width: 1.5,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: tt.titleLarge?.copyWith(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: tt.bodyMedium?.copyWith(
                              color: BrandColors.alabaster.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    final tt = Theme.of(context).textTheme;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: tt.bodyLarge?.copyWith(color: BrandColors.alabaster),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: BrandColors.ecstasy),
        filled: true,
        fillColor: BrandColors.codGrey.withValues(alpha: 0.25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: BrandColors.ecstasy,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: BrandColors.persianRed,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: BrandColors.persianRed,
            width: 2,
          ),
        ),
        labelStyle: tt.bodyMedium?.copyWith(
          color: BrandColors.alabaster.withValues(alpha: 0.7),
        ),
        hintStyle: tt.bodyMedium?.copyWith(
          color: BrandColors.alabaster.withValues(alpha: 0.5),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (keyboardType == TextInputType.emailAddress) {
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
              }
              if (keyboardType == TextInputType.phone) {
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
              }
              return null;
            }
          : null,
    );
  }
}



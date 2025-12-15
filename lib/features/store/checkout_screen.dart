import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'package:house_of_sheelaa/core/constants/countries_states.dart';
import 'state/cart_state.dart';
import 'payment_screen.dart';
import '../auth/state/auth_state.dart';

class CheckoutScreen extends StatefulWidget {
  static const String route = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    // Auto-populate from user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthState>();
      if (authState.status == AuthStatus.authenticated) {
        _nameController.text = authState.name ?? '';
        _emailController.text = authState.email ?? '';
        _phoneController.text = authState.phone ?? '';
        _addressController.text = authState.street ?? '';
        _cityController.text = authState.city ?? '';
        _selectedCountry = authState.country ?? 'India';
        _selectedState = authState.state;
        _pincodeController.text = authState.pincode ?? '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      final orderDetails = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _selectedState ?? '',
        'pincode': _pincodeController.text,
        'country': _selectedCountry ?? 'India',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(orderDetails: orderDetails),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final cartItems = cart.items.values.toList();

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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Checkout',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Details Section
                        _buildSectionTitle('Customer Details'),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Delivery Address Section
                        _buildSectionTitle('Delivery Address'),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _addressController,
                          label: 'Street Address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter city';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildCountryDropdown(),
                        const SizedBox(height: 12),
                        _buildStateDropdown(),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _pincodeController,
                          label: 'Pincode',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter pincode';
                            }
                            if (value.length != 6) {
                              return 'Please enter a valid 6-digit pincode';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Order Summary
                        _buildSectionTitle('Order Summary'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.alabaster.withValues(alpha: 0.15),
                                BrandColors.alabaster.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: BrandColors.alabaster.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              ...cartItems.map((item) => _buildOrderItem(item)),
                              const Divider(
                                color: BrandColors.alabaster,
                                thickness: 1,
                                height: 24,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      color: BrandColors.alabaster,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '₹${cart.totalAmount}',
                                    style: const TextStyle(
                                      color: BrandColors.ecstasy,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),

              // Proceed Button
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
                      onPressed: _proceedToPayment,
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
                            Icons.payment_rounded,
                            color: BrandColors.alabaster,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Proceed to Payment',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            color: BrandColors.alabaster,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: BrandColors.alabaster,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: BrandColors.ecstasy, size: 20),
        ),
        filled: true,
        fillColor: BrandColors.codGrey.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.2),
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
        errorStyle: const TextStyle(
          color: BrandColors.persianRed,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      dropdownColor: BrandColors.codGrey,
      style: const TextStyle(color: BrandColors.alabaster, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: BrandColors.codGrey.withValues(alpha: 0.6),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.public_outlined, color: BrandColors.ecstasy, size: 20),
        ),
        labelText: 'Country',
        labelStyle: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'Select Country',
        hintStyle: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.2),
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
      ),
      items: CountryStateData.getCountries().map((country) {
        return DropdownMenuItem(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _selectedState = null;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select country';
        }
        return null;
      },
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      dropdownColor: BrandColors.codGrey,
      style: const TextStyle(color: BrandColors.alabaster, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: BrandColors.codGrey.withValues(alpha: 0.6),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrandColors.ecstasy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.map_outlined, color: BrandColors.ecstasy, size: 20),
        ),
        labelText: 'State',
        labelStyle: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'Select State',
        hintStyle: TextStyle(
          color: BrandColors.alabaster.withValues(alpha: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.2),
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
      ),
      items: _selectedCountry == null
          ? []
          : CountryStateData.getStates(_selectedCountry!).map((state) {
              return DropdownMenuItem(
                value: state,
                child: Text(state),
              );
            }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedState = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select state';
        }
        return null;
      },
    );
  }

  Widget _buildOrderItem(dynamic cartItem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(cartItem.product.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${cartItem.quantity}',
                  style: TextStyle(
                    color: BrandColors.alabaster.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${cartItem.totalPrice}',
            style: const TextStyle(
              color: BrandColors.ecstasy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/odoo_models.dart';
import '../../theme/brand_theme.dart';

/// Non-Appointment Healing Service Purchase Screen
/// For healing services that don't require appointment booking
class HealingPurchaseScreen extends StatefulWidget {
  final OdooService service;

  const HealingPurchaseScreen({
    super.key,
    required this.service,
  });

  @override
  State<HealingPurchaseScreen> createState() => _HealingPurchaseScreenState();
}

class _HealingPurchaseScreenState extends State<HealingPurchaseScreen> {
  int _quantity = 1;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement cart functionality
    // For now, show success dialog
    _showSuccessDialog();
  }

  void _buyNow() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement direct purchase/checkout
    // For now, show success dialog
    _showPurchaseDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: BrandColors.ecstasy),
            const SizedBox(width: 12),
            const Text('Added to Cart'),
          ],
        ),
        content: Text('${widget.service.name} has been added to your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to cart
            },
            child: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: BrandColors.ecstasy),
            const SizedBox(width: 12),
            const Text('Order Placed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order has been placed successfully!'),
            const SizedBox(height: 16),
            Text(
              'Service: ${widget.service.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Quantity: $_quantity'),
            Text('Total: ₹${(widget.service.price * _quantity).toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text('You will receive an email confirmation shortly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        backgroundColor: BrandColors.ecstasy,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            _buildServiceImage(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name and Price
                  Text(
                    widget.service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.service.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.ecstasy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (widget.service.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.service.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Quantity Selector
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),
                  
                  // Customer Details Form
                  _buildCustomerDetailsForm(),
                  const SizedBox(height: 24),
                  
                  // Total Price Card
                  _buildTotalPriceCard(),
                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildServiceImage() {
    if (widget.service.imageUrl == null) {
      return Container(
        width: double.infinity,
        height: 250,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 64, color: Colors.grey),
      );
    }

    return Image.network(
      widget.service.imageUrl!,
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 250,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: BrandColors.ecstasy,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: BrandColors.ecstasy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address (Optional)',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Special Requests (Optional)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPriceCard() {
    final total = widget.service.price * _quantity;

    return Card(
      color: BrandColors.ecstasy.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text(
                  '₹${widget.service.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity', style: TextStyle(fontSize: 16)),
                Text('× $_quantity', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BrandColors.ecstasy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: BrandColors.ecstasy, width: 2),
                  foregroundColor: BrandColors.ecstasy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.ecstasy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

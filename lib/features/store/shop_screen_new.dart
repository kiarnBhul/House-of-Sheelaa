import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'models/product_model.dart';
import 'products_data.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'state/cart_state.dart';
import '../../core/odoo/odoo_state.dart';

class ShopScreenNew extends StatefulWidget {
  const ShopScreenNew({super.key});
  static const String route = '/shop';
  @override
  State<ShopScreenNew> createState() => _ShopScreenNewState();
}

class _ShopScreenNewState extends State<ShopScreenNew> {
  String query = '';
  String selectedCategory = 'All';
  String sortBy = 'Name';
  final List<Product> _localProducts = ProductsData.getAllProducts();
  bool _isLoadingOdoo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOdooProducts();
  }

  Future<void> _loadOdooProducts() async {
    final odooState = context.read<OdooState>();
    if (odooState.isAuthenticated && odooState.products.isEmpty) {
      setState(() => _isLoadingOdoo = true);
      await odooState.loadProducts();
      if (mounted) {
        setState(() => _isLoadingOdoo = false);
      }
    }
  }

  List<Product> get _allProducts {
    final odooState = context.watch<OdooState>();
    
    // Use Odoo products if available, otherwise use local products
    if (odooState.isAuthenticated && odooState.products.isNotEmpty) {
      return odooState.products.map((odooProduct) {
        return Product(
          id: 'odoo_${odooProduct.id}',
          name: odooProduct.name,
          subtitle: odooProduct.categoryName ?? 'Spiritual Product',
          description: odooProduct.description ?? 'Premium spiritual product from House of Sheelaa',
          price: '₹${odooProduct.price.toStringAsFixed(0)}',
          priceValue: odooProduct.price.toInt(),
          image: odooProduct.imageUrl ?? 'assets/images/spiritual_products.jpg',
          category: odooProduct.categoryName ?? 'Other',
          benefits: [],
          rating: 4.5,
          reviewCount: 0,
        );
      }).toList();
    }
    
    return _localProducts;
  }

  List<String> get _categories {
    final odooState = context.watch<OdooState>();
    final categories = <String>{'All'};
    
    if (odooState.isAuthenticated && odooState.products.isNotEmpty) {
      for (var product in odooState.products) {
        if (product.categoryName != null && product.categoryName!.isNotEmpty) {
          categories.add(product.categoryName!);
        }
      }
    } else {
      categories.addAll(ProductsData.getCategories());
    }
    
    return categories.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final categories = _categories;
    
    // Filter products
    List<Product> filteredProducts = _allProducts;
    
    // Filter by search
    if (query.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(query.toLowerCase())).toList();
    }
    
    // Filter by category
    if (selectedCategory != 'All') {
      filteredProducts = filteredProducts.where((p) => p.category == selectedCategory).toList();
    }
    
    // Sort products
    if (sortBy == 'Name') {
      filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    } else if (sortBy == 'Price: Low to High') {
      filteredProducts.sort((a, b) => a.priceValue.compareTo(b.priceValue));
    } else if (sortBy == 'Price: High to Low') {
      filteredProducts.sort((a, b) => b.priceValue.compareTo(a.priceValue));
    } else if (sortBy == 'Rating') {
      filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
    }
    
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
                      'Shop',
                      style: TextStyle(
                        color: BrandColors.alabaster,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    // Refresh/Odoo Status Button
                    Consumer<OdooState>(
                      builder: (context, odooState, child) {
                        if (odooState.isAuthenticated) {
                          return IconButton(
                            icon: _isLoadingOdoo
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(BrandColors.ecstasy),
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, color: BrandColors.ecstasy),
                            onPressed: _isLoadingOdoo ? null : () async {
                              setState(() => _isLoadingOdoo = true);
                              await odooState.loadProducts();
                              if (mounted) {
                                setState(() => _isLoadingOdoo = false);
                              }
                            },
                            tooltip: 'Refresh from Odoo',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(width: 8),
                    // Cart Icon with Badge
                    Stack(
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
                            icon: const Icon(Icons.shopping_cart_rounded, color: BrandColors.alabaster),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CartScreen()),
                              );
                            },
                          ),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    BrandColors.ecstasy,
                                    BrandColors.persianRed,
                                  ],
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: BrandColors.alabaster,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.alabaster.withValues(alpha: 0.18),
                        BrandColors.alabaster.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: BrandColors.alabaster.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        color: BrandColors.alabaster.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: BrandColors.ecstasy,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: BrandColors.ecstasy,
                        ),
                        onPressed: () => _showFilterBottomSheet(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        BrandColors.ecstasy,
                                        BrandColors.persianRed,
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : BrandColors.alabaster.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? BrandColors.ecstasy
                                    : BrandColors.alabaster.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: BrandColors.ecstasy.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: BrandColors.alabaster,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: isSelected ? 14 : 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Products Grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 80,
                              color: BrandColors.alabaster.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                color: BrandColors.alabaster.withValues(alpha: 0.8),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                color: BrandColors.alabaster.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                            context,
                            filteredProducts[index],
                            cart,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, CartState cart) {
    final isInCart = cart.isInCart(product.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.alabaster.withValues(alpha: 0.18),
              BrandColors.alabaster.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: BrandColors.alabaster.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.codGrey.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.asset(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.jacaranda,
                                BrandColors.cardinalPink,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.self_improvement,
                              size: 60,
                              color: BrandColors.alabaster,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isInCart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BrandColors.ecstasy,
                              BrandColors.persianRed,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.codGrey.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: BrandColors.alabaster,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cart.getQuantity(product.id)}',
                              style: const TextStyle(
                                color: BrandColors.alabaster,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < product.rating.floor()
                              ? Icons.star_rounded
                              : (index < product.rating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                          color: BrandColors.ecstasy,
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(
                          color: BrandColors.alabaster.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and Add Button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.price,
                          style: const TextStyle(
                            color: BrandColors.ecstasy,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BrandColors.ecstasy,
                              BrandColors.persianRed,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.ecstasy.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              cart.addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added!'),
                                  backgroundColor: BrandColors.ecstasy,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                isInCart ? Icons.add_rounded : Icons.shopping_cart_rounded,
                                color: BrandColors.alabaster,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BrandColors.jacaranda,
                BrandColors.cardinalPink,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: BrandColors.ecstasy,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      color: BrandColors.alabaster,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: BrandColors.alabaster),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...[
                'Name',
                'Price: Low to High',
                'Price: High to Low',
                'Rating',
              ].map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => sortBy = option);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: sortBy == option
                              ? const LinearGradient(
                                  colors: [
                                    BrandColors.ecstasy,
                                    BrandColors.persianRed,
                                  ],
                                )
                              : null,
                          color: sortBy == option
                              ? null
                              : BrandColors.alabaster.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sortBy == option
                                ? BrandColors.ecstasy
                                : BrandColors.alabaster.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sortBy == option
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: BrandColors.alabaster,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              option,
                              style: TextStyle(
                                color: BrandColors.alabaster,
                                fontWeight: sortBy == option ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}


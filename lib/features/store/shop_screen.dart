import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'models/product_model.dart';
import 'products_data.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'state/cart_state.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  static const String route = '/shop';
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String query = '';
  final List<Product> allProducts = ProductsData.getAllProducts();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cart = context.watch<CartState>();
    
    // Filter products by search query
    final filteredProducts = query.isEmpty
        ? allProducts
        : allProducts.where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.subtitle.toLowerCase().contains(query.toLowerCase())).toList();
    
    // Group by category
    final Map<String, List<Product>> groupedProducts = {};
    for (var product in filteredProducts) {
      if (!groupedProducts.containsKey(product.category)) {
        groupedProducts[product.category] = [];
      }
      groupedProducts[product.category]!.add(product);
    }
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BrandColors.alabaster,
        actions: [
          // Cart Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
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
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
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
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: tt.bodyMedium?.copyWith(
                  color: BrandColors.alabaster,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for products…',
                  hintStyle: TextStyle(
                    color: BrandColors.alabaster.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BrandColors.ecstasy,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (groupedProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: BrandColors.alabaster.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          color: BrandColors.alabaster.withValues(alpha: 0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final category in groupedProducts.keys) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BrandColors.ecstasy,
                              BrandColors.persianRed,
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category,
                        style: const TextStyle(
                          color: BrandColors.alabaster,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: BrandColors.codGrey,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupedProducts[category]!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (ctx, i) {
                    final product = groupedProducts[category]![i];
                    return _productTile(context, product, cart);
                  },
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }

  Widget _productTile(BuildContext context, Product product, CartState cart) {
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
              BrandColors.alabaster.withValues(alpha: 0.15),
              BrandColors.alabaster.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BrandColors.alabaster.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.codGrey.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _productImageFallback(product);
                      },
                    ),
                  ),
                  if (isInCart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BrandColors.ecstasy,
                              BrandColors.persianRed,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.codGrey.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: BrandColors.alabaster,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cart.getQuantity(product.id)}',
                              style: const TextStyle(
                                color: BrandColors.alabaster,
                                fontSize: 12,
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
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.price,
                          style: const TextStyle(
                            color: BrandColors.ecstasy,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
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
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.ecstasy.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              cart.addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to cart!'),
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
                              padding: const EdgeInsets.all(8),
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

  Widget _productImageFallback(Product product) {
    IconData icon;
    final name = product.name.toLowerCase();
    if (name.contains('bracelet')) {
      icon = Icons.link;
    } else if (name.contains('spray')) {
      icon = Icons.water_drop;
    } else if (name.contains('salt')) {
      icon = Icons.grain;
    } else if (name.contains('soap')) {
      icon = Icons.soap;
    } else {
      icon = Icons.self_improvement;
    }
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.jacaranda,
            BrandColors.cardinalPink,
            BrandColors.ecstasy,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: BrandColors.alabaster, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BrandColors.alabaster,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
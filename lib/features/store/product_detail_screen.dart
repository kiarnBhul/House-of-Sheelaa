import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'models/product_model.dart';
import 'state/cart_state.dart';

class ProductDetailScreen extends StatelessWidget {
  static const String route = '/product-detail';
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final isInCart = cart.isInCart(product.id);
    final quantity = cart.getQuantity(product.id);

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
                    const Spacer(),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Product Image
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.codGrey.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    BrandColors.jacaranda,
                                    BrandColors.cardinalPink,
                                    BrandColors.ecstasy,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.self_improvement,
                                  size: 80,
                                  color: BrandColors.alabaster.withValues(alpha: 0.8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Product Name & Price
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BrandColors.alabaster.withValues(alpha: 0.18),
                            BrandColors.alabaster.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: BrandColors.alabaster,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.subtitle,
                            style: TextStyle(
                              color: BrandColors.alabaster.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      BrandColors.ecstasy,
                                      BrandColors.persianRed,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BrandColors.ecstasy.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  product.price,
                                  style: const TextStyle(
                                    color: BrandColors.alabaster,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (isInCart)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColors.alabaster.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: BrandColors.alabaster.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: BrandColors.ecstasy,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'In Cart: $quantity',
                                        style: const TextStyle(
                                          color: BrandColors.alabaster,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BrandColors.alabaster.withValues(alpha: 0.15),
                            BrandColors.alabaster.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: BrandColors.ecstasy,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'About Product',
                                style: TextStyle(
                                  color: BrandColors.alabaster,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            product.description,
                            style: TextStyle(
                              color: BrandColors.alabaster.withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Benefits Section
                    if (product.benefits.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BrandColors.alabaster.withValues(alpha: 0.15),
                              BrandColors.alabaster.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: BrandColors.alabaster.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: BrandColors.ecstasy,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Benefits',
                                  style: TextStyle(
                                    color: BrandColors.alabaster,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...product.benefits.map(
                              (benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: BrandColors.ecstasy,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: TextStyle(
                                          color: BrandColors.alabaster.withValues(alpha: 0.85),
                                          fontSize: 15,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Reviews Section
                    if (product.reviews.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BrandColors.alabaster.withValues(alpha: 0.15),
                              BrandColors.alabaster.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
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
                                const Icon(
                                  Icons.rate_review_rounded,
                                  color: BrandColors.ecstasy,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Customer Reviews',
                                  style: TextStyle(
                                    color: BrandColors.alabaster,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
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
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: BrandColors.alabaster,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        product.rating.toString(),
                                        style: const TextStyle(
                                          color: BrandColors.alabaster,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Based on ${product.reviewCount} reviews',
                              style: TextStyle(
                                color: BrandColors.alabaster.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...product.reviews.map((review) => _buildReviewCard(review)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Add to Cart Button
      bottomNavigationBar: Container(
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
              onPressed: () {
                cart.addItem(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart!'),
                    backgroundColor: BrandColors.ecstasy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    duration: const Duration(seconds: 2),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_rounded,
                    color: BrandColors.alabaster,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isInCart ? 'Add More to Cart' : 'Add to Cart',
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
    );
  }

  Widget _buildReviewCard(Review review) {
    final timeAgo = _formatDate(review.date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.alabaster.withValues(alpha: 0.12),
            BrandColors.alabaster.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.alabaster.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      BrandColors.ecstasy,
                      BrandColors.persianRed,
                    ],
                  ),
                ),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: BrandColors.alabaster,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: BrandColors.alabaster.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.alabaster.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: BrandColors.ecstasy,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              color: BrandColors.alabaster.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}


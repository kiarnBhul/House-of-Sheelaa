class Product {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String price;
  final int priceValue;
  final String image;
  final String category;
  final List<String> benefits;
  final double rating;
  final int reviewCount;
  final List<Review> reviews;

  Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.priceValue,
    required this.image,
    required this.category,
    required this.benefits,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.reviews = const [],
  });
}

class Review {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  int get totalPrice => product.priceValue * quantity;
}


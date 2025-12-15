/// Cart item model for non-appointment services
class CartItem {
  final int serviceId;
  final String serviceName;
  final double price;
  final String? imageUrl;
  final String? description;
  int quantity;

  CartItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    this.imageUrl,
    this.description,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

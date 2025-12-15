import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/odoo_models.dart';

/// Shopping cart service for digital/instant services (non-appointment)
/// Persists cart items locally using SharedPreferences
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _items = [];
  bool _isLoaded = false;

  static const String _storageKey = 'shopping_cart_items';

  /// Get all cart items
  List<CartItem> get items => List.unmodifiable(_items);

  /// Get total number of items
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Get total price
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Initialize cart by loading from storage
  Future<void> init() async {
    if (_isLoaded) return;
    await _loadFromStorage();
    _isLoaded = true;
  }

  /// Add service to cart
  Future<void> addItem(OdooService service) async {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item.serviceId == service.id);
    
    if (existingIndex >= 0) {
      // Increment quantity
      _items[existingIndex].quantity++;
    } else {
      // Add new item
      _items.add(CartItem(
        serviceId: service.id,
        serviceName: service.name,
        price: service.price,
        imageUrl: service.imageUrl,
        description: service.description,
        quantity: 1,
      ));
    }

    await _saveToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('🛒 Added to cart: ${service.name} (Total items: $itemCount)');
    }
  }

  /// Remove item from cart
  Future<void> removeItem(int serviceId) async {
    _items.removeWhere((item) => item.serviceId == serviceId);
    await _saveToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('🛒 Removed from cart: $serviceId (Total items: $itemCount)');
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(int serviceId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(serviceId);
      return;
    }

    final index = _items.indexWhere((item) => item.serviceId == serviceId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      await _saveToStorage();
      notifyListeners();
    }
  }

  /// Clear all items from cart
  Future<void> clear() async {
    _items.clear();
    await _saveToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('🛒 Cart cleared');
    }
  }

  /// Check if a service is in the cart
  bool isInCart(int serviceId) {
    return _items.any((item) => item.serviceId == serviceId);
  }

  /// Get quantity of a specific service in cart
  int getQuantity(int serviceId) {
    final item = _items.firstWhere(
      (item) => item.serviceId == serviceId,
      orElse: () => CartItem(serviceId: -1, serviceName: '', price: 0),
    );
    return item.serviceId == -1 ? 0 : item.quantity;
  }

  /// Save cart to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save cart: $e');
      }
    }
  }

  /// Load cart from SharedPreferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List;
        _items = jsonList.map((json) => CartItem.fromJson(json)).toList();
        
        if (kDebugMode) {
          debugPrint('🛒 Cart loaded: $itemCount items, total: ₹${totalPrice.toStringAsFixed(0)}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load cart: $e');
      }
      _items = [];
    }
  }
}

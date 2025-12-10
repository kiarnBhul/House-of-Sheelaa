import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/odoo_models.dart';

/// Cache for Odoo data to enable instant display on app startup
class OdooCache {
  static const String _keyProducts = 'odoo_cache_products';
  static const String _keyServices = 'odoo_cache_services';
  static const String _keyCategories = 'odoo_cache_categories';
  static const String _keyLastUpdate = 'odoo_cache_last_update';

  /// Save products to cache
  static Future<void> saveProducts(List<OdooProduct> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_keyProducts, jsonEncode(jsonList));
      await _updateTimestamp();
      if (kDebugMode) debugPrint('[OdooCache] Cached ${products.length} products');
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error caching products: $e');
    }
  }

  /// Save services to cache
  static Future<void> saveServices(List<OdooService> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = services.map((s) => s.toJson()).toList();
      await prefs.setString(_keyServices, jsonEncode(jsonList));
      await _updateTimestamp();
      if (kDebugMode) debugPrint('[OdooCache] Cached ${services.length} services');
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error caching services: $e');
    }
  }

  /// Save categories to cache
  static Future<void> saveCategories(List<OdooCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((c) => c.toJson()).toList();
      await prefs.setString(_keyCategories, jsonEncode(jsonList));
      await _updateTimestamp();
      if (kDebugMode) debugPrint('[OdooCache] Cached ${categories.length} categories');
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error caching categories: $e');
    }
  }

  /// Load products from cache
  static Future<List<OdooProduct>?> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyProducts);
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      final products = jsonList
          .map((json) => OdooProduct.fromJson(json as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) debugPrint('[OdooCache] Loaded ${products.length} products from cache');
      return products;
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error loading products: $e');
      return null;
    }
  }

  /// Load services from cache
  static Future<List<OdooService>?> loadServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyServices);
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      final services = jsonList
          .map((json) => OdooService.fromJson(json as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) debugPrint('[OdooCache] Loaded ${services.length} services from cache');
      return services;
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error loading services: $e');
      return null;
    }
  }

  /// Load categories from cache
  static Future<List<OdooCategory>?> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCategories);
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      final categories = jsonList
          .map((json) => OdooCategory.fromJson(json as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) debugPrint('[OdooCache] Loaded ${categories.length} categories from cache');
      return categories;
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error loading categories: $e');
      return null;
    }
  }

  /// Get cache age in hours
  static Future<int?> getCacheAgeHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyLastUpdate);
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);
      return age.inHours;
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is stale (older than 24 hours)
  static Future<bool> isCacheStale() async {
    final age = await getCacheAgeHours();
    if (age == null) return true;
    return age > 24;
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProducts);
      await prefs.remove(_keyServices);
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyLastUpdate);
      if (kDebugMode) debugPrint('[OdooCache] Cache cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('[OdooCache] Error clearing cache: $e');
    }
  }

  static Future<void> _updateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
  }
}

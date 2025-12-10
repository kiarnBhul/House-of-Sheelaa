import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/odoo_models.dart';

/// Phase 1: Local Product Caching Service
/// Stores products, services, categories, and appointment types locally
/// for instant loading on app restart
class ProductCacheService {
  static const String _keyProducts = 'cached_products';
  static const String _keyServices = 'cached_services';
  static const String _keyCategories = 'cached_categories';
  static const String _keyAppointmentTypes = 'cached_appointment_types';
  static const String _keyProductsTimestamp = 'cached_products_timestamp';
  static const String _keyServicesTimestamp = 'cached_services_timestamp';
  static const String _keyCategoriesTimestamp = 'cached_categories_timestamp';
  static const String _keyAppointmentTypesTimestamp = 'cached_appointment_types_timestamp';
  
  /// Cache products to local storage
  static Future<bool> cacheProducts(List<OdooProduct> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_keyProducts, jsonString);
      await prefs.setInt(_keyProductsTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Cached ${products.length} products');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to cache products: $e');
      }
      return false;
    }
  }
  
  /// Cache services to local storage
  static Future<bool> cacheServices(List<OdooService> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = services.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_keyServices, jsonString);
      await prefs.setInt(_keyServicesTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Cached ${services.length} services');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to cache services: $e');
      }
      return false;
    }
  }
  
  /// Cache categories to local storage
  static Future<bool> cacheCategories(List<OdooCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_keyCategories, jsonString);
      await prefs.setInt(_keyCategoriesTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Cached ${categories.length} categories');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to cache categories: $e');
      }
      return false;
    }
  }
  
  /// Cache appointment types to local storage
  static Future<bool> cacheAppointmentTypes(List<OdooAppointmentType> appointmentTypes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = appointmentTypes.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_keyAppointmentTypes, jsonString);
      await prefs.setInt(_keyAppointmentTypesTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Cached ${appointmentTypes.length} appointment types');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to cache appointment types: $e');
      }
      return false;
    }
  }
  
  /// Load cached products from local storage
  static Future<List<OdooProduct>?> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyProducts);
      
      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[ProductCache] No cached products found');
        }
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final products = jsonList
          .map((json) => OdooProduct.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final timestamp = prefs.getInt(_keyProductsTimestamp);
      final age = timestamp != null 
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
          : null;
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Loaded ${products.length} cached products (age: ${age?.inHours}h)');
      }
      return products;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to load cached products: $e');
      }
      return null;
    }
  }
  
  /// Load cached services from local storage
  static Future<List<OdooService>?> loadServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyServices);
      
      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[ProductCache] No cached services found');
        }
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final services = jsonList
          .map((json) => OdooService.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final timestamp = prefs.getInt(_keyServicesTimestamp);
      final age = timestamp != null 
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
          : null;
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Loaded ${services.length} cached services (age: ${age?.inHours}h)');
      }
      return services;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to load cached services: $e');
      }
      return null;
    }
  }
  
  /// Load cached categories from local storage
  static Future<List<OdooCategory>?> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCategories);
      
      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[ProductCache] No cached categories found');
        }
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final categories = jsonList
          .map((json) => OdooCategory.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final timestamp = prefs.getInt(_keyCategoriesTimestamp);
      final age = timestamp != null 
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
          : null;
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Loaded ${categories.length} cached categories (age: ${age?.inHours}h)');
      }
      return categories;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to load cached categories: $e');
      }
      return null;
    }
  }
  
  /// Load cached appointment types from local storage
  static Future<List<OdooAppointmentType>?> loadAppointmentTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyAppointmentTypes);
      
      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[ProductCache] No cached appointment types found');
        }
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final appointmentTypes = jsonList
          .map((json) => OdooAppointmentType.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final timestamp = prefs.getInt(_keyAppointmentTypesTimestamp);
      final age = timestamp != null 
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
          : null;
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Loaded ${appointmentTypes.length} cached appointment types (age: ${age?.inHours}h)');
      }
      return appointmentTypes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to load cached appointment types: $e');
      }
      return null;
    }
  }
  
  /// Get cache age for products
  static Future<Duration?> getProductsCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyProductsTimestamp);
      if (timestamp == null) return null;
      return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    } catch (e) {
      return null;
    }
  }
  
  /// Get cache age for services
  static Future<Duration?> getServicesCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyServicesTimestamp);
      if (timestamp == null) return null;
      return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    } catch (e) {
      return null;
    }
  }
  
  /// Clear all cached data
  static Future<bool> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProducts);
      await prefs.remove(_keyServices);
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyAppointmentTypes);
      await prefs.remove(_keyProductsTimestamp);
      await prefs.remove(_keyServicesTimestamp);
      await prefs.remove(_keyCategoriesTimestamp);
      await prefs.remove(_keyAppointmentTypesTimestamp);
      
      if (kDebugMode) {
        debugPrint('[ProductCache] ✅ Cleared all cache');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductCache] ❌ Failed to clear cache: $e');
      }
      return false;
    }
  }
}

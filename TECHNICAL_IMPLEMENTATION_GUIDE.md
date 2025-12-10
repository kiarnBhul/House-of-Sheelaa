# Technical Implementation Guide: Persistent Data Solution

---

## Phase 1: Local Product Caching Service

### File: `lib/core/cache/product_cache_service.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/odoo_models.dart';

class ProductCacheService {
  static const String _keyProducts = 'cached_products';
  static const String _keyServices = 'cached_services';
  static const String _keyCategories = 'cached_categories';
  static const String _keyLastProductsSync = 'last_products_sync';
  static const String _keyLastServicesSync = 'last_services_sync';
  static const String _keyLastCategoriesSync = 'last_categories_sync';
  
  // Cache TTL: 7 days (604800 seconds)
  static const int _cacheTtlSeconds = 604800;
  
  final SharedPreferences _prefs;
  
  ProductCacheService(this._prefs);
  
  /// Save products to cache
  Future<bool> saveProducts(List<OdooProduct> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_keyProducts, jsonString);
      await _prefs.setInt(_keyLastProductsSync, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('[ProductCache] Saved ${products.length} products');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error saving products: $e');
      return false;
    }
  }
  
  /// Load products from cache
  Future<List<OdooProduct>> loadProducts() async {
    try {
      final jsonString = _prefs.getString(_keyProducts);
      if (jsonString == null || jsonString.isEmpty) {
        if (kDebugMode) print('[ProductCache] No cached products found');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final products = jsonList
          .map((item) => OdooProduct.fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        print('[ProductCache] Loaded ${products.length} products from cache');
      }
      return products;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error loading products: $e');
      return [];
    }
  }
  
  /// Save services to cache
  Future<bool> saveServices(List<OdooService> services) async {
    try {
      final jsonList = services.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_keyServices, jsonString);
      await _prefs.setInt(_keyLastServicesSync, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('[ProductCache] Saved ${services.length} services');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error saving services: $e');
      return false;
    }
  }
  
  /// Load services from cache
  Future<List<OdooService>> loadServices() async {
    try {
      final jsonString = _prefs.getString(_keyServices);
      if (jsonString == null || jsonString.isEmpty) {
        if (kDebugMode) print('[ProductCache] No cached services found');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final services = jsonList
          .map((item) => OdooService.fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        print('[ProductCache] Loaded ${services.length} services from cache');
      }
      return services;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error loading services: $e');
      return [];
    }
  }
  
  /// Save categories to cache
  Future<bool> saveCategories(List<OdooCategory> categories) async {
    try {
      final jsonList = categories.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_keyCategories, jsonString);
      await _prefs.setInt(_keyLastCategoriesSync, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('[ProductCache] Saved ${categories.length} categories');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error saving categories: $e');
      return false;
    }
  }
  
  /// Load categories from cache
  Future<List<OdooCategory>> loadCategories() async {
    try {
      final jsonString = _prefs.getString(_keyCategories);
      if (jsonString == null || jsonString.isEmpty) {
        if (kDebugMode) print('[ProductCache] No cached categories found');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final categories = jsonList
          .map((item) => OdooCategory.fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        print('[ProductCache] Loaded ${categories.length} categories from cache');
      }
      return categories;
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error loading categories: $e');
      return [];
    }
  }
  
  /// Check if cache is expired
  bool isCacheExpired({String type = 'products'}) {
    final key = _getLastSyncKey(type);
    final lastSync = _prefs.getInt(key);
    
    if (lastSync == null) {
      if (kDebugMode) print('[ProductCache] No sync timestamp for $type');
      return true;
    }
    
    final age = DateTime.now().millisecondsSinceEpoch - lastSync;
    final isExpired = age > (_cacheTtlSeconds * 1000);
    
    if (kDebugMode) {
      print('[ProductCache] $type cache age: ${(age / 1000 / 3600).toStringAsFixed(1)} hours, expired: $isExpired');
    }
    
    return isExpired;
  }
  
  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'products': {
        'cached': _prefs.containsKey(_keyProducts),
        'count': _prefs.getString(_keyProducts) != null 
            ? (jsonDecode(_prefs.getString(_keyProducts)!) as List).length 
            : 0,
        'lastSync': _prefs.getInt(_keyLastProductsSync),
        'expired': isCacheExpired(type: 'products'),
      },
      'services': {
        'cached': _prefs.containsKey(_keyServices),
        'count': _prefs.getString(_keyServices) != null 
            ? (jsonDecode(_prefs.getString(_keyServices)!) as List).length 
            : 0,
        'lastSync': _prefs.getInt(_keyLastServicesSync),
        'expired': isCacheExpired(type: 'services'),
      },
      'categories': {
        'cached': _prefs.containsKey(_keyCategories),
        'count': _prefs.getString(_keyCategories) != null 
            ? (jsonDecode(_prefs.getString(_keyCategories)!) as List).length 
            : 0,
        'lastSync': _prefs.getInt(_keyLastCategoriesSync),
        'expired': isCacheExpired(type: 'categories'),
      },
    };
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await Future.wait([
        _prefs.remove(_keyProducts),
        _prefs.remove(_keyServices),
        _prefs.remove(_keyCategories),
        _prefs.remove(_keyLastProductsSync),
        _prefs.remove(_keyLastServicesSync),
        _prefs.remove(_keyLastCategoriesSync),
      ]);
      
      if (kDebugMode) print('[ProductCache] Cleared all cache');
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error clearing cache: $e');
    }
  }
  
  /// Clear specific cache type
  Future<void> clearCache(String type) async {
    try {
      final dataKey = _getDataKey(type);
      final syncKey = _getLastSyncKey(type);
      
      await Future.wait([
        _prefs.remove(dataKey),
        _prefs.remove(syncKey),
      ]);
      
      if (kDebugMode) print('[ProductCache] Cleared $type cache');
    } catch (e) {
      if (kDebugMode) print('[ProductCache] Error clearing $type cache: $e');
    }
  }
  
  String _getDataKey(String type) {
    switch (type) {
      case 'products':
        return _keyProducts;
      case 'services':
        return _keyServices;
      case 'categories':
        return _keyCategories;
      default:
        return _keyProducts;
    }
  }
  
  String _getLastSyncKey(String type) {
    switch (type) {
      case 'products':
        return _keyLastProductsSync;
      case 'services':
        return _keyLastServicesSync;
      case 'categories':
        return _keyLastCategoriesSync;
      default:
        return _keyLastProductsSync;
    }
  }
}
```

---

## Integrating Phase 1 into OdooState

### Modifications to `lib/core/odoo/odoo_state.dart`

```dart
// Add at the top with other imports
import '../cache/product_cache_service.dart';

class OdooState extends ChangeNotifier {
  // ... existing code ...
  
  late ProductCacheService _productCacheService;
  
  OdooState() {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('[OdooState] Initializing...');
    
    // Initialize cache service first
    try {
      final prefs = await SharedPreferences.getInstance();
      _productCacheService = ProductCacheService(prefs);
    } catch (e) {
      debugPrint('[OdooState] Error initializing cache service: $e');
    }
    
    // Load local config immediately
    try {
      await OdooConfig.loadConfig().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('[OdooState] Config load timed out'),
      );
      _isAuthenticated = OdooConfig.isAuthenticated;
    } catch (e) {
      debugPrint('[OdooState] Config load error: $e');
      _isAuthenticated = false;
    }
    
    // PHASE 1: Load cached products immediately (for instant UI)
    await _loadCachedProducts();
    
    notifyListeners();
    
    // Continue with async initialization
    _initializeAsync();
  }
  
  /// PHASE 1: Load products from cache
  Future<void> _loadCachedProducts() async {
    try {
      debugPrint('[OdooState] Loading cached products...');
      
      final cachedProducts = await _productCacheService.loadProducts();
      final cachedServices = await _productCacheService.loadServices();
      final cachedCategories = await _productCacheService.loadCategories();
      
      if (cachedProducts.isNotEmpty || cachedServices.isNotEmpty) {
        _products = cachedProducts;
        _services = cachedServices;
        _categories = cachedCategories;
        
        _lastProductsFetch = DateTime.now();
        _lastServicesFetch = DateTime.now();
        _lastCategoriesFetch = DateTime.now();
        
        debugPrint('[OdooState] ✅ Loaded from cache: ${_products.length} products, ${_services.length} services');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OdooState] Error loading cached products: $e');
    }
  }

  void _initializeAsync() {
    Future.microtask(() async {
      try {
        debugPrint('[OdooState] Loading config + auth in background...');
        
        // ... existing global config loading ...
        
        // If already configured, load fresh data
        if (OdooConfig.isConfigured && _isAuthenticated) {
          debugPrint('[OdooState] Loading fresh data from Odoo...');
          await _loadDataInBackground();
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('[OdooState] Async initialization error: $e');
      }
    });
  }

  Future<void> _loadDataInBackground() async {
    try {
      // Fetch fresh products
      final freshProducts = await _apiService.getProducts();
      final freshServices = await _apiService.getServices();
      final freshCategories = await _apiService.getCategories();
      
      if (freshProducts.isNotEmpty) {
        _products = freshProducts;
        _lastProductsFetch = DateTime.now();
        
        // PHASE 1: Save to cache immediately
        unawaited(_productCacheService.saveProducts(freshProducts));
      }
      
      if (freshServices.isNotEmpty) {
        _services = freshServices;
        _lastServicesFetch = DateTime.now();
        
        // PHASE 1: Save to cache
        unawaited(_productCacheService.saveServices(freshServices));
      }
      
      if (freshCategories.isNotEmpty) {
        _categories = freshCategories;
        _lastCategoriesFetch = DateTime.now();
        
        // PHASE 1: Save to cache
        unawaited(_productCacheService.saveCategories(freshCategories));
      }
      
      debugPrint('[OdooState] ✅ Fresh data loaded and cached');
      notifyListeners();
    } catch (e) {
      debugPrint('[OdooState] Error loading fresh data: $e');
      // Don't fail - we have cached data
    }
  }
  
  // Getter to check cache status
  Map<String, dynamic> getCacheStatus() {
    return _productCacheService.getCacheStatus();
  }
  
  // Method to manually refresh cache
  Future<void> refreshCache() async {
    debugPrint('[OdooState] Manual cache refresh requested');
    if (OdooConfig.isConfigured && _isAuthenticated) {
      await _loadDataInBackground();
    }
  }
  
  // Method to clear cache
  Future<void> clearCache() async {
    debugPrint('[OdooState] Clearing cache...');
    await _productCacheService.clearAllCache();
    _products = [];
    _services = [];
    _categories = [];
    notifyListeners();
  }
}
```

---

## Phase 2: Remote Product Cache Service

### File: `lib/core/cache/remote_product_cache_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/odoo_models.dart';

class RemoteProductCacheService {
  static const String _collectionProducts = 'products_cache';
  static const String _fieldProducts = 'products';
  static const String _fieldServices = 'services';
  static const String _fieldCategories = 'categories';
  static const String _fieldLastSync = 'lastSync';
  static const String _fieldSyncStatus = 'syncStatus';
  static const String _fieldVersion = 'version';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get current user ID (should be from auth state)
  String? get _userId {
    // You'll need to inject this or get from FirebaseAuth
    // For now, use a default or admin identifier
    return 'admin'; // Replace with actual user ID
  }
  
  /// Upload products to Firestore
  Future<bool> uploadProducts(
    List<OdooProduct> products, {
    List<OdooService>? services,
    List<OdooCategory>? categories,
  }) async {
    try {
      final userId = _userId ?? 'admin';
      final docRef = _firestore.collection(_collectionProducts).doc(userId);
      
      final data = <String, dynamic>{
        _fieldProducts: products.map((p) => p.toJson()).toList(),
        _fieldServices: services?.map((s) => s.toJson()).toList() ?? [],
        _fieldCategories: categories?.map((c) => c.toJson()).toList() ?? [],
        _fieldLastSync: FieldValue.serverTimestamp(),
        _fieldSyncStatus: 'complete',
        _fieldVersion: 1,
      };
      
      await docRef.set(data, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('[RemoteCache] Uploaded ${products.length} products to Firestore');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[RemoteCache] Error uploading products: $e');
      return false;
    }
  }
  
  /// Download products from Firestore
  Future<Map<String, List<dynamic>>> downloadProducts() async {
    try {
      final userId = _userId ?? 'admin';
      final docRef = _firestore.collection(_collectionProducts).doc(userId);
      final snapshot = await docRef.get();
      
      if (!snapshot.exists) {
        if (kDebugMode) print('[RemoteCache] No remote cache found');
        return {
          'products': [],
          'services': [],
          'categories': [],
        };
      }
      
      final data = snapshot.data() ?? {};
      
      final productsData = data[_fieldProducts] as List? ?? [];
      final servicesData = data[_fieldServices] as List? ?? [];
      final categoriesData = data[_fieldCategories] as List? ?? [];
      
      if (kDebugMode) {
        print('[RemoteCache] Downloaded ${productsData.length} products from Firestore');
      }
      
      return {
        'products': productsData,
        'services': servicesData,
        'categories': categoriesData,
      };
    } catch (e) {
      if (kDebugMode) print('[RemoteCache] Error downloading products: $e');
      return {
        'products': [],
        'services': [],
        'categories': [],
      };
    }
  }
  
  /// Get last remote sync time
  Future<DateTime?> getLastRemoteSyncTime() async {
    try {
      final userId = _userId ?? 'admin';
      final docRef = _firestore.collection(_collectionProducts).doc(userId);
      final snapshot = await docRef.get();
      
      if (!snapshot.exists) return null;
      
      final data = snapshot.data() ?? {};
      final timestamp = data[_fieldLastSync] as Timestamp?;
      
      return timestamp?.toDate();
    } catch (e) {
      if (kDebugMode) print('[RemoteCache] Error getting last sync time: $e');
      return null;
    }
  }
  
  /// Sync products to remote (can be called periodically)
  Future<void> syncProductsToRemote(
    List<OdooProduct> products, {
    List<OdooService>? services,
    List<OdooCategory>? categories,
  }) async {
    try {
      debugPrint('[RemoteCache] Starting sync to Firestore...');
      
      final success = await uploadProducts(
        products,
        services: services,
        categories: categories,
      );
      
      if (success) {
        debugPrint('[RemoteCache] ✅ Sync complete');
      }
    } catch (e) {
      debugPrint('[RemoteCache] Error during sync: $e');
    }
  }
  
  /// Delete remote cache (for cleanup)
  Future<bool> deleteRemoteCache() async {
    try {
      final userId = _userId ?? 'admin';
      await _firestore.collection(_collectionProducts).doc(userId).delete();
      
      if (kDebugMode) print('[RemoteCache] Deleted remote cache');
      return true;
    } catch (e) {
      if (kDebugMode) print('[RemoteCache] Error deleting remote cache: $e');
      return false;
    }
  }
}
```

---

## Phase 3: Auto-Save Configuration

### Modifications to `lib/core/odoo/odoo_config.dart`

Add to the OdooConfig class:

```dart
/// Auto-save configuration to Firestore after successful connection
static Future<bool> saveAndSyncConfig({
  required String baseUrlValue,
  required String databaseValue,
  String? apiKeyValue,
  String? usernameValue,
  String? passwordValue,
  String? proxyUrlValue,
  int? uidValue,
  String? sessionIdValue,
}) async {
  // 1. Save locally first
  await saveConfig(
    baseUrlValue: baseUrlValue,
    databaseValue: databaseValue,
    apiKeyValue: apiKeyValue,
    usernameValue: usernameValue,
    passwordValue: passwordValue,
    proxyUrlValue: proxyUrlValue,
    uidValue: uidValue,
    sessionIdValue: sessionIdValue,
  );
  
  // 2. Schedule background sync to Firestore (don't wait)
  _autoSyncConfigToFirestore();
  
  return true;
}

/// Auto-sync configuration to Firestore (fire and forget)
static void _autoSyncConfigToFirestore() {
  Future.microtask(() async {
    try {
      await saveToFirestore().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            print('[OdooConfig] Firestore sync timeout');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[OdooConfig] Auto-sync to Firestore failed (continuing): $e');
      }
    }
  });
}

/// Load configuration with fallback strategy
static Future<bool> loadConfigWithFallback() async {
  try {
    // 1. Try local first
    await loadConfig();
    if (isConfigured) {
      if (kDebugMode) print('[OdooConfig] ✅ Loaded from local storage');
      return true;
    }
    
    // 2. Try Firestore if local failed
    if (kDebugMode) print('[OdooConfig] Local not found, trying Firestore...');
    final fromFirestore = await loadFromFirestore();
    
    if (fromFirestore) {
      if (kDebugMode) print('[OdooConfig] ✅ Loaded from Firestore');
      return true;
    }
    
    if (kDebugMode) print('[OdooConfig] ❌ No configuration found');
    return false;
  } catch (e) {
    if (kDebugMode) print('[OdooConfig] Error in loadConfigWithFallback: $e');
    return false;
  }
}
```

---

## Phase 4: Cache Management UI

### File: `lib/features/admin/cache_management_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import '../../core/odoo/odoo_state.dart';

class CacheManagementScreen extends StatefulWidget {
  static const String route = '/cache-management';
  
  const CacheManagementScreen({super.key});
  
  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  bool _isRefreshing = false;
  bool _isClearing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Management'),
        backgroundColor: BrandTheme.primaryColor,
      ),
      body: Consumer<OdooState>(
        builder: (context, odooState, _) {
          final cacheStatus = odooState.getCacheStatus();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cache Status Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cache Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCacheStatusItem(
                        'Products',
                        cacheStatus['products'],
                      ),
                      const SizedBox(height: 12),
                      _buildCacheStatusItem(
                        'Services',
                        cacheStatus['services'],
                      ),
                      const SizedBox(height: 12),
                      _buildCacheStatusItem(
                        'Categories',
                        cacheStatus['categories'],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : () => _refreshCache(context),
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isRefreshing ? 'Refreshing...' : 'Refresh Cache Now',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isClearing ? null : () => _clearCache(context),
                icon: _isClearing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.delete_sweep),
                label: Text(
                  _isClearing ? 'Clearing...' : 'Clear All Cache',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ℹ️ How It Works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoPoint('Cache is automatically saved when products are fetched from Odoo'),
                      _buildInfoPoint('Cached data is shown instantly on app restart'),
                      _buildInfoPoint('Fresh data is fetched in the background'),
                      _buildInfoPoint('Use "Refresh Now" to force an immediate update'),
                      _buildInfoPoint('Cache expires after 7 days of no updates'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCacheStatusItem(String label, Map<String, dynamic>? status) {
    if (status == null) {
      return Text('$label: Loading...');
    }
    
    final isCached = status['cached'] as bool;
    final count = status['count'] as int;
    final lastSync = status['lastSync'] as int?;
    final isExpired = status['expired'] as bool;
    
    String lastSyncText = 'Never';
    if (lastSync != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(lastSync);
      lastSyncText = DateFormat('MMM dd, yyyy HH:mm').format(date);
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$count items • Last sync: $lastSyncText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Chip(
          label: Text(
            isCached ? (isExpired ? 'EXPIRED' : 'CACHED') : 'EMPTY',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: isCached
              ? (isExpired ? Colors.orange : Colors.green)
              : Colors.grey,
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _refreshCache(BuildContext context) async {
    setState(() => _isRefreshing = true);
    
    try {
      final odooState = context.read<OdooState>();
      await odooState.refreshCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cache refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
  
  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will delete all cached products, services, and categories. '
          'They will be re-fetched from Odoo on next startup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isClearing = true);
    
    try {
      final odooState = context.read<OdooState>();
      await odooState.clearCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}
```

---

## Files Summary

### Phase 1 (Essential)
- ✅ `lib/core/cache/product_cache_service.dart` - NEW
- ✅ Modify `lib/core/odoo/odoo_state.dart`

### Phase 2
- ✅ `lib/core/cache/remote_product_cache_service.dart` - NEW
- ✅ Modify `lib/core/odoo/odoo_state.dart`

### Phase 3
- ✅ Modify `lib/core/odoo/odoo_config.dart`
- ✅ Modify `lib/core/odoo/odoo_state.dart`

### Phase 4
- ✅ `lib/features/admin/cache_management_screen.dart` - NEW
- ✅ Add route in `lib/features/admin/app_admin.dart`

### Phase 5 (Optional)
- ✅ `lib/core/sync/background_sync_service.dart` - NEW

---

**Document Status:** Ready for Implementation  
**Last Updated:** December 7, 2025

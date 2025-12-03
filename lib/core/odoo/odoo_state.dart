import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'odoo_config.dart';
import 'odoo_api_service.dart';
import 'global_odoo_config_service.dart';
import '../models/odoo_models.dart';

class OdooState extends ChangeNotifier {
  final OdooApiService _apiService = OdooApiService();
  final GlobalOdooConfigService _globalConfigService = GlobalOdooConfigService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  List<OdooProduct> _products = [];
  List<OdooService> _services = [];
  List<OdooCategory> _categories = [];
  List<OdooEvent> _events = [];
  Map<int, OdooStock> _stock = {};

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  List<OdooProduct> get products => _products;
  List<OdooService> get services => _services;
  List<OdooCategory> get categories => _categories;
  List<OdooEvent> get events => _events;
  Map<int, OdooStock> get stock => _stock;

  OdooState() {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('[OdooState] Initializing...');
    
    // PRIORITY 1: Try to load global configuration from Firestore (for all users)
    try {
      debugPrint('[OdooState] Attempting to load global Odoo configuration...');
      final hasGlobalConfig = await _globalConfigService.loadGlobalConfig();
      
      if (hasGlobalConfig) {
        debugPrint('[OdooState] ✅ Global configuration loaded successfully');
        // Reload local config to pick up the global settings
        await OdooConfig.loadConfig();
        _isAuthenticated = OdooConfig.isAuthenticated;
        
        // Auto-connect using global config
        if (OdooConfig.isConfigured) {
          debugPrint('[OdooState] Auto-connecting with global config...');
          await _autoConnect();
        }
        notifyListeners();
        return;
      } else {
        debugPrint('[OdooState] ⚠️ No global configuration found');
      }
    } catch (e) {
      debugPrint('[OdooState] ❌ Error loading global config: $e');
    }

    // PRIORITY 2: Fall back to local configuration (for development/admin)
    debugPrint('[OdooState] Falling back to local configuration...');
    await OdooConfig.loadConfig();
    _isAuthenticated = OdooConfig.isAuthenticated;
    
    // If local config is missing, try user-specific Firestore config (legacy)
    if (!OdooConfig.isConfigured) {
      try {
        final ok = await OdooConfig.loadFromFirestore();
        if (ok) {
          await OdooConfig.loadConfig();
          _isAuthenticated = OdooConfig.isAuthenticated;
        }
      } catch (_) {}
    }

    // Auto-connect to Odoo in background if configured
    if (OdooConfig.isConfigured) {
      if (!_isAuthenticated) {
        await _autoConnect();
      } else {
        _loadDataInBackground();
      }
    }
    
    notifyListeners();
  }

  /// Auto-connect to Odoo in background (silent, no user interaction)
  Future<void> _autoConnect() async {
    try {
      debugPrint('[OdooState] Attempting authentication...');
      final authResult = await _apiService.authenticate();
      if (authResult.success) {
        _isAuthenticated = true;
        debugPrint('[OdooState] ✅ Authentication successful');
        // Load products automatically
        _loadDataInBackground();
      } else {
        debugPrint('[OdooState] ❌ Authentication failed: ${authResult.error}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[OdooState] ❌ Authentication error: $e');
      _isAuthenticated = false;
    }
  }

  /// Load data in background without blocking UI
  Future<void> _loadDataInBackground() async {
    if (!_isAuthenticated) return;
    
    // Load products in background (do not filter by stock so services are included)
    Future.microtask(() async {
      try {
        await loadProducts(inStock: false);
      } catch (e) {
        // Silent fail
      }
    });
    // Load categories and services as well
    Future.microtask(() async {
      try {
        await loadCategories();
        await loadServices();
      } catch (e) {}
    });
  }

  /// Configure Odoo connection
  Future<bool> configure({
    required String baseUrl,
    required String database,
    String apiKey = '',
    String username = '',
    String password = '',
    String proxyUrl = '',
    bool persistRemote = false,
    String? remoteDocId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Save configuration first
      await OdooConfig.saveConfig(
        baseUrlValue: baseUrl,
        databaseValue: database,
        apiKeyValue: apiKey,
        usernameValue: username,
        passwordValue: password,
        proxyUrlValue: proxyUrl,
      );
      
      // Reload config to ensure proxy URL is loaded
      await OdooConfig.loadConfig();

      final authResult = await _apiService.authenticate();
        if (authResult.success) {
          _isAuthenticated = true;
          _isLoading = false;
          // Persist remotely if requested
          if (persistRemote) {
            try {
              final docId = remoteDocId ?? 'odoo_config';
              await OdooConfig.saveToFirestore(docId: docId);
            } catch (_) {}
          }
          notifyListeners();
          return true;
      } else {
        _error = authResult.error;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load products from Odoo
  Future<void> loadProducts({List<String>? categories, bool inStock = true}) async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _apiService.getProducts(
        categories: categories,
        inStock: inStock,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load services from Odoo
  Future<void> loadServices() async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _apiService.getServices();
      debugPrint('[OdooState] loaded services: ${_services.length}');
      if (_services.isNotEmpty) {
        for (var s in _services.take(6)) {
          debugPrint('[OdooState] service sample: id=${s.id} name="${s.name}" categ=${s.categoryId} public=${s.publicCategoryIds}');
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ecommerce categories from Odoo
  Future<void> loadCategories() async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
      debugPrint('[OdooState] loaded categories: ${_categories.length}');
      if (_categories.isNotEmpty) {
        for (var c in _categories.take(10)) {
          debugPrint('[OdooState] category sample: id=${c.id} name="${c.name}" parent=${c.parentId}');
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load events from Odoo
  Future<void> loadEvents({bool upcomingOnly = true}) async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _apiService.getEvents(upcomingOnly: upcomingOnly);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load stock information
  Future<void> loadStock({List<int>? productIds}) async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stockList = await _apiService.getStock(productIds: productIds);
      _stock = {for (var s in stockList) s.productId: s};
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadProducts(inStock: false),
      loadServices(),
      loadEvents(),
      loadCategories(),
    ]);
  }

  /// Logout from Odoo
  Future<void> logout() async {
    await OdooConfig.clearConfig();
    _isAuthenticated = false;
    _products = [];
    _services = [];
    _events = [];
    _stock = {};
    _error = null;
    notifyListeners();
  }

  /// Get product by ID
  OdooProduct? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get service by ID
  OdooService? getServiceById(int id) {
    try {
      return _services.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get event by ID
  OdooEvent? getEventById(int id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get stock for product
  OdooStock? getStockForProduct(int productId) {
    return _stock[productId];
  }

  // ------------------ CRUD helpers ------------------
  /// Create a new category in Odoo and refresh categories
  Future<int?> createCategory(Map<String, dynamic> values) async {
    if (!_isAuthenticated) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _apiService.createCategory(values);
      await loadCategories();
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a category and refresh
  Future<bool> updateCategory(int id, Map<String, dynamic> values) async {
    if (!_isAuthenticated) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _apiService.updateCategory(id, values);
      await loadCategories();
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a category and refresh
  Future<bool> deleteCategory(int id) async {
    if (!_isAuthenticated) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _apiService.deleteCategory(id);
      await loadCategories();
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Product CRUD
  Future<int?> createProduct(Map<String, dynamic> values) async {
    if (!_isAuthenticated) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _apiService.createProductRecord(values);
      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> values) async {
    if (!_isAuthenticated) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _apiService.updateProductRecord(id, values);
      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    if (!_isAuthenticated) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _apiService.deleteProductRecord(id);
      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'odoo_config.dart';
import 'odoo_api_service.dart';
import 'global_odoo_config_service.dart';
import '../models/odoo_models.dart';
import '../cache/product_cache_service.dart';
import '../cache/slot_cache_service.dart';

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
  List<OdooAppointmentType> _appointmentTypes = [];
  Map<int, OdooStock> _stock = {};

  // Cache freshness tracking
  DateTime? _lastProductsFetch;
  DateTime? _lastServicesFetch;
  DateTime? _lastCategoriesFetch;
  DateTime? _lastAppointmentTypesFetch;
  final Duration _cacheTtl = const Duration(minutes: 10);

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  List<OdooProduct> get products => _products;
  List<OdooService> get services => _services;
  List<OdooCategory> get categories => _categories;
  List<OdooEvent> get events => _events;
  List<OdooAppointmentType> get appointmentTypes => _appointmentTypes;
  Map<int, OdooStock> get stock => _stock;

  OdooState() {
    _initialize();
  }

  bool _isStale(DateTime? lastFetch) {
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > _cacheTtl;
  }

  Future<void> _initialize() async {
    debugPrint('[OdooState] Initializing...');
    
    // PHASE 1: Load cached data immediately for instant UI (non-blocking)
    _loadCachedDataAsync();
    
    // Load config immediately with timeout (no blocking)
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
    
    notifyListeners();
    
    // Load global config + auth in background (non-blocking)
    _initializeAsync();
  }

  /// PHASE 1: Load cached data in background for instant app startup
  void _loadCachedDataAsync() {
    Future.microtask(() async {
      try {
        debugPrint('[OdooState] Loading cached data...');
        
        // ⚡ Clean up expired slot cache on startup
        SlotCacheService.clearExpiredCache();
        
        final cachedProducts = await ProductCacheService.loadProducts();
        final cachedServices = await ProductCacheService.loadServices();
        final cachedCategories = await ProductCacheService.loadCategories();
        final cachedAppointmentTypes = await ProductCacheService.loadAppointmentTypes();
        
        if (cachedProducts != null) {
          _products = cachedProducts;
          debugPrint('[OdooState] ✅ Loaded ${cachedProducts.length} cached products');
        }
        if (cachedServices != null) {
          _services = cachedServices;
          debugPrint('[OdooState] ✅ Loaded ${cachedServices.length} cached services');
        }
        if (cachedCategories != null) {
          _categories = cachedCategories;
          debugPrint('[OdooState] ✅ Loaded ${cachedCategories.length} cached categories');
        }
        if (cachedAppointmentTypes != null) {
          _appointmentTypes = cachedAppointmentTypes;
          debugPrint('[OdooState] ✅ Loaded ${cachedAppointmentTypes.length} cached appointment types');
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('[OdooState] Cache load error (non-critical): $e');
      }
    });
  }

  void _initializeAsync() {
    Future.microtask(() async {
      try {
        debugPrint('[OdooState] Loading config + auth in background...');
        
        try {
          final hasGlobalConfig = await _globalConfigService.loadGlobalConfig().timeout(
            const Duration(seconds: 10), // Increased from 3 to 10 seconds
            onTimeout: () => false,
          );
          
          if (hasGlobalConfig) {
            debugPrint('[OdooState] ✅ Global config loaded');
            await OdooConfig.loadConfig();
            _isAuthenticated = OdooConfig.isAuthenticated;
          }
        } catch (e) {
          debugPrint('[OdooState] Global config error (continuing): $e');
        }
        
        if (!OdooConfig.isConfigured) {
          try {
            await OdooConfig.loadFromFirestore().timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            );
            if (OdooConfig.isConfigured) {
              await OdooConfig.loadConfig();
              _isAuthenticated = OdooConfig.isAuthenticated;
            }
          } catch (_) {}
        }
        
        if (OdooConfig.isConfigured) {
          if (!_isAuthenticated) {
            await _autoConnect();
          } else {
            _loadDataInBackground();
          }
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('[OdooState] Async init error: $e');
      }
    });
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

    // Warm caches without blocking UI; these will respect freshness checks
    Future.microtask(() async {
      try {
        await warmCatalogAndAppointments();
      } catch (_) {}
    });
  }

  Future<void> warmCatalogAndAppointments({bool force = false}) async {
    await Future.wait([
      ensureProductsFresh(inStock: false, force: force),
      ensureCategoriesFresh(force: force),
      ensureServicesFresh(force: force),
      ensureAppointmentTypesFresh(force: force),
    ]);
  }

  Future<void> ensureProductsFresh({bool inStock = true, bool force = false}) async {
    if (!_isAuthenticated) return;
    if (force || _products.isEmpty || _isStale(_lastProductsFetch)) {
      await loadProducts(inStock: inStock);
    }
  }

  Future<void> ensureServicesFresh({bool force = false}) async {
    if (!_isAuthenticated) return;
    if (force || _services.isEmpty || _isStale(_lastServicesFetch)) {
      await loadServices();
    }
  }

  Future<void> ensureAppointmentTypesFresh({bool force = false}) async {
    if (!_isAuthenticated) return;
    if (force || _appointmentTypes.isEmpty || _isStale(_lastAppointmentTypesFetch)) {
      await loadAppointmentTypes();
    }
  }

  Future<void> ensureCategoriesFresh({bool force = false}) async {
    if (!_isAuthenticated) return;
    if (force || _categories.isEmpty || _isStale(_lastCategoriesFetch)) {
      await loadCategories();
    }
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
      _lastProductsFetch = DateTime.now();
      
      // PHASE 1: Auto-save products to cache
      ProductCacheService.cacheProducts(_products);
      
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
      debugPrint('[OdooState] 🔄 Starting getServices call...');
      _services = await _apiService.getServices();
      debugPrint('[OdooState] ✅ loaded services: ${_services.length}');
      _lastServicesFetch = DateTime.now();
      if (_services.isNotEmpty) {
        for (var s in _services.take(3)) {
          debugPrint('[OdooState] service sample: id=${s.id} name="${s.name}" hasAppointment=${s.hasAppointment} appointmentId=${s.appointmentTypeId}');
        }
      } else {
        debugPrint('[OdooState] ⚠️ WARNING: getServices returned ZERO services!');
      }
      
      // PHASE 1: Auto-save services to cache
      ProductCacheService.cacheServices(_services);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('[OdooState] ❌ ERROR loading services: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-throw so timeout can catch it
    }
  }

  /// Load appointment types from Odoo
  Future<void> loadAppointmentTypes() async {
    if (!_isAuthenticated) {
      _error = 'Not authenticated with Odoo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointmentTypes = await _apiService.getAppointmentTypes();
      debugPrint('[OdooState] loaded appointment types: ${_appointmentTypes.length}');
      _lastAppointmentTypesFetch = DateTime.now();
      
      // PHASE 1: Auto-save appointment types to cache
      ProductCacheService.cacheAppointmentTypes(_appointmentTypes);
      
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
      _lastCategoriesFetch = DateTime.now();
      if (_categories.isNotEmpty) {
        for (var c in _categories.take(10)) {
          debugPrint('[OdooState] category sample: id=${c.id} name="${c.name}" parent=${c.parentId}');
        }
      }
      
      // PHASE 1: Auto-save categories to cache
      ProductCacheService.cacheCategories(_categories);
      
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


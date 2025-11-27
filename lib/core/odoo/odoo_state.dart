import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'odoo_config.dart';
import 'odoo_api_service.dart';
import '../models/odoo_models.dart';

class OdooState extends ChangeNotifier {
  final OdooApiService _apiService = OdooApiService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  List<OdooProduct> _products = [];
  List<OdooService> _services = [];
  List<OdooEvent> _events = [];
  Map<int, OdooStock> _stock = {};

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  List<OdooProduct> get products => _products;
  List<OdooService> get services => _services;
  List<OdooEvent> get events => _events;
  Map<int, OdooStock> get stock => _stock;

  OdooState() {
    _initialize();
  }

  Future<void> _initialize() async {
    await OdooConfig.loadConfig();
    _isAuthenticated = OdooConfig.isAuthenticated;
    
    // Auto-connect to Odoo in background if configured
    if (OdooConfig.isConfigured && !_isAuthenticated) {
      // Try to authenticate silently in background
      _autoConnect();
    } else if (_isAuthenticated) {
      // Load data if already authenticated
      _loadDataInBackground();
    }
    
    notifyListeners();
  }

  /// Auto-connect to Odoo in background (silent, no user interaction)
  Future<void> _autoConnect() async {
    try {
      final authResult = await _apiService.authenticate();
      if (authResult.success) {
        _isAuthenticated = true;
        // Load products automatically
        _loadDataInBackground();
      }
      notifyListeners();
    } catch (e) {
      // Silent fail - don't show errors to users
      _isAuthenticated = false;
    }
  }

  /// Load data in background without blocking UI
  Future<void> _loadDataInBackground() async {
    if (!_isAuthenticated) return;
    
    // Load products in background
    Future.microtask(() async {
      try {
        await loadProducts();
      } catch (e) {
        // Silent fail
      }
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
      loadProducts(),
      loadServices(),
      loadEvents(),
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
}


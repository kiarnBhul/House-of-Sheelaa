import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class OdooConfig {
  static const String _keyBaseUrl = 'odoo_base_url';
  static const String _keyDatabase = 'odoo_database';
  static const String _keyApiKey = 'odoo_api_key';
  static const String _keyUsername = 'odoo_username';
  static const String _keyPassword = 'odoo_password';
  static const String _keyProxyUrl = 'odoo_proxy_url';
  static const String _keyUid = 'odoo_uid';
  static const String _keySessionId = 'odoo_session_id';

  // Default values - Can be set via environment variables or UI
  static final String _baseUrlEnv = const String.fromEnvironment('ODOO_BASE_URL', defaultValue: '');
  static final String _databaseEnv = const String.fromEnvironment('ODOO_DATABASE', defaultValue: '');
  static final String _apiKeyEnv = const String.fromEnvironment('ODOO_API_KEY', defaultValue: '');
  static final String _proxyEnv = const String.fromEnvironment('ODOO_PROXY_URL', defaultValue: '');
  static String baseUrl = _baseUrlEnv.isNotEmpty ? _baseUrlEnv : '';
  static String database = _databaseEnv.isNotEmpty ? _databaseEnv : '';
  static String apiKey = _apiKeyEnv; // Can be set via UI or environment variable
  static String proxyUrl = _proxyEnv; // Optional: when set on web, route requests via proxy to avoid CORS
  static String username = '';
  static String password = '';
  static int? uid;
  static String? sessionId;

  // Normalize base URL (remove trailing slashes and /odoo suffix)
  static String _normalizeUrl(String url) {
    String normalized = url.trim();
    // Remove trailing slash
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    // Remove /odoo suffix if present (Odoo.com instances)
    if (normalized.endsWith('/odoo')) {
      normalized = normalized.substring(0, normalized.length - 5);
    }
    return normalized;
  }

  // Normalize proxy URL to ensure it has /api/odoo path
  static String _normalizeProxyUrl(String url) {
    if (url.isEmpty) return url;
    String normalized = url.trim();
    // Remove trailing slash
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    // If proxy URL doesn't include /api/odoo, add it
    // But allow for cases where user provides full path
    if (!normalized.contains('/api/odoo')) {
      // If it's just a base URL like http://localhost:3000, add /api/odoo
      final baseUrlPattern = RegExp(r'^https?://[^/]+$');
      if (baseUrlPattern.hasMatch(normalized)) {
        normalized = '$normalized/api/odoo';
      }
    }
    return normalized;
  }

  // Odoo API endpoints
  static String get authUrl {
    if (kIsWeb && proxyUrl.isNotEmpty) {
      // When using proxy, proxy server handles routing
      final normalizedProxy = _normalizeProxyUrl(proxyUrl);
      final url = '$normalizedProxy/web/session/authenticate';
      // Debug: Only print in debug mode to reduce console spam
      if (kDebugMode) {
        print('[OdooConfig] Using proxy for authUrl: $url');
      }
      return url;
    }
    final directUrl = '${_normalizeUrl(baseUrl)}/web/session/authenticate';
    return directUrl;
  }
  static String get jsonRpcUrl {
    if (kIsWeb && proxyUrl.isNotEmpty) {
      // When using proxy, proxy server handles routing
      final normalizedProxy = _normalizeProxyUrl(proxyUrl);
      final url = '$normalizedProxy/jsonrpc';
      return url;
    }
    final directUrl = '${_normalizeUrl(baseUrl)}/jsonrpc';
    return directUrl;
  }
  
  // Get the actual Odoo base URL (needed by proxy)
  static String get actualOdooBaseUrl => _normalizeUrl(baseUrl);
  static String get commonUrl => jsonRpcUrl;

  // Model names in Odoo
  static const String productModel = 'product.product';
  static const String productTemplateModel = 'product.template';
  static const String serviceModel = 'product.service'; // Custom model or use product.product with service type
  static const String eventModel = 'event.event';
  static const String eventRegistrationModel = 'event.registration';
  static const String saleOrderModel = 'sale.order';
  static const String stockQuantModel = 'stock.quant';

  /// Load configuration from SharedPreferences
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = _baseUrlEnv.isNotEmpty ? _baseUrlEnv : (prefs.getString(_keyBaseUrl) ?? baseUrl);
    database = _databaseEnv.isNotEmpty ? _databaseEnv : (prefs.getString(_keyDatabase) ?? database);
    // Load API key from prefs if not set via environment variable
    apiKey = _apiKeyEnv.isNotEmpty ? _apiKeyEnv : (prefs.getString(_keyApiKey) ?? apiKey);
    username = prefs.getString(_keyUsername) ?? '';
    password = prefs.getString(_keyPassword) ?? '';
    proxyUrl = _proxyEnv.isNotEmpty ? _proxyEnv : (prefs.getString(_keyProxyUrl) ?? proxyUrl);
    uid = prefs.getInt(_keyUid);
    sessionId = prefs.getString(_keySessionId);
  }

  /// Save configuration to SharedPreferences
  static Future<void> saveConfig({
    String? baseUrlValue,
    String? databaseValue,
    String? apiKeyValue,
    String? usernameValue,
    String? passwordValue,
    String? proxyUrlValue,
    int? uidValue,
    String? sessionIdValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (baseUrlValue != null) {
      baseUrl = baseUrlValue;
      await prefs.setString(_keyBaseUrl, baseUrlValue);
    }
    if (databaseValue != null) {
      database = databaseValue;
      await prefs.setString(_keyDatabase, databaseValue);
    }
    // Save API key if provided (allows dynamic configuration via UI)
    if (apiKeyValue != null && apiKeyValue.isNotEmpty) {
      apiKey = apiKeyValue;
      await prefs.setString(_keyApiKey, apiKeyValue);
    }
    if (usernameValue != null) {
      username = usernameValue;
      await prefs.setString(_keyUsername, usernameValue);
    }
    if (passwordValue != null) {
      password = passwordValue;
      await prefs.setString(_keyPassword, passwordValue);
    }
    if (proxyUrlValue != null) {
      proxyUrl = proxyUrlValue.trim();
      if (proxyUrl.isEmpty) {
        await prefs.remove(_keyProxyUrl);
        proxyUrl = ''; // Reset to empty
      } else {
        // Normalize proxy URL before saving
        proxyUrl = _normalizeProxyUrl(proxyUrl);
        await prefs.setString(_keyProxyUrl, proxyUrl);
      }
    }
    if (uidValue != null) {
      uid = uidValue;
      await prefs.setInt(_keyUid, uidValue);
    }
    if (sessionIdValue != null) {
      sessionId = sessionIdValue;
      await prefs.setString(_keySessionId, sessionIdValue);
    }
  }

  /// Clear all configuration
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyDatabase);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyProxyUrl);
    await prefs.remove(_keyUid);
    await prefs.remove(_keySessionId);
    baseUrl = '';
    database = '';
    apiKey = _apiKeyEnv; // Reset to environment variable if set, otherwise empty
    username = '';
    password = '';
    proxyUrl = _proxyEnv; // Reset to environment variable if set, otherwise empty
    uid = null;
    sessionId = null;
  }

  /// Check if configuration is complete
  static bool get isConfigured {
    return baseUrl.isNotEmpty &&
        database.isNotEmpty &&
        (apiKey.isNotEmpty || (username.isNotEmpty && password.isNotEmpty));
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return isConfigured && uid != null && sessionId != null;
  }
}


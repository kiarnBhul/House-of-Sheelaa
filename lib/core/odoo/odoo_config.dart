import 'package:shared_preferences/shared_preferences.dart';

class OdooConfig {
  static const String _keyBaseUrl = 'odoo_base_url';
  static const String _keyDatabase = 'odoo_database';
  static const String _keyApiKey = 'odoo_api_key';
  static const String _keyUsername = 'odoo_username';
  static const String _keyPassword = 'odoo_password';
  static const String _keyUid = 'odoo_uid';
  static const String _keySessionId = 'odoo_session_id';

  // Default values - Update these with your Odoo instance details
  static String baseUrl = 'https://your-odoo-instance.com';
  static String database = 'your_database_name';
  static String apiKey = 'ec48b7e79184485691fbf3464be9330a7f6031fc'; // Pre-filled API key
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

  // Odoo API endpoints
  static String get authUrl => '${_normalizeUrl(baseUrl)}/web/session/authenticate';
  static String get jsonRpcUrl => '${_normalizeUrl(baseUrl)}/jsonrpc';
  static String get commonUrl => '${_normalizeUrl(baseUrl)}/jsonrpc';

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
    baseUrl = prefs.getString(_keyBaseUrl) ?? baseUrl;
    database = prefs.getString(_keyDatabase) ?? database;
    apiKey = prefs.getString(_keyApiKey) ?? apiKey;
    username = prefs.getString(_keyUsername) ?? '';
    password = prefs.getString(_keyPassword) ?? '';
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
    if (apiKeyValue != null) {
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
    await prefs.remove(_keyUid);
    await prefs.remove(_keySessionId);
    baseUrl = 'https://your-odoo-instance.com';
    database = 'your_database_name';
    apiKey = '02aad5fe3af89ccca6d120ae6223f0278d683017';
    username = '';
    password = '';
    uid = null;
    sessionId = null;
  }

  /// Check if configuration is complete
  static bool get isConfigured {
    return baseUrl.isNotEmpty &&
        baseUrl != 'https://your-odoo-instance.com' &&
        database.isNotEmpty &&
        database != 'your_database_name' &&
        apiKey.isNotEmpty;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return isConfigured && uid != null && sessionId != null;
  }
}


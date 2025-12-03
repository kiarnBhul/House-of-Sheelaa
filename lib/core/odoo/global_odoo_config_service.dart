import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'odoo_config.dart';

/// Global Odoo Configuration Service
/// This service manages a single, centralized Odoo configuration that all users access.
/// Only admins can update the configuration via the admin panel.
/// All users automatically fetch and use this configuration.
class GlobalOdooConfigService {
  static const String GLOBAL_CONFIG_DOC_ID = 'global_odoo_config';
  static const String CONFIG_COLLECTION = 'app_settings';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch the global Odoo configuration from Firestore
  /// This is called by all users on app startup
  Future<bool> loadGlobalConfig() async {
    try {
      debugPrint('[GlobalOdooConfig] Loading global Odoo configuration...');
      
      final doc = await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(GLOBAL_CONFIG_DOC_ID)
          .get();

      if (!doc.exists) {
        debugPrint('[GlobalOdooConfig] No global configuration found');
        return false;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('[GlobalOdooConfig] Global configuration is empty');
        return false;
      }

      // Decrypt and load into OdooConfig
      final baseUrl = data['baseUrl'] as String? ?? '';
      final database = data['database'] as String? ?? '';
      final apiKey = data['apiKey'] as String? ?? '';
      final username = data['username'] as String? ?? '';
      final password = data['password'] as String? ?? '';
      final proxyUrl = data['proxyUrl'] as String? ?? '';
      final isActive = data['isActive'] as bool? ?? true;
      final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();

      if (!isActive) {
        debugPrint('[GlobalOdooConfig] Global configuration is disabled');
        return false;
      }

      if (baseUrl.isEmpty || database.isEmpty) {
        debugPrint('[GlobalOdooConfig] Global configuration incomplete');
        return false;
      }

      debugPrint('[GlobalOdooConfig] Loaded config: $baseUrl / $database');
      debugPrint('[GlobalOdooConfig] Last updated: $lastUpdated');
      debugPrint('[GlobalOdooConfig] Using proxy: ${proxyUrl.isNotEmpty ? proxyUrl : "None"}');

      // Save to local OdooConfig
      await OdooConfig.saveConfig(
        baseUrlValue: baseUrl,
        databaseValue: database,
        apiKeyValue: apiKey,
        usernameValue: username,
        passwordValue: password,
        proxyUrlValue: proxyUrl,
      );

      // Reload to ensure it's applied
      await OdooConfig.loadConfig();

      debugPrint('[GlobalOdooConfig] Global configuration loaded successfully');
      return true;
    } catch (e) {
      debugPrint('[GlobalOdooConfig] Error loading global config: $e');
      return false;
    }
  }

  /// Save the global Odoo configuration to Firestore (Admin only)
  /// This is called from the admin panel when admin configures Odoo
  Future<bool> saveGlobalConfig({
    required String baseUrl,
    required String database,
    String apiKey = '',
    String username = '',
    String password = '',
    String proxyUrl = '',
    bool isActive = true,
  }) async {
    try {
      debugPrint('[GlobalOdooConfig] Saving global Odoo configuration...');

      final configData = {
        'baseUrl': baseUrl,
        'database': database,
        'apiKey': apiKey,
        'username': username,
        'password': password,
        'proxyUrl': proxyUrl,
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': 1,
      };

      await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(GLOBAL_CONFIG_DOC_ID)
          .set(configData, SetOptions(merge: true));

      debugPrint('[GlobalOdooConfig] Global configuration saved successfully');
      return true;
    } catch (e) {
      debugPrint('[GlobalOdooConfig] Error saving global config: $e');
      return false;
    }
  }

  /// Check if global configuration exists
  Future<bool> hasGlobalConfig() async {
    try {
      final doc = await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(GLOBAL_CONFIG_DOC_ID)
          .get();
      return doc.exists && (doc.data()?['isActive'] as bool? ?? false);
    } catch (e) {
      debugPrint('[GlobalOdooConfig] Error checking global config: $e');
      return false;
    }
  }

  /// Get global configuration metadata (for admin panel display)
  Future<Map<String, dynamic>?> getGlobalConfigMetadata() async {
    try {
      final doc = await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(GLOBAL_CONFIG_DOC_ID)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return {
        'baseUrl': data['baseUrl'] ?? '',
        'database': data['database'] ?? '',
        'proxyUrl': data['proxyUrl'] ?? '',
        'isActive': data['isActive'] ?? false,
        'lastUpdated': (data['lastUpdated'] as Timestamp?)?.toDate(),
        'hasApiKey': (data['apiKey'] as String? ?? '').isNotEmpty,
        'hasUsername': (data['username'] as String? ?? '').isNotEmpty,
      };
    } catch (e) {
      debugPrint('[GlobalOdooConfig] Error getting metadata: $e');
      return null;
    }
  }

  /// Disable global configuration (Admin only)
  Future<bool> disableGlobalConfig() async {
    try {
      await _firestore
          .collection(CONFIG_COLLECTION)
          .doc(GLOBAL_CONFIG_DOC_ID)
          .update({'isActive': false});
      return true;
    } catch (e) {
      debugPrint('[GlobalOdooConfig] Error disabling config: $e');
      return false;
    }
  }

  /// Listen to global configuration changes in real-time
  Stream<DocumentSnapshot> watchGlobalConfig() {
    return _firestore
        .collection(CONFIG_COLLECTION)
        .doc(GLOBAL_CONFIG_DOC_ID)
        .snapshots();
  }
}

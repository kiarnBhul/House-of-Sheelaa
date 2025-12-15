import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'odoo_config.dart';
import '../../core/models/odoo_models.dart';
import '../cache/slot_cache_service.dart';

class OdooApiService {
  static final OdooApiService _instance = OdooApiService._internal();
  factory OdooApiService() => _instance;
  OdooApiService._internal();

  /// Authenticate with Odoo using API Key
  Future<OdooAuthResult> authenticate() async {
    try {
      // Try API key authentication first
      if (OdooConfig.apiKey.isNotEmpty) {
        // Method 1: Try API key as password with database name as username (most common for Odoo.com)
        final result1 = await _authenticateWithApiKey(
          username: OdooConfig.database,
          apiKey: OdooConfig.apiKey,
        );
        if (result1.success) return result1;

        // Method 2: Try with 'admin' username
        final result2 = await _authenticateWithApiKey(
          username: 'admin',
          apiKey: OdooConfig.apiKey,
        );
        if (result2.success) return result2;

        // Method 3: Try with 'api' username
        final result3 = await _authenticateWithApiKey(
          username: 'api',
          apiKey: OdooConfig.apiKey,
        );
        if (result3.success) return result3;

        // Method 4: Try API key via JSON-RPC authenticate
        final result4 = await _authenticateViaJsonRpc();
        if (result4.success) return result4;

        // Method 5: Try with database name without hyphens (Odoo.com format)
        final cleanDb = OdooConfig.database.replaceAll('-', '_');
        if (cleanDb != OdooConfig.database) {
          final result5 = await _authenticateWithApiKey(
            username: cleanDb,
            apiKey: OdooConfig.apiKey,
          );
          if (result5.success) return result5;
        }
      }

      // Fallback to username/password if API key fails
      if (OdooConfig.username.isNotEmpty && OdooConfig.password.isNotEmpty) {
        // For web builds, try JSON-RPC first (better CORS support)
        if (kIsWeb) {
          final jsonRpcResult = await _authenticateViaJsonRpcWithCredentials(
            username: OdooConfig.username,
            password: OdooConfig.password,
          );
          if (jsonRpcResult.success) return jsonRpcResult;
        }

        // Try standard web session authenticate
        final response = await http.post(
          Uri.parse(OdooConfig.authUrl),
          headers: _getRequestHeaders(),
          body: jsonEncode({
            'jsonrpc': '2.0',
            'params': {
              'db': OdooConfig.database,
              'login': OdooConfig.username,
              'password': OdooConfig.password,
            },
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Connection timeout. This might be a CORS issue on web builds.');
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['result'] != null && data['result']['uid'] != null) {
            final uid = data['result']['uid'] as int;
            final sessionId = data['result']['session_id'] as String?;
            
            await OdooConfig.saveConfig(
              uidValue: uid,
              sessionIdValue: sessionId,
            );

            return OdooAuthResult(success: true, uid: uid, sessionId: sessionId);
          }
        }
      }

      // Return detailed error message
      String errorMsg = 'Authentication failed. ';
      if (OdooConfig.apiKey.isNotEmpty) {
        errorMsg += 'Please verify:\n';
        errorMsg += '1. API key is correct\n';
        errorMsg += '2. Database name matches exactly\n';
        errorMsg += '3. Odoo URL is correct (try without /odoo suffix)\n';
        errorMsg += '4. API key has proper permissions in Odoo';
      } else {
        errorMsg += 'Please check your username and password';
      }
      
      return OdooAuthResult(success: false, error: errorMsg);
    } catch (e) {
      String errorString = e.toString();
      
      // Detect CORS errors specifically
      if (errorString.contains('Failed to fetch') || 
          errorString.contains('CORS') ||
          errorString.contains('NetworkError') ||
          (kIsWeb && errorString.contains('ClientException'))) {
        return OdooAuthResult(
          success: false,
          error: '''CORS Error: Odoo server is blocking requests from this origin.

This is a common issue with Flutter web apps. Solutions:

1. **For Development**: Test on mobile/desktop builds instead of web
   - Run: flutter run -d chrome (for testing)
   - Or: flutter run -d windows/macos/linux/android/ios

2. **For Production**: Configure Odoo to allow CORS
   - Contact your Odoo administrator
   - Add your domain to Odoo's CORS whitelist
   - Or use a backend proxy server

3. **Alternative**: Use Odoo's external API if available
   - Some Odoo instances have separate API endpoints

Current error: $errorString''',
        );
      }
      
      return OdooAuthResult(success: false, error: 'Connection error: $errorString');
    }
  }

  /// Get headers for Odoo requests (includes proxy headers if needed)
  Map<String, String> _getRequestHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // If using proxy on web, send actual Odoo URL as header
    if (kIsWeb && OdooConfig.proxyUrl.isNotEmpty) {
      headers['X-Odoo-Base-Url'] = OdooConfig.actualOdooBaseUrl;
    }
    
    return headers;
  }

  /// Authenticate using API key as password
  Future<OdooAuthResult> _authenticateWithApiKey({
    required String username,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(OdooConfig.authUrl),
        headers: _getRequestHeaders(),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'db': OdooConfig.database,
            'login': username,
            'password': apiKey,
          },
        }),
      ).timeout(const Duration(seconds: 15)); // Increased from 5 to 15 seconds

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check for errors first
        if (data['error'] != null) {
          return OdooAuthResult(
            success: false,
            error: 'Odoo error: ${data['error']['message'] ?? data['error']}',
          );
        }
        
        if (data['result'] != null) {
          final result = data['result'];
          // Handle different response formats
          int? uid;
          String? sessionId;
          
          if (result is Map) {
            uid = result['uid'] as int?;
            sessionId = result['session_id'] as String?;
          } else if (result is int) {
            uid = result;
            sessionId = apiKey; // Use API key as session identifier
          }
          
          if (uid != null && uid > 0) {
            await OdooConfig.saveConfig(
              uidValue: uid,
              sessionIdValue: sessionId ?? apiKey,
            );

            return OdooAuthResult(success: true, uid: uid, sessionId: sessionId ?? apiKey);
          }
        }
      } else {
        return OdooAuthResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
      return OdooAuthResult(success: false, error: 'Invalid response format');
    } catch (e) {
      String errorString = e.toString();
      if (errorString.contains('Failed to fetch') || 
          errorString.contains('CORS') ||
          errorString.contains('NetworkError') ||
          (kIsWeb && errorString.contains('ClientException'))) {
        return OdooAuthResult(success: false, error: 'CORS blocked');
      }
      return OdooAuthResult(success: false, error: 'Network error: $errorString');
    }
  }

  /// Authenticate via JSON-RPC
  Future<OdooAuthResult> _authenticateViaJsonRpc() async {
    try {
      final response = await http.post(
        Uri.parse(OdooConfig.jsonRpcUrl),
        headers: _getRequestHeaders(),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'service': 'common',
            'method': 'authenticate',
            'args': [
              OdooConfig.database,
              OdooConfig.database, // Try database name as username
              OdooConfig.apiKey,   // API key as password
            ],
          },
          'id': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == null && data['result'] != null) {
          final result = data['result'];
          if (result is int && result > 0) {
            final uid = result;
            await OdooConfig.saveConfig(uidValue: uid, sessionIdValue: OdooConfig.apiKey);
            return OdooAuthResult(success: true, uid: uid, sessionId: OdooConfig.apiKey);
          }
        }
      }
      return OdooAuthResult(success: false, error: '');
    } catch (e) {
      return OdooAuthResult(success: false, error: '');
    }
  }

  /// Authenticate via JSON-RPC with username/password
  Future<OdooAuthResult> _authenticateViaJsonRpcWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(OdooConfig.jsonRpcUrl),
        headers: _getRequestHeaders(),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'service': 'common',
            'method': 'authenticate',
            'args': [
              OdooConfig.database,
              username,
              password,
            ],
          },
          'id': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == null && data['result'] != null) {
          final result = data['result'];
          if (result is int && result > 0) {
            final uid = result;
            // For JSON-RPC, we use the password as session identifier
            await OdooConfig.saveConfig(uidValue: uid, sessionIdValue: password);
            return OdooAuthResult(success: true, uid: uid, sessionId: password);
          }
        } else if (data['error'] != null) {
          return OdooAuthResult(
            success: false,
            error: 'Odoo error: ${data['error']['message'] ?? data['error']}',
          );
        }
      }
      return OdooAuthResult(success: false, error: '');
    } catch (e) {
      return OdooAuthResult(success: false, error: '');
    }
  }


  /// Execute RPC call to Odoo
  Future<dynamic> executeRpc({
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic>? kwargs,
  }) async {
    // Ensure we're authenticated or attempt to authenticate silently
    if (!OdooConfig.isAuthenticated) {
      final authResult = await authenticate();
      if (!authResult.success) {
        throw Exception('Authentication failed: ${authResult.error}');
      }
    }

    // Try the RPC call, but if it fails due to authentication/session expiry,
    // attempt to re-authenticate once and retry the RPC.
    int attempts = 0;
    while (attempts < 2) {
      attempts += 1;
      try {
        // Build headers
        final headers = _getRequestHeaders();

        if (OdooConfig.sessionId != null) {
          headers['Cookie'] = 'session_id=${OdooConfig.sessionId}';
        }

        final response = await http.post(
          Uri.parse(OdooConfig.jsonRpcUrl),
          headers: headers,
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'service': 'object',
              'method': 'execute_kw',
              'args': [
                OdooConfig.database,
                OdooConfig.uid ?? 1,
                OdooConfig.apiKey.isNotEmpty ? OdooConfig.apiKey : (OdooConfig.password.isNotEmpty ? OdooConfig.password : ''),
                model,
                method,
                args,
                kwargs ?? {},
              ],
            },
            'id': DateTime.now().millisecondsSinceEpoch,
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout after 30 seconds. Odoo server might be slow or unavailable.');
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['error'] != null) {
            final err = data['error'];
            
            // Enhanced error logging - capture ALL error details
            debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            debugPrint('[OdooApi] 🔴 ODOO ERROR DETAILS:');
            debugPrint('[OdooApi] Full error object: $err');
            
            String errMsg = 'Unknown error';
            String? errData;
            String? errDebugInfo;
            
            if (err is Map) {
              // Extract error message
              if (err['message'] != null) {
                errMsg = err['message'].toString();
              } else if (err['data'] != null && err['data'] is Map && err['data']['message'] != null) {
                errMsg = err['data']['message'].toString();
              }
              
              // Extract error data (often contains the real reason)
              if (err['data'] != null) {
                errData = err['data'].toString();
                debugPrint('[OdooApi] Error data: $errData');
              }
              
              // Extract debug info
              if (err['debug'] != null) {
                errDebugInfo = err['debug'].toString();
                debugPrint('[OdooApi] Debug info: $errDebugInfo');
              }
            } else {
              errMsg = err.toString();
            }
            
            debugPrint('[OdooApi] Error message: $errMsg');
            debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            
            // If error indicates an authentication/session issue, try to re-authenticate and retry once
            if (errMsg.toLowerCase().contains('access denied') || errMsg.toLowerCase().contains('session') || errMsg.toLowerCase().contains('authentication')) {
              if (attempts < 2) {
                final authResult = await authenticate();
                if (authResult.success) {
                  // continue to retry the RPC
                  continue;
                }
              }
              throw Exception('Odoo RPC Error: $errMsg${errData != null ? '\nData: $errData' : ''}');
            }
            throw Exception('Odoo RPC Error: $errMsg${errData != null ? '\nData: $errData' : ''}');
          }
          return data['result'];
        }
        throw Exception('HTTP Error: ${response.statusCode}');
      } catch (e) {
        // If this was an auth failure and we haven't retried, try authenticate and retry
        final msg = e.toString().toLowerCase();
        if ((msg.contains('authentication') || msg.contains('access denied') || msg.contains('session')) && attempts < 2) {
          final authResult = await authenticate();
          if (authResult.success) {
            continue; // retry RPC
          }
        }
        throw Exception('RPC call failed: $e');
      }
    }
    throw Exception('RPC call failed after retries');
  }

  /// Search and read records
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<List<dynamic>>? domain,
    List<String>? fields,
    int? limit,
    int? offset,
    String? order,
  }) async {
    try {
      final result = await executeRpc(
        model: model,
        method: 'search_read',
        args: [
          domain ?? [],
          fields ?? [],
        ],
        kwargs: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
          if (order != null) 'order': order,
        },
      );

      if (result != null && result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      return [];
    } catch (e) {
      throw Exception('Search read failed: $e');
    }
  }

  /// Get products from Odoo
  Future<List<OdooProduct>> getProducts({
    List<String>? categories,
    bool inStock = true,
  }) async {
    try {
      List<List<dynamic>> domain = [
        ['sale_ok', '=', true],
        // include both product and service types so services can be discovered when present
        ['type', 'in', ['product', 'service']],
      ];

      if (categories != null && categories.isNotEmpty) {
        domain.add(['categ_id', 'in', categories]);
      }

      // For services there might not be qty_available; only apply inStock filter when explicitly requested
      if (inStock) {
        domain.add(['qty_available', '>', 0]);
      }

      if (kDebugMode) {
        debugPrint('[OdooApi] getProducts calling jsonRpcUrl=${OdooConfig.jsonRpcUrl} domain=$domain inStock=$inStock categories=$categories');
      }
      final records = await searchRead(
        model: OdooConfig.productTemplateModel,
        domain: domain,
        fields: [
          'id',
          'name',
          'description',
          'list_price',
          'categ_id',
          'public_categ_ids',
          'image_1920',
          'qty_available',
          'default_code',
          'barcode',
          'type',
        ],
      );

      if (kDebugMode) {
        debugPrint('[OdooApi] getProducts returned ${records.length} records');
        if (records.isNotEmpty) debugPrint('[OdooApi] getProducts sample=${records.first}');
      }

      final parsed = <OdooProduct>[];
      for (var record in records) {
        try {
          parsed.add(OdooProduct.fromJson(record));
        } catch (e) {
          if (kDebugMode) debugPrint('[OdooApi] getProducts parse failed for record id=${record['id']}: $e');
        }
      }
      return parsed;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get services from Odoo
  Future<List<OdooService>> getServices() async {
    try {
      final domain = [
        ['sale_ok', '=', true],
        ['type', '=', 'service'],
      ];
      if (kDebugMode) {
        debugPrint('[OdooApi] getServices calling jsonRpcUrl=${OdooConfig.jsonRpcUrl} domain=$domain');
      }
      // Request services without custom x_appointment_type_id field (doesn't exist in this Odoo)
      // Will match services to appointments by product_id link instead
      final records = await searchRead(
        model: OdooConfig.productTemplateModel,
        domain: domain,
        fields: [
          'id',
          'name',
          'description',
          'list_price',
          'categ_id',
          'public_categ_ids',
          'image_1920',
          'default_code',
          'product_variant_ids',
          // NOTE: 'appointment_type_id' removed - doesn't exist on product.template in Odoo 19
          // Appointment linking happens via appointment.type.product_id instead
          'x_studio_has_appointment',
          'x_studio_appointment_link',
        ],
      );
      if (kDebugMode) {
        debugPrint('[OdooApi] getServices returned ${records.length} records from ${OdooConfig.productTemplateModel}');
        if (records.isNotEmpty) debugPrint('[OdooApi] getServices sample=${records.first}');
      }

      // Fallback: try product.product if product.template returned nothing
      if (records.isEmpty) {
        if (kDebugMode) debugPrint('[OdooApi] getServices fallback: trying ${OdooConfig.productModel}');
        final alt = await searchRead(
          model: OdooConfig.productModel,
          domain: domain,
          fields: [
            'id', 'name', 'description', 'list_price', 'categ_id', 'public_categ_ids', 'image_1920', 'default_code', 'type',
            'appointment_type_id', 'x_studio_has_appointment', 'x_studio_appointment_link'
          ],
        );
        if (kDebugMode) debugPrint('[OdooApi] getServices fallback returned ${alt.length} records from ${OdooConfig.productModel}');
        if (alt.isNotEmpty) {
          return alt.map((record) => OdooService.fromJson(record)).toList();
        }
      }

      final parsed = <OdooService>[];
      for (var record in records) {
        try {
          final service = OdooService.fromJson(record);
          parsed.add(service);
          
          // 🔍 Service Type Detection Logging
          if (kDebugMode) {
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            debugPrint('📦 Service: ${service.name}');
            debugPrint('   ID: ${service.id}');
            debugPrint('   Type: ${record['type']}');
            debugPrint('   Has Appointment: ${service.hasAppointment}');
            debugPrint('   Appointment Type ID: ${service.appointmentTypeId}');
            debugPrint('   Raw appointment_type_id: ${record['appointment_type_id']}');
            debugPrint('   Raw x_studio_has_appointment: ${record['x_studio_has_appointment']}');
            debugPrint('   ALL APPOINTMENT-RELATED FIELDS:');
            record.forEach((key, value) {
              if (key.toLowerCase().contains('appoint') || key.toLowerCase().contains('type')) {
                debugPrint('      $key: $value');
              }
            });
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[OdooApi] getServices parse failed for record id=${record['id']}: $e');
        }
      }
      // Fallback: try product.product if product.template returned nothing
      if (parsed.isEmpty) {
        if (kDebugMode) debugPrint('[OdooApi] getServices fallback: trying ${OdooConfig.productModel}');
        final alt = await searchRead(
          model: OdooConfig.productModel,
          domain: domain,
          fields: [
            'id', 'name', 'description', 'list_price', 'categ_id', 'public_categ_ids', 'image_1920', 'default_code', 'type',
            'appointment_type_id', 'x_appointment_type_id', 'x_studio_has_appointment', 'x_studio_appointment_link'
          ],
        );
        final altParsed = <OdooService>[];
        for (var record in alt) {
          try {
            altParsed.add(OdooService.fromJson(record));
          } catch (e) {
            if (kDebugMode) debugPrint('[OdooApi] getServices fallback parse failed for record id=${record['id']}: $e');
          }
        }
        if (altParsed.isNotEmpty) return altParsed;
      }

      return parsed;
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  /// Get ecommerce categories from Odoo (tries public category then fallback)
  Future<List<OdooCategory>> getCategories() async {
    try {
      // First try the public ecommerce category model (used by Website/eCommerce)
      final records = await searchRead(
        model: 'product.public.category',
        fields: ['id', 'name', 'parent_id', 'image_1920'],
        order: 'id asc',
      );

      if (records.isNotEmpty) {
        return records.map((r) => OdooCategory.fromJson(r)).toList();
      }

      // Fallback to product.category (older / alternate model)
      final fallback = await searchRead(
        model: 'product.category',
        fields: ['id', 'name', 'parent_id', 'image_1920'],
        order: 'id asc',
      );

      return fallback.map((r) => OdooCategory.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get events from Odoo
  Future<List<OdooEvent>> getEvents({bool upcomingOnly = true}) async {
    try {
      List<List<dynamic>> domain = [];
      if (upcomingOnly) {
        domain.add(['date_begin', '>=', DateTime.now().toIso8601String()]);
      }

      final records = await searchRead(
        model: OdooConfig.eventModel,
        domain: domain,
        fields: [
          'id',
          'name',
          'description',
          'date_begin',
          'date_end',
          'address_id',
          'seats_available',
          'event_type_id',
        ],
        order: 'date_begin asc',
      );

      return records.map((record) => OdooEvent.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Create a sale order
  Future<int?> createSaleOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
  }) async {
    try {
      final orderLineData = orderLines.map((line) => [0, 0, line]).toList();
      
      final result = await executeRpc(
        model: OdooConfig.saleOrderModel,
        method: 'create',
        args: [
          {
            'partner_id': partnerId,
            'order_line': orderLineData,
          }
        ],
      );

      // Odoo create returns the ID directly
      if (result is int) {
        return result;
      } else if (result is Map && result['id'] != null) {
        return result['id'] as int;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to create sale order: $e');
      return null;
    }
  }

  /// Get inventory/stock information
  Future<List<OdooStock>> getStock({
    List<int>? productIds,
  }) async {
    try {
      List<List<dynamic>> domain = [];
      if (productIds != null && productIds.isNotEmpty) {
        domain.add(['product_id', 'in', productIds]);
      }

      final records = await searchRead(
        model: OdooConfig.stockQuantModel,
        domain: domain,
        fields: [
          'id',
          'product_id',
          'location_id',
          'quantity',
          'reserved_quantity',
        ],
      );

      return records.map((record) => OdooStock.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stock: $e');
    }
  }

  /// Generic create record helper
  Future<dynamic> createRecord({required String model, required Map<String, dynamic> values}) async {
    try {
      final result = await executeRpc(
        model: model,
        method: 'create',
        args: [values],
      );
      return result;
    } catch (e) {
      throw Exception('Create failed: $e');
    }
  }

  /// Generic update (write) helper
  Future<bool> updateRecord({required String model, required int id, required Map<String, dynamic> values}) async {
    try {
      final result = await executeRpc(
        model: model,
        method: 'write',
        args: [ [id], values ],
      );
      return result == true || result == 1;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// Generic delete (unlink) helper
  Future<bool> deleteRecord({required String model, required int id}) async {
    try {
      final result = await executeRpc(
        model: model,
        method: 'unlink',
        args: [ [id] ],
      );
      return result == true || result == 1;
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Category-specific helpers
  Future<int?> createCategory(Map<String, dynamic> values) async {
    try {
      final id = await createRecord(model: 'product.public.category', values: values);
      if (id == null) return null;
      return id as int;
    } catch (e) {
      // fallback try product.category
      try {
        final id = await createRecord(model: 'product.category', values: values);
        return id as int?;
      } catch (e2) {
        throw Exception('Create category failed: $e / $e2');
      }
    }
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> values) async {
    try {
      return await updateRecord(model: 'product.public.category', id: id, values: values);
    } catch (e) {
      // try fallback
      return await updateRecord(model: 'product.category', id: id, values: values);
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      return await deleteRecord(model: 'product.public.category', id: id);
    } catch (e) {
      return await deleteRecord(model: 'product.category', id: id);
    }
  }

  /// Product CRUD helpers (using product.template)
  Future<int?> createProductRecord(Map<String, dynamic> values) async {
    try {
      final id = await createRecord(model: OdooConfig.productTemplateModel, values: values);
      return id as int?;
    } catch (e) {
      throw Exception('Create product failed: $e');
    }
  }

  Future<bool> updateProductRecord(int id, Map<String, dynamic> values) async {
    try {
      return await updateRecord(model: OdooConfig.productTemplateModel, id: id, values: values);
    } catch (e) {
      throw Exception('Update product failed: $e');
    }
  }

  Future<bool> deleteProductRecord(int id) async {
    try {
      return await deleteRecord(model: OdooConfig.productTemplateModel, id: id);
    } catch (e) {
      throw Exception('Delete product failed: $e');
    }
  }
  /// Get appointment types
  Future<List<OdooAppointmentType>> getAppointmentTypes() async {
    try {
      debugPrint('[OdooApi] getAppointmentTypes calling');
      
      // First, try to get ALL appointment types to see if any exist
      try {
        final allRecords = await searchRead(
          model: 'appointment.type',
          domain: [], // Get ALL appointment types
          fields: ['id', 'name', 'website_published'],
          limit: 5,
        );
        debugPrint('[OdooApi] Total appointment types in Odoo: ${allRecords.length}');
        if (allRecords.isNotEmpty) {
          for (var r in allRecords) {
            debugPrint('[OdooApi] Appointment type: id=${r['id']}, name=${r['name']}, website_published=${r['website_published']}');
          }
        }
      } catch (e) {
        debugPrint('[OdooApi] Could not fetch all appointment types: $e');
      }
      
      // Now fetch only published ones
      final records = await searchRead(
        model: 'appointment.type',
        domain: [['website_published', '=', true]], // Only published appointments
        fields: [
          'id',
          'name',
          'product_id',
          'appointment_duration',
          'location',
          // 'website_url' might not be directly available in all versions, 
          // but usually computed or we can construct it: /appointment/{id}
        ],
      );

      debugPrint('[OdooApi] getAppointmentTypes returned ${records.length} published records');
      if (records.isNotEmpty) {
        debugPrint('[OdooApi] getAppointmentTypes sample: ${records.first}');
      }
      
      return records.map((r) => OdooAppointmentType.fromJson(r)).toList();
    } catch (e) {
      debugPrint('[OdooApi] ❌ Failed to fetch appointment types: $e');
      if (kDebugMode) debugPrint('Failed to fetch appointment types (module might not be installed): $e');
      return [];
    }
  }

  /// Get appointment type details including staff
  Future<Map<String, dynamic>?> getAppointmentTypeDetails(int appointmentTypeId) async {
    try {
      final records = await searchRead(
        model: 'appointment.type',
        domain: [['id', '=', appointmentTypeId]],
        fields: [
          'id',
          'name',
          'product_id',
          'appointment_duration',
          'location',
          'staff_user_ids',
          'schedule_based_on',
          'min_schedule_hours',
          'max_schedule_days',
        ],
        limit: 1,
      );

      if (records.isNotEmpty) {
        return records.first;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to fetch appointment type details: $e');
      return null;
    }
  }

  /// Get staff/consultants for an appointment type
  Future<List<OdooStaff>> getAppointmentStaff(int appointmentTypeId) async {
    try {
      // First get the staff_user_ids from appointment type
      final appointmentDetails = await getAppointmentTypeDetails(appointmentTypeId);
      if (appointmentDetails == null) return [];

      final staffIds = appointmentDetails['staff_user_ids'];
      if (staffIds == null || (staffIds is List && staffIds.isEmpty)) {
        return [];
      }

      // Get user details for each staff member
      final userIds = staffIds is List ? staffIds.cast<int>() : [staffIds as int];
      
      final records = await searchRead(
        model: 'res.users',
        domain: [['id', 'in', userIds]],
        fields: [
          'id',
          'name',
          'email',
          'phone',
          'image_128',
        ],
      );

      return records.map((r) => OdooStaff.fromJson(r)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to fetch appointment staff: $e');
      return [];
    }
  }

  /// Get available appointment slots for a specific date and staff
  /// PRIORITY: Always fetch fresh schedule from Odoo, only use cache as fallback
  Future<List<OdooAppointmentSlot>> getAppointmentSlots({
    required int appointmentTypeId,
    required DateTime date,
    int? staffId,
  }) async {
    try {
      debugPrint('[OdooApi] 🔄 Fetching FRESH slots for type=$appointmentTypeId, date=${date.toIso8601String()}, staff=$staffId');
      
      // ⚡ STEP 1: ALWAYS try to fetch fresh availability schedule from Odoo FIRST
      List<Map<String, dynamic>>? freshAvailability;
      int durationMinutes = 30; // Default
      int intervalMinutes = 30;
      
      try {
        // Get appointment type details for duration
        final typeDetails = await getAppointmentTypeDetails(appointmentTypeId);
        if (typeDetails != null) {
          final durationHours = (typeDetails['appointment_duration'] as num?)?.toDouble() ?? 0.5;
          durationMinutes = (durationHours * 60).round();
          intervalMinutes = (typeDetails['slot_duration'] as num?)?.toInt() ?? durationMinutes;
          debugPrint('[OdooApi] Duration: $durationMinutes min, interval: $intervalMinutes min');
        }
        
        // Fetch fresh availability schedule from Odoo
        debugPrint('[OdooApi] → Fetching FRESH availability schedule from Odoo...');
        final typeData = await searchRead(
          model: 'appointment.type',
          domain: [['id', '=', appointmentTypeId]],
          fields: ['slot_ids'],
        ).timeout(const Duration(seconds: 8));

        if (typeData.isNotEmpty && typeData[0]['slot_ids'] != null) {
          final slotIds = typeData[0]['slot_ids'] as List;
          debugPrint('[OdooApi] Found ${slotIds.length} slot IDs in appointment type');
          
          if (slotIds.isNotEmpty) {
            // Read the actual slot records with consultant restrictions
            final slots = await searchRead(
              model: 'appointment.slot',
              domain: [['id', 'in', slotIds]],
              fields: ['weekday', 'start_hour', 'end_hour', 'slot_type', 'restrict_to_user_ids'],
            ).timeout(const Duration(seconds: 8));
            
            if (slots.isNotEmpty) {
              freshAvailability = slots;
              debugPrint('[OdooApi] ✅ Fetched FRESH ${slots.length} availability rules from Odoo');
              
              // Cache the availability schedule for emergency fallback
              await SlotCacheService.cacheAvailabilitySchedule(
                appointmentTypeId: appointmentTypeId,
                availabilitySlots: slots,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[OdooApi] ⚠️ Failed to fetch fresh availability from Odoo: $e');
      }
      
      // STEP 2: Use fresh availability if fetched, otherwise try cache as fallback
      List<Map<String, dynamic>>? availabilityToUse = freshAvailability;
      
      if (availabilityToUse == null) {
        debugPrint('[OdooApi] → Fresh fetch failed, trying cache as fallback...');
        availabilityToUse = await SlotCacheService.loadAvailabilitySchedule(
          appointmentTypeId: appointmentTypeId,
        );
        if (availabilityToUse != null) {
          debugPrint('[OdooApi] ⚠️ Using CACHED availability (${availabilityToUse.length} rules) - may be outdated!');
        }
      }
      
      // STEP 3: Generate slots from availability schedule
      if (availabilityToUse != null && availabilityToUse.isNotEmpty) {
        final generatedSlots = _generateSlotsFromAvailability(
          availabilityToUse,
          date,
          durationMinutes,
          intervalMinutes,
          staffId,
        );
        
        if (generatedSlots.isNotEmpty) {
          debugPrint('[OdooApi] ✅ Generated ${generatedSlots.length} slots from availability schedule');
          
          // Cache generated slots for quick reload (short duration)
          await SlotCacheService.cacheSlots(
            appointmentTypeId: appointmentTypeId,
            date: date,
            staffId: staffId,
            slots: generatedSlots,
          );
          
          return generatedSlots;
        } else {
          debugPrint('[OdooApi] ℹ️ No slots available for this date/consultant (schedule exists but no match)');
          return []; // Return empty list = "No slots available for this day"
        }
      }
      
      // STEP 4: As last resort, check if we have any cached slots from previous successful fetch
      debugPrint('[OdooApi] ⚠️ No availability schedule available, checking for cached slots as emergency fallback...');
      final cachedSlots = await SlotCacheService.loadSlots(
        appointmentTypeId: appointmentTypeId,
        date: date,
        staffId: staffId,
      );
      
      if (cachedSlots != null && cachedSlots.isNotEmpty) {
        debugPrint('[OdooApi] ⚠️ Using EMERGENCY cached slots (${cachedSlots.length}) - Odoo unavailable!');
        return cachedSlots;
      }
      
      // STEP 5: Absolute last resort - no schedule configured in Odoo for this day
      debugPrint('[OdooApi] ℹ️ No availability schedule found in Odoo for this appointment type/date/staff');
      debugPrint('[OdooApi] → This means: No slots configured in Odoo Availabilities tab for this combination');
      return []; // Return empty = "No slots available for this day"
      
    } catch (e) {
      debugPrint('[OdooApi] ❌ getAppointmentSlots failed: $e');
      return [];
    }
  }
  


  /// Generate slots from availability schedule (appointment.slot records)
  List<OdooAppointmentSlot> _generateSlotsFromAvailability(
    List<Map<String, dynamic>> availabilitySlots,
    DateTime date,
    int durationMinutes,
    int intervalMinutes,
    int? staffId,
  ) {
    final slots = <OdooAppointmentSlot>[];
    final weekday = date.weekday.toString(); // Monday = 1, Sunday = 7
    final now = DateTime.now();
    
    debugPrint('[OdooApi] Generating slots for weekday $weekday, staffId=$staffId from ${availabilitySlots.length} availability records');
    
    for (var availability in availabilitySlots) {
      final slotWeekday = availability['weekday']?.toString();
      
      // Match weekday (Odoo uses '0' for Monday, '6' for Sunday, or string '1'-'7')
      bool weekdayMatches = false;
      if (slotWeekday == weekday) {
        weekdayMatches = true;
      } else if (slotWeekday == (date.weekday % 7).toString()) {
        weekdayMatches = true;
      }
      
      if (!weekdayMatches) continue;
      
      // Check if this slot is restricted to specific consultants
      final restrictToUserIds = availability['restrict_to_user_ids'];
      bool consultantMatches = true;
      
      debugPrint('[OdooApi]   Checking restriction: restrict_to_user_ids=$restrictToUserIds, staffId=$staffId');
      
      if (restrictToUserIds != null && staffId != null) {
        // restrictToUserIds can be List<int> or List<dynamic> with [id, name] pairs or false
        if (restrictToUserIds == false || restrictToUserIds is! List || (restrictToUserIds).isEmpty) {
          // No restrictions - available to all consultants
          debugPrint('[OdooApi]   ✓ No restrictions - available to all');
        } else if (restrictToUserIds.isNotEmpty) {
          // Check if staffId is in the list
          consultantMatches = false;
          for (var userId in restrictToUserIds) {
            int? userIdInt;
            if (userId is int) {
              userIdInt = userId;
            } else if (userId is List && userId.isNotEmpty && userId[0] is int) {
              userIdInt = userId[0] as int;
            }
            
            if (userIdInt == staffId) {
              consultantMatches = true;
              debugPrint('[OdooApi]   ✓ Consultant $staffId IS in restrict_to_user_ids');
              break;
            }
          }
          
          if (!consultantMatches) {
            debugPrint('[OdooApi]   ⊗ Consultant $staffId NOT in restrict_to_user_ids: $restrictToUserIds - SKIPPING');
            continue;
          }
        }
      } else {
        debugPrint('[OdooApi]   ✓ No staffId filter or no restrictions');
      }
      
      final startHour = (availability['start_hour'] as num?)?.toDouble() ?? 9.0;
      final endHour = (availability['end_hour'] as num?)?.toDouble() ?? 17.0;
      
      debugPrint('[OdooApi]   → Weekday $slotWeekday matches, consultant allowed, hours: $startHour - $endHour');
      
      // Convert hours to DateTime
      final startHourInt = startHour.floor();
      final startMinuteInt = ((startHour - startHourInt) * 60).round();
      final endHourInt = endHour.floor();
      final endMinuteInt = ((endHour - endHourInt) * 60).round();
      
      var slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        startHourInt,
        startMinuteInt,
      );
      
      final dayEnd = DateTime(
        date.year,
        date.month,
        date.day,
        endHourInt,
        endMinuteInt,
      );
      
      // Generate slots for this availability window
      while (slotStart.add(Duration(minutes: durationMinutes)).isBefore(dayEnd) ||
             slotStart.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(dayEnd)) {
        // Only include future slots
        if (slotStart.isAfter(now)) {
          final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
          slots.add(OdooAppointmentSlot(
            startTime: slotStart,
            endTime: slotEnd,
            staffId: staffId ?? 0,
            staffName: null,
          ));
        }
        slotStart = slotStart.add(Duration(minutes: intervalMinutes));
      }
    }
    
    debugPrint('[OdooApi] Generated ${slots.length} slots from availability');
    return slots;
  }

  /// Generate slots from the appointment schedule
  Future<List<OdooAppointmentSlot>> _generateSlotsFromSchedule(
    int appointmentTypeId,
    DateTime date,
    int? staffId,
    double durationHours,
    int slotIntervalMinutes,
  ) async {
    try {
      final durationMinutes = (durationHours * 60).round();
      final stepMinutes = slotIntervalMinutes > 0 ? slotIntervalMinutes : durationMinutes;

      // Get availability slots from appointment.slot model  
      final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
      final odooWeekday = dayOfWeek.toString(); // Odoo uses '1' for Monday

      final scheduleRecords = await searchRead(
        model: 'appointment.slot',
        domain: [
          ['appointment_type_id', '=', appointmentTypeId],
          ['weekday', '=', odooWeekday],
        ],
        fields: [
          'id',
          'weekday',
          'start_hour',
          'end_hour',
          'restrict_to_user_ids',
        ],
      );

      final slots = <OdooAppointmentSlot>[];
      
      for (var schedule in scheduleRecords) {
        final startHour = (schedule['start_hour'] as num?)?.toDouble() ?? 9.0;
        final endHour = (schedule['end_hour'] as num?)?.toDouble() ?? 17.0;
        
        // Check staff restriction
        final restrictedUsers = schedule['restrict_to_user_ids'];
        if (staffId != null && restrictedUsers is List && restrictedUsers.isNotEmpty) {
          if (!restrictedUsers.contains(staffId)) continue;
        }
        
        // Generate slots within this time range
        var currentHour = startHour;
        while (currentHour + (durationMinutes / 60) <= endHour + 1e-6) {
          final startMinutes = ((currentHour - currentHour.floor()) * 60).round();
          final startTime = DateTime(
            date.year,
            date.month,
            date.day,
            currentHour.floor(),
            startMinutes,
          );
          final endTime = startTime.add(Duration(minutes: durationMinutes));
          
          // Only add future slots
          if (startTime.isAfter(DateTime.now())) {
            slots.add(OdooAppointmentSlot(
              startTime: startTime,
              endTime: endTime,
              staffId: staffId ?? 0,
            ));
          }
          
          currentHour += stepMinutes / 60;
        }
      }
      
      return slots;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to generate slots from schedule: $e');
      return [];
    }
  }

  /// Generate default time slots when Odoo API is unavailable
  /// This creates reasonable business hour slots (9 AM - 5 PM)
  List<OdooAppointmentSlot> _generateDefaultTimeSlots(
    DateTime date,
    int durationMinutes,
    int slotIntervalMinutes,
  ) {
    final slots = <OdooAppointmentSlot>[];
    final stepMinutes = slotIntervalMinutes > 0 ? slotIntervalMinutes : durationMinutes;
    
    // Only generate slots for today and future dates
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return [];
    }
    
    // Business hours: 9 AM - 5 PM (with 30-minute intervals)
    final morningStart = 9.0;  // 9:00 AM
    final morningEnd = 12.0;   // 12:00 PM
    final afternoonStart = 13.0; // 1:00 PM  
    final afternoonEnd = 17.0;   // 5:00 PM
    
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(date, now);
    
    // Generate morning slots (9 AM - 12 PM)
    var currentHour = morningStart;
    while (currentHour + (durationMinutes / 60) <= morningEnd + 1e-6) {
      final startMinutes = ((currentHour - currentHour.floor()) * 60).round();
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        currentHour.floor(),
        startMinutes,
      );
      
      // Only add if in the future (for today) or any time (for future dates)
      if (!isToday || startTime.isAfter(now.add(const Duration(minutes: 30)))) {
        final endTime = startTime.add(Duration(minutes: durationMinutes));
        slots.add(OdooAppointmentSlot(
          startTime: startTime,
          endTime: endTime,
          staffId: 0,
        ));
      }
      
      currentHour += stepMinutes / 60;
    }
    
    // Generate afternoon slots (1 PM - 5 PM)
    currentHour = afternoonStart;
    while (currentHour + (durationMinutes / 60) <= afternoonEnd + 1e-6) {
      final startMinutes = ((currentHour - currentHour.floor()) * 60).round();
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        currentHour.floor(),
        startMinutes,
      );
      
      // Only add if in the future (for today) or any time (for future dates)
      if (!isToday || startTime.isAfter(now.add(const Duration(minutes: 30)))) {
        final endTime = startTime.add(Duration(minutes: durationMinutes));
        slots.add(OdooAppointmentSlot(
          startTime: startTime,
          endTime: endTime,
          staffId: 0,
        ));
      }
      
      currentHour += stepMinutes / 60;
    }
    
    if (kDebugMode) {
      debugPrint('[OdooApi] Generated ${slots.length} default time slots for ${DateFormat('yyyy-MM-dd').format(date)}');
    }
    return slots;
  }

  /// Create an appointment booking using Odoo Appointments module
  Future<Map<String, dynamic>?> createAppointmentBooking({
    required int appointmentTypeId,
    required DateTime dateTime,
    required int staffId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
    int? productId,
    double? price,
  }) async {
    try {
      debugPrint('[OdooApi] Creating appointment booking:');
      debugPrint('[OdooApi]   Type ID: $appointmentTypeId');
      debugPrint('[OdooApi]   DateTime: $dateTime');
      debugPrint('[OdooApi]   Staff ID: $staffId');
      debugPrint('[OdooApi]   Customer: $customerName <$customerEmail>');
      if (productId != null) debugPrint('[OdooApi]   Product ID: $productId, Price: $price');
      
      // Format datetime for Odoo 19 (requires YYYY-MM-DD HH:MM:SS format, no 'T' or 'Z')
      // Odoo 19 expects: '2025-12-15 02:30:00' NOT '2025-12-15T02:30:00.000Z'
      final utcDateTime = dateTime.toUtc();
      final dateTimeStr = '${utcDateTime.year.toString().padLeft(4, '0')}-'
          '${utcDateTime.month.toString().padLeft(2, '0')}-'
          '${utcDateTime.day.toString().padLeft(2, '0')} '
          '${utcDateTime.hour.toString().padLeft(2, '0')}:'
          '${utcDateTime.minute.toString().padLeft(2, '0')}:'
          '${utcDateTime.second.toString().padLeft(2, '0')}';
      
      // Step 1: Find or create partner
      int? partnerId;
      try {
        final partners = await searchRead(
          model: 'res.partner',
          domain: [['email', '=', customerEmail]],
          fields: ['id'],
          limit: 1,
        );
        
        if (partners.isNotEmpty) {
          partnerId = partners.first['id'] as int?;
          debugPrint('[OdooApi] Found existing partner: $partnerId');
        } else {
          final created = await executeRpc(
            model: 'res.partner',
            method: 'create',
            args: [
              {
                'name': customerName,
                'email': customerEmail,
                if (customerPhone != null) 'phone': customerPhone,
              }
            ],
          );
          if (created is int) {
            partnerId = created;
            debugPrint('[OdooApi] Created new partner: $partnerId');
          }
        }
      } catch (e) {
        debugPrint('[OdooApi] ⚠️ Partner creation/lookup failed: $e');
      }

      // Step 2: Create Sale Order with clear line description (primary record)
      int? saleOrderId;
      if (productId != null && price != null && price > 0 && partnerId != null) {
        try {
          // Fetch service name and consultant name for better description
          String serviceName = '';
          String consultantName = '';
          try {
            final appointmentType = await searchRead(
              model: 'appointment.type',
              domain: [['id', '=', appointmentTypeId]],
              fields: ['name'],
              limit: 1,
            );
            if (appointmentType.isNotEmpty) {
              serviceName = appointmentType.first['name'] as String? ?? '';
            }
          } catch (_) {}

          try {
            final consultant = await searchRead(
              model: 'res.users',
              domain: [['id', '=', staffId]],
              fields: ['name'],
              limit: 1,
            );
            if (consultant.isNotEmpty) {
              consultantName = consultant.first['name'] as String? ?? '';
            }
          } catch (_) {}

          final lineDescription = 'Service booking | '
            '${serviceName.isNotEmpty ? serviceName : 'Service'} | '
            '${DateFormat('MMM dd, yyyy – h:mm a').format(dateTime.toLocal())} | '
            'Consultant: ${consultantName.isNotEmpty ? consultantName : 'ID $staffId'}';

          final orderLines = [
            {
              'name': lineDescription,
              'product_id': productId,
              'product_uom_qty': 1,
              'price_unit': price,
            }
          ];

          saleOrderId = await createSaleOrder(
            partnerId: partnerId,
            orderLines: orderLines,
          );
          
          if (saleOrderId != null) {
            debugPrint('[OdooApi] ✅ Sale Order created: $saleOrderId');
          } else {
            debugPrint('[OdooApi] ⚠️ Sale order creation returned null');
          }
        } catch (e) {
          debugPrint('[OdooApi] ⚠️ Sale order creation failed (non-critical): $e');
        }
      }

      // Step 3: Create calendar.event - THIS IS CRITICAL FOR APPOINTMENTS TO SHOW!
      int? calendarEventId;
      if (partnerId != null) {
        try {
          debugPrint('[OdooApi] 📅 Creating calendar.event for appointment...');
          debugPrint('[OdooApi]    appointment_type_id: $appointmentTypeId');
          debugPrint('[OdooApi]    user_id (staff): $staffId');
          debugPrint('[OdooApi]    partner_ids: [[6, 0, [$partnerId]]]');
          debugPrint('[OdooApi]    start: $dateTimeStr');
          
          // Calculate end time (15 minutes by default)
          final endDateTime = dateTime.add(const Duration(minutes: 15));
          final utcEndDateTime = endDateTime.toUtc();
          final endDateTimeStr = '${utcEndDateTime.year.toString().padLeft(4, '0')}-'
              '${utcEndDateTime.month.toString().padLeft(2, '0')}-'
              '${utcEndDateTime.day.toString().padLeft(2, '0')} '
              '${utcEndDateTime.hour.toString().padLeft(2, '0')}:'
              '${utcEndDateTime.minute.toString().padLeft(2, '0')}:'
              '${utcEndDateTime.second.toString().padLeft(2, '0')}';
          
          // Fetch appointment type name for event title
          String eventName = 'Appointment';
          try {
            final appointmentType = await searchRead(
              model: 'appointment.type',
              domain: [['id', '=', appointmentTypeId]],
              fields: ['name'],
              limit: 1,
            );
            if (appointmentType.isNotEmpty) {
              eventName = appointmentType.first['name'] as String? ?? 'Appointment';
            }
          } catch (e) {
            debugPrint('[OdooApi] Could not fetch appointment type name: $e');
          }
          
          final eventData = {
            'name': eventName,
            'start': dateTimeStr,
            'stop': endDateTimeStr,
            'allday': false,
            'duration': 0.25, // 15 minutes = 0.25 hours
            
            // CRITICAL FIELDS for Staff Bookings view
            'appointment_type_id': appointmentTypeId,
            'user_id': staffId,
            'partner_ids': [[6, 0, [partnerId]]],
            
            // Location and video call
            'location': 'Online',
            'videocall_location': 'odoo_discuss',
            
            // Description
            'description': '''Appointment Booking
Customer: $customerName
Email: $customerEmail
${customerPhone != null ? 'Phone: $customerPhone' : ''}
${saleOrderId != null ? 'Sales Order: SO$saleOrderId' : ''}
${notes != null && notes.isNotEmpty ? '\nNotes: $notes' : ''}''',
            
            // Additional fields
            'privacy': 'public',
            'show_as': 'busy',
            'active': true,
          };
          
          debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('[OdooApi] 📤 SENDING TO ODOO:');
          debugPrint('[OdooApi] Model: calendar.event');
          debugPrint('[OdooApi] Method: create');
          debugPrint('[OdooApi] Event Data:');
          eventData.forEach((key, value) {
            debugPrint('[OdooApi]   $key: $value');
          });
          debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          calendarEventId = await executeRpc(
            model: 'calendar.event',
            method: 'create',
            args: [eventData],
          );
          
          if (calendarEventId is int) {
            debugPrint('[OdooApi] ✅✅✅ CALENDAR EVENT CREATED!');
            debugPrint('[OdooApi]    Event ID: $calendarEventId');
            debugPrint('[OdooApi]    Should now appear in:');
            debugPrint('[OdooApi]       Appointments → Appointment Types → Staff Bookings');
            debugPrint('[OdooApi]       Calendar → $eventName');
            debugPrint('[OdooApi]    ⏸️  Email will be sent after order confirmation');
          } else {
            debugPrint('[OdooApi] ⚠️ Calendar event creation returned unexpected type: ${calendarEventId.runtimeType}');
          }
        } catch (e, stackTrace) {
          debugPrint('[OdooApi] ❌❌❌ CALENDAR EVENT CREATION FAILED!');
          debugPrint('[OdooApi]    Error: $e');
          debugPrint('[OdooApi]    Stack: $stackTrace');
          debugPrint('[OdooApi]    💡 This is why appointment doesn\'t show in Appointments module!');
        }
      } else {
        debugPrint('[OdooApi] ❌ Cannot create calendar event - missing partnerId');
      }

      // Step 4: Return success with all IDs
      return {
        'success': true,
        if (saleOrderId != null) 'sale_order_id': saleOrderId,
        if (calendarEventId != null && calendarEventId is int) 'calendar_event_id': calendarEventId,
        'partner_id': partnerId,
        'appointment_type_id': appointmentTypeId,
        'datetime': dateTimeStr,
      };
    } catch (e, stackTrace) {
      debugPrint('[OdooApi] ❌ createAppointmentBooking failed: $e');
      debugPrint('[OdooApi] Stack: $stackTrace');
      return {'error': e.toString()};
    }
  }

  /// Fetch product variants for a given product template
  Future<List<OdooProductVariant>> getProductVariants(int productTemplateId) async {
    try {
      if (kDebugMode) {
        debugPrint('[OdooApi] Fetching variants for product template $productTemplateId');
      }

      final records = await searchRead(
        model: OdooConfig.productModel, // product.product
        domain: [['product_tmpl_id', '=', productTemplateId]],
        fields: [
          'id',
          'name',
          'display_name',
          'list_price',
          'lst_price',
          'product_template_attribute_value_ids',
        ],
      );

      if (kDebugMode) {
        debugPrint('[OdooApi] Found ${records.length} variants');
        if (records.isNotEmpty) {
          debugPrint('[OdooApi] Sample variant: ${records.first}');
        }
      }

      // Try to fetch attribute name from the first variant
      String? attributeName;
      if (records.isNotEmpty) {
        final firstVariant = records.first;
        if (firstVariant['product_template_attribute_value_ids'] is List) {
          final attrIds = firstVariant['product_template_attribute_value_ids'] as List;
          if (attrIds.isNotEmpty) {
            try {
              // Fetch the attribute value details to get the attribute name
              final attrRecords = await searchRead(
                model: 'product.template.attribute.value',
                domain: [['id', 'in', attrIds]],
                fields: ['id', 'name', 'attribute_id'],
                limit: 1,
              );
              
              if (attrRecords.isNotEmpty && attrRecords.first['attribute_id'] is List) {
                final attrIdData = attrRecords.first['attribute_id'] as List;
                if (attrIdData.length >= 2) {
                  attributeName = attrIdData[1] as String; // [id, name] format
                  if (kDebugMode) {
                    debugPrint('[OdooApi] Found attribute name: $attributeName');
                  }
                }
              }
            } catch (e) {
              debugPrint('[OdooApi] Could not fetch attribute name: $e');
            }
          }
        }
      }

      // Parse variants with the attribute name
      final variants = records.map((record) {
        final variant = OdooProductVariant.fromJson(record);
        // If we found an attribute name and the variant has 'Option' key, create new variant with correct key
        if (attributeName != null && variant.attributes.containsKey('Option')) {
          final value = variant.attributes['Option']!;
          return OdooProductVariant(
            id: variant.id,
            name: variant.name,
            price: variant.price,
            displayName: variant.displayName,
            attributes: {attributeName: value},
          );
        }
        return variant;
      }).toList();
      
      return variants;
    } catch (e) {
      debugPrint('[OdooApi] ❌ getProductVariants failed: $e');
      return [];
    }
  }

  /// Create a simple sales order for non-appointment services
  Future<int?> createSimpleSalesOrder({
    required int partnerId,
    required int productId,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[OdooApi] Creating sales order for partner $partnerId, product $productId');
      }

      final orderLines = [
        {
          'product_id': productId,
          'product_uom_qty': quantity,
          'price_unit': 0, // Let Odoo calculate from product
        }
      ];

      final saleOrderId = await createSaleOrder(
        partnerId: partnerId,
        orderLines: orderLines,
      );

      if (kDebugMode) {
        debugPrint('[OdooApi] ✅ Sales order created: $saleOrderId');
      }

      return saleOrderId;
    } catch (e) {
      debugPrint('[OdooApi] ❌ createSimpleSalesOrder failed: $e');
      return null;
    }
  }

  /// Create sales order from cart checkout
  Future<Map<String, dynamic>> createSalesOrderFromCart({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryAddress,
    required String city,
    required String state,
    required String pincode,
    required List<Map<String, dynamic>> cartItems, // [{productId, productName, quantity, price}]
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[OdooApi] 🛒 Creating sales order from cart');
        debugPrint('[OdooApi] Customer: $customerName ($customerEmail)');
        debugPrint('[OdooApi] Items: ${cartItems.length}');
      }

      // Step 1: Find or create customer partner
      int? partnerId;
      try {
        if (kDebugMode) {
          debugPrint('[OdooApi] 📧 Searching for partner with email: $customerEmail');
          debugPrint('[OdooApi] 👤 Customer name to use: $customerName');
        }
        
        // Only search if email is valid and not empty
        if (customerEmail.isEmpty || !customerEmail.contains('@')) {
          if (kDebugMode) {
            debugPrint('[OdooApi] ⚠️ Invalid email, will create partner with phone');
          }
          throw Exception('Invalid email address for partner search');
        }
        
        final partners = await searchRead(
          model: 'res.partner',
          domain: [['email', '=', customerEmail]],
          fields: ['id', 'name', 'email', 'is_company'],
          limit: 1,
        );
        
        if (partners.isNotEmpty) {
          final existingPartnerId = partners.first['id'] as int?;
          final existingName = partners.first['name'] as String?;
          final isCompany = partners.first['is_company'] as bool?;
          
          if (kDebugMode) {
            debugPrint('[OdooApi] 🔍 Found existing partner: $existingPartnerId');
            debugPrint('[OdooApi] Name: $existingName, Is Company: $isCompany');
          }
          
          // If it's a company record or name doesn't match, update it
          if (isCompany == true || existingName != customerName) {
            if (kDebugMode) {
              debugPrint('[OdooApi] 📝 Updating partner with correct customer data');
            }
            
            try {
              await executeRpc(
                model: 'res.partner',
                method: 'write',
                args: [
                  [existingPartnerId],
                  {
                    'name': customerName,
                    'phone': customerPhone,
                    'street': deliveryAddress,
                    'city': city,
                    'zip': pincode,
                    'is_company': false,
                  }
                ],
              );
              
              if (kDebugMode) {
                debugPrint('[OdooApi] ✅ Partner updated successfully');
              }
            } catch (updateError) {
              debugPrint('[OdooApi] ⚠️ Could not update partner: $updateError');
            }
          }
          
          partnerId = existingPartnerId;
        } else {
          // Create new partner
          if (kDebugMode) {
            debugPrint('[OdooApi] 🆕 Creating new partner');
            debugPrint('[OdooApi] Name: $customerName');
            debugPrint('[OdooApi] Email: $customerEmail');
            debugPrint('[OdooApi] Phone: $customerPhone');
          }
          
          final created = await executeRpc(
            model: 'res.partner',
            method: 'create',
            args: [
              {
                'name': customerName,
                'email': customerEmail,
                'phone': customerPhone,
                'street': deliveryAddress,
                'city': city,
                'state_id': false,
                'zip': pincode,
                'country_id': 104, // India
                'is_company': false,
              }
            ],
          );
          
          if (created is int) {
            partnerId = created;
            if (kDebugMode) {
              debugPrint('[OdooApi] ✅ Created new partner: $partnerId');
            }
          } else {
            if (kDebugMode) {
              debugPrint('[OdooApi] ⚠️ Unexpected partner creation response: $created');
            }
          }
        }
      } catch (e) {
        debugPrint('[OdooApi] ❌ Partner creation failed: $e');
        return {
          'success': false,
          'error': 'Failed to create customer record: $e',
        };
      }

      if (partnerId == null) {
        return {
          'success': false,
          'error': 'Failed to get or create customer partner',
        };
      }

      // Step 2: Prepare order lines from cart items
      List<Map<String, dynamic>> orderLines = [];
      double totalAmount = 0.0;

      for (var item in cartItems) {
        final productId = item['productId'] as int?;
        final productName = item['productName'] as String? ?? 'Product';
        final quantity = item['quantity'] as int? ?? 1;
        final price = item['price'] as double? ?? 0.0;

        if (productId != null) {
          orderLines.add({
            'product_id': productId,
            'product_uom_qty': quantity,
            'price_unit': price,
            'name': productName,
          });
          totalAmount += price * quantity;
        }
      }

      if (orderLines.isEmpty) {
        return {
          'success': false,
          'error': 'No valid products in cart',
        };
      }

      // Step 3: Create the sales order
      final orderLineData = orderLines.map((line) => [0, 0, line]).toList();
      
      // Build order note with payment and delivery info
      final orderNote = '''
Order Details:
- Payment Method: $paymentMethod
- Delivery Address: $deliveryAddress, $city, $state - $pincode
- Phone: $customerPhone
${notes != null ? '- Notes: $notes' : ''}
''';

      try {
        final saleOrderId = await executeRpc(
          model: OdooConfig.saleOrderModel,
          method: 'create',
          args: [
            {
              'partner_id': partnerId,
              'order_line': orderLineData,
              'note': orderNote,
              'state': 'draft', // Start as draft
            }
          ],
        );

        if (saleOrderId is int) {
          if (kDebugMode) {
            debugPrint('[OdooApi] ✅ Sales Order created: SO$saleOrderId');
            debugPrint('[OdooApi] Total Amount: ₹${totalAmount.toStringAsFixed(2)}');
          }

          // Try to confirm the order automatically
          String orderStatus = 'draft';
          try {
            debugPrint('[OdooApi] 🔄 Confirming sales order SO$saleOrderId...');
            final confirmResult = await executeRpc(
              model: OdooConfig.saleOrderModel,
              method: 'action_confirm',
              args: [[saleOrderId]],
            );
            orderStatus = 'sale'; // Confirmed
            debugPrint('[OdooApi] ✅✅✅ Sales Order CONFIRMED successfully!');
            debugPrint('[OdooApi]    Status changed: draft → sale');
            debugPrint('[OdooApi]    Result: $confirmResult');
          } catch (e, stackTrace) {
            debugPrint('[OdooApi] ❌❌❌ CRITICAL: Order confirmation FAILED!');
            debugPrint('[OdooApi]    Error: $e');
            debugPrint('[OdooApi]    Stack: $stackTrace');
            debugPrint('[OdooApi]    ⚠️ Appointments may not be created because order is not confirmed!');
            debugPrint('[OdooApi]    💡 Check Odoo logs for confirmation error details');
          }

          return {
            'success': true,
            'saleOrderId': saleOrderId,
            'partnerId': partnerId,
            'totalAmount': totalAmount,
            'orderReference': 'SO$saleOrderId',
            'orderStatus': orderStatus,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response from Odoo',
          };
        }
      } catch (e) {
        debugPrint('[OdooApi] ❌ Sales order creation failed: $e');
        return {
          'success': false,
          'error': 'Failed to create sales order: $e',
        };
      }
    } catch (e) {
      debugPrint('[OdooApi] ❌ createSalesOrderFromCart failed: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Create appointment booking in Odoo Appointments module
  /// This creates bookings that show in "Staff Bookings" for each appointment type
  /// Emails are ONLY sent when orderStatus is 'sale' (confirmed), not 'draft' (quotation)
  Future<Map<String, dynamic>> createAppointmentFromOrder({
    required int partnerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required int saleOrderId,
    required String serviceName,
    required DateTime appointmentDate,
    int durationMinutes = 15,
    String orderStatus = 'draft', // Order status - controls email sending
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[OdooApi] 📅 Creating appointment booking for SO$saleOrderId');
        debugPrint('[OdooApi] 👤 Customer: $customerName');
        debugPrint('[OdooApi] 🎯 Service: $serviceName');
        debugPrint('[OdooApi] 📆 Scheduled: $appointmentDate');
      }

      // Step 1: Find existing appointment type by matching service name
      // Your Odoo already has these types configured
      int? appointmentTypeId;
      Map<String, dynamic>? appointmentType;
      
      try {
        debugPrint('[OdooApi] 🔍 Searching for appointment type...');
        debugPrint('[OdooApi]    Service name: "$serviceName"');
        
        // Search for appointment type - try exact match first
        debugPrint('[OdooApi]    Trying exact match: name = "$serviceName"');
        var existingTypes = await searchRead(
          model: 'appointment.type',
          domain: [['name', '=', serviceName]],
          fields: ['id', 'name', 'staff_user_ids', 'appointment_duration'],
        );
        debugPrint('[OdooApi]    Exact match results: ${existingTypes.length} types found');

        // If no exact match, try fuzzy search (e.g., "Manifestation Healing Booking" -> "Manifestation Healing")
        if (existingTypes.isEmpty) {
          final serviceKeyword = serviceName.replaceAll(' Booking', '').trim();
          debugPrint('[OdooApi]    Trying fuzzy match: name ilike "$serviceKeyword"');
          existingTypes = await searchRead(
            model: 'appointment.type',
            domain: [['name', 'ilike', serviceKeyword]],
            fields: ['id', 'name', 'staff_user_ids', 'appointment_duration'],
            limit: 1,
          );
          debugPrint('[OdooApi]    Fuzzy match results: ${existingTypes.length} types found');
        }

        if (existingTypes.isNotEmpty) {
          appointmentType = existingTypes.first as Map<String, dynamic>;
          appointmentTypeId = appointmentType['id'] as int;
          
          debugPrint('[OdooApi] ✅✅✅ FOUND APPOINTMENT TYPE!');
          debugPrint('[OdooApi]    ID: $appointmentTypeId');
          debugPrint('[OdooApi]    Name: ${appointmentType['name']}');
          debugPrint('[OdooApi]    Staff IDs: ${appointmentType['staff_user_ids']}');
          debugPrint('[OdooApi]    Duration: ${appointmentType['appointment_duration']}');
        } else {
          debugPrint('[OdooApi] ❌❌❌ NO APPOINTMENT TYPE FOUND!');
          debugPrint('[OdooApi]    Searched for: "$serviceName"');
          debugPrint('[OdooApi]    💡 ACTION REQUIRED:');
          debugPrint('[OdooApi]       1. Go to Odoo → Appointments');
          debugPrint('[OdooApi]       2. Create appointment type named exactly: "$serviceName"');
          debugPrint('[OdooApi]       3. Configure staff and communication settings');
        }
      } catch (e, stackTrace) {
        debugPrint('[OdooApi] ❌ Error searching appointment type: $e');
        debugPrint('[OdooApi] Stack: $stackTrace');
      }

      // Step 2: Get staff/consultant user from appointment type or default
      int? staffUserId;
      int? staffPartnerId; // NEW: Get consultant's partner_id for attendees
      
      try {
        // Try to get staff from appointment type first
        if (appointmentType != null && appointmentType['staff_user_ids'] != null) {
          final staffIds = appointmentType['staff_user_ids'] as List;
          if (staffIds.isNotEmpty) {
            // Get first staff member from appointment type
            if (staffIds[0] is List) {
              staffUserId = (staffIds[0] as List).last as int;
            } else {
              staffUserId = staffIds[0] as int;
            }
            
            if (kDebugMode) {
              debugPrint('[OdooApi] 👨‍💼 Using staff from appointment type: User ID $staffUserId');
            }
          }
        }

        // Fallback to admin if no staff assigned to appointment type
        if (staffUserId == null) {
          final users = await searchRead(
            model: 'res.users',
            domain: [['login', '=', 'admin']],
            fields: ['id', 'name', 'partner_id'],
          );
          
          if (users.isNotEmpty) {
            staffUserId = users.first['id'] as int;
            if (kDebugMode) {
              debugPrint('[OdooApi] 👨‍💼 Using default admin user: ${users.first['name']}');
            }
          }
        }
        
        // NEW: Get consultant's partner_id so they receive emails too
        if (staffUserId != null) {
          debugPrint('[OdooApi] 🔍 Fetching consultant partner_id for user: $staffUserId');
          
          final staffUser = await searchRead(
            model: 'res.users',
            domain: [['id', '=', staffUserId]],
            fields: ['id', 'name', 'partner_id', 'email'],
          );
          
          debugPrint('[OdooApi] 📊 Staff user search result: $staffUser');
          
          if (staffUser.isNotEmpty) {
            final partnerData = staffUser.first['partner_id'];
            debugPrint('[OdooApi] 📊 partner_id raw data: $partnerData (type: ${partnerData.runtimeType})');
            
            // Handle different formats of partner_id response
            if (partnerData is List && partnerData.isNotEmpty) {
              // Format: [id, "name"]
              staffPartnerId = partnerData[0] as int;
              final staffName = partnerData.length > 1 ? partnerData[1] as String : 'Unknown';
              final staffEmail = staffUser.first['email'] as String?;
              
              if (kDebugMode) {
                debugPrint('[OdooApi] ✅ Consultant details fetched:');
                debugPrint('[OdooApi]    User ID: $staffUserId');
                debugPrint('[OdooApi]    Partner ID: $staffPartnerId');
                debugPrint('[OdooApi]    Name: $staffName');
                debugPrint('[OdooApi]    Email: $staffEmail');
                debugPrint('[OdooApi]    Will be added as attendee to receive meeting link');
              }
            } else if (partnerData is int) {
              // Format: just an integer
              staffPartnerId = partnerData;
              debugPrint('[OdooApi] ✅ Consultant Partner ID (int format): $staffPartnerId');
            } else if (partnerData == false || partnerData == null) {
              debugPrint('[OdooApi] ⚠️ Consultant has no partner_id (value: $partnerData)');
            } else {
              debugPrint('[OdooApi] ⚠️ Unexpected partner_id format: $partnerData');
            }
          } else {
            debugPrint('[OdooApi] ⚠️ No staff user found with ID: $staffUserId');
          }
        }
      } catch (e, stackTrace) {
        debugPrint('[OdooApi] ⚠️ Error finding staff user: $e');
        debugPrint('[OdooApi] Stack trace: $stackTrace');
      }

      // Step 3: Calculate end time and format for Odoo 19
      final endDate = appointmentDate.add(Duration(minutes: durationMinutes));
      
      // Format datetimes for Odoo 19 (YYYY-MM-DD HH:MM:SS without 'T' or 'Z')
      final utcStart = appointmentDate.toUtc();
      final startStr = '${utcStart.year.toString().padLeft(4, '0')}-'
          '${utcStart.month.toString().padLeft(2, '0')}-'
          '${utcStart.day.toString().padLeft(2, '0')} '
          '${utcStart.hour.toString().padLeft(2, '0')}:'
          '${utcStart.minute.toString().padLeft(2, '0')}:'
          '${utcStart.second.toString().padLeft(2, '0')}';
      
      final utcEnd = endDate.toUtc();
      final endStr = '${utcEnd.year.toString().padLeft(4, '0')}-'
          '${utcEnd.month.toString().padLeft(2, '0')}-'
          '${utcEnd.day.toString().padLeft(2, '0')} '
          '${utcEnd.hour.toString().padLeft(2, '0')}:'
          '${utcEnd.minute.toString().padLeft(2, '0')}:'
          '${utcEnd.second.toString().padLeft(2, '0')}';

      // Step 4: Create calendar event with proper appointment booking structure
      // Build attendees list: BOTH customer AND consultant
      final List<int> attendeePartnerIds = [partnerId]; // Start with customer
      
      debugPrint('[OdooApi] 👥 Building attendees list...');
      debugPrint('[OdooApi]    Customer Partner ID: $partnerId (added)');
      
      if (staffPartnerId != null) {
        attendeePartnerIds.add(staffPartnerId); // Add consultant
        debugPrint('[OdooApi]    Consultant Partner ID: $staffPartnerId (added)');
      } else {
        debugPrint('[OdooApi]    ⚠️ No consultant partner_id - only customer will be attendee');
      }
      
      debugPrint('[OdooApi]    Final attendee list: $attendeePartnerIds (${attendeePartnerIds.length} attendees)');
      
      final eventData = {
        'name': serviceName, // Use service name directly
        'start': startStr,
        'stop': endStr,
        'allday': false,
        'duration': durationMinutes / 60.0,
        
        // Link to appointment type - CRITICAL for showing in Staff Bookings
        if (appointmentTypeId != null) 'appointment_type_id': appointmentTypeId,
        
        // Assign to staff user
        if (staffUserId != null) 'user_id': staffUserId,
        
        // ATTENDEES: Both customer AND consultant - they will BOTH get emails
        'partner_ids': [[6, 0, attendeePartnerIds]],
        
        // Location and video call settings
        'location': 'Online',
        'videocall_location': 'odoo_discuss', // Use Odoo's built-in video
        
        // Booking details in description
        'description': '''Appointment Booking
--------------------------------
Customer: $customerName
Email: $customerEmail  
Phone: $customerPhone
Service: $serviceName
Duration: $durationMinutes minutes
Sales Order: SO$saleOrderId
--------------------------------

This is an online consultation.
Video call link will be available before the appointment.
''',
        
        // Additional fields for proper integration
        'privacy': 'public',
        'show_as': 'busy',
        'active': true,
      };

      debugPrint('[OdooApi] 📝 Creating calendar.event record...');
      debugPrint('[OdooApi]    Model: calendar.event');
      debugPrint('[OdooApi]    Method: create');
      debugPrint('[OdooApi]    Fields: ${eventData.keys.join(', ')}');
      debugPrint('[OdooApi]    appointment_type_id: $appointmentTypeId');
      debugPrint('[OdooApi]    user_id (staff): $staffUserId');
      debugPrint('[OdooApi] ');
      debugPrint('[OdooApi] 👥 👥 👥 ATTENDEES CONFIGURATION 👥 👥 👥');
      debugPrint('[OdooApi]    Customer Partner ID: $partnerId');
      if (staffPartnerId != null) {
        debugPrint('[OdooApi]    Consultant Partner ID: $staffPartnerId');
        debugPrint('[OdooApi]    Total attendees: 2 (Customer + Consultant)');
      } else {
        debugPrint('[OdooApi]    ⚠️ WARNING: Only 1 attendee (Customer only)');
        debugPrint('[OdooApi]    ⚠️ Consultant will NOT receive email notification');
      }
      debugPrint('[OdooApi]    partner_ids value: [[6, 0, $attendeePartnerIds]]');
      debugPrint('[OdooApi]    Actual list being sent: $attendeePartnerIds');
      debugPrint('[OdooApi] ');
      debugPrint('[OdooApi]    videocall_location: odoo_discuss');
      
      debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[OdooApi] 📤 SENDING TO ODOO:');
      debugPrint('[OdooApi] Model: calendar.event');
      debugPrint('[OdooApi] Method: create');
      debugPrint('[OdooApi] Event Data:');
      eventData.forEach((key, value) {
        debugPrint('[OdooApi]   $key: $value');
      });
      debugPrint('[OdooApi] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final appointmentId = await executeRpc(
        model: 'calendar.event',
        method: 'create',
        args: [eventData],
      );

      debugPrint('[OdooApi] Response from create: $appointmentId (type: ${appointmentId.runtimeType})');

      if (appointmentId is int) {
        debugPrint('[OdooApi] ✅✅✅ CALENDAR EVENT CREATED SUCCESSFULLY!');
        debugPrint('[OdooApi]    Appointment ID: $appointmentId');
        debugPrint('[OdooApi]    Should now be visible in:');
        debugPrint('[OdooApi]       Appointments → Appointment Types → Staff Bookings');
        debugPrint('[OdooApi]       Filter: Appointment = ${appointmentType?['name']}');

        // IMPORTANT: Only send emails when order is confirmed (status = 'sale')
        // NOT when it's just a quotation (status = 'draft')
        if (orderStatus == 'sale') {
          debugPrint('[OdooApi] ✅ Order is CONFIRMED - sending invitation emails...');
          
          // Step 5: Send invitation email to BOTH customer AND consultant
          try {
            // Send to customer
            await executeRpc(
              model: 'calendar.event',
              method: 'action_sendmail',
              args: [[appointmentId]],
            );
            
            if (kDebugMode) {
              debugPrint('[OdooApi] 📧 ✅ Invitation email sent to:');
              debugPrint('[OdooApi]    👤 Customer: $customerEmail');
              debugPrint('[OdooApi]    👨‍💼 Consultant: (via Odoo attendees)');
              debugPrint('[OdooApi]    📅 Meeting link included in email');
            }
          } catch (e) {
            debugPrint('[OdooApi] ⚠️ Could not send invitation email: $e');
            // Non-critical, continue
          }
        } else {
          debugPrint('[OdooApi] ⏸️  Order status is \'$orderStatus\' (not \'sale\')');
          debugPrint('[OdooApi]    📧 Emails will be sent ONLY after order confirmation');
          debugPrint('[OdooApi]    💡 Admin must confirm the quotation in Odoo first');
        }

        // Step 6: Update sales order with appointment reference
        try {
          await executeRpc(
            model: 'sale.order',
            method: 'write',
            args: [
              [saleOrderId],
              {
                'note': 'Appointment ID: $appointmentId\nScheduled: ${appointmentDate.toString()}',
              }
            ],
          );
        } catch (e) {
          debugPrint('[OdooApi] ⚠️ Could not update sales order: $e');
        }

        return {
          'success': true,
          'appointmentId': appointmentId,
          'appointmentTypeId': appointmentTypeId,
          'staffUserId': staffUserId,
        };
      } else {
        if (kDebugMode) {
          debugPrint('[OdooApi] ⚠️ Unexpected appointment response: $appointmentId');
        }
        return {
          'success': false,
          'error': 'Invalid response from Odoo appointments',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('[OdooApi] ❌ Appointment creation failed: $e');
      debugPrint('[OdooApi] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Failed to create appointment: $e',
      };
    }
  }

  /// Get list of available consultants/staff members
  Future<List<Map<String, dynamic>>> getConsultants() async {
    try {
      final users = await searchRead(
        model: 'res.users',
        domain: [
          ['active', '=', true],
          ['share', '=', false], // Internal users only, not portal users
        ],
        fields: ['id', 'name', 'email', 'image_128'],
      );

      return users.map((user) => user as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('[OdooApi] ❌ Failed to fetch consultants: $e');
      return [];
    }
  }

  /// Update appointment status (used when consultant completes appointment)
  Future<bool> updateAppointmentStatus({
    required int appointmentId,
    required String status, // 'open', 'done', 'cancelled'
  }) async {
    try {
      await executeRpc(
        model: 'calendar.event',
        method: 'write',
        args: [
          [appointmentId],
          {'state': status}
        ],
      );

      if (kDebugMode) {
        debugPrint('[OdooApi] ✅ Appointment $appointmentId status updated to: $status');
      }

      return true;
    } catch (e) {
      debugPrint('[OdooApi] ❌ Failed to update appointment status: $e');
      return false;
    }
  }

  /// Get user's appointments from Odoo calendar events
  Future<List<Map<String, dynamic>>> getUserAppointments({
    required String customerEmail,
  }) async {
    try {
      debugPrint('[OdooApi] 📅 Fetching appointments for: $customerEmail');
      
      // First, find the partner ID for this customer
      final partners = await searchRead(
        model: 'res.partner',
        domain: [['email', '=', customerEmail]],
        fields: ['id', 'name'],
        limit: 1,
      );

      if (partners.isEmpty) {
        debugPrint('[OdooApi] No partner found for email: $customerEmail');
        return [];
      }

      final partnerId = partners.first['id'] as int;
      debugPrint('[OdooApi] Found partner ID: $partnerId');

      // Fetch calendar events for this partner
      final events = await searchRead(
        model: 'calendar.event',
        domain: [
          ['partner_ids', 'in', partnerId],
        ],
        fields: [
          'id',
          'name',
          'start',
          'stop',
          'duration',
          'partner_ids',
          'user_id',
          'description',
          'location',
          'appointment_type_id',
        ],
        order: 'start desc',
      );

      debugPrint('[OdooApi] Found ${events.length} appointments');

      // Transform events to include more details
      final List<Map<String, dynamic>> appointments = [];
      for (var event in events) {
        final appointment = Map<String, dynamic>.from(event);
        
        // Get consultant name from user_id
        if (event['user_id'] is List && (event['user_id'] as List).length > 1) {
          appointment['consultantName'] = (event['user_id'] as List)[1];
        }

        // Get appointment type name
        if (event['appointment_type_id'] is List && (event['appointment_type_id'] as List).length > 1) {
          appointment['appointmentTypeName'] = (event['appointment_type_id'] as List)[1];
        }

        appointments.add(appointment);
      }

      return appointments;
    } catch (e) {
      debugPrint('[OdooApi] ❌ Error fetching user appointments: $e');
      return [];
    }
  }
}

class OdooAuthResult {
  final bool success;
  final int? uid;
  final String? sessionId;
  final String? error;

  OdooAuthResult({
    required this.success,
    this.uid,
    this.sessionId,
    this.error,
  });
}


import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'odoo_config.dart';
import '../../core/models/odoo_models.dart';

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
          headers: {
            'Content-Type': 'application/json',
          },
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

  /// Authenticate using API key as password
  Future<OdooAuthResult> _authenticateWithApiKey({
    required String username,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(OdooConfig.authUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'db': OdooConfig.database,
            'login': username,
            'password': apiKey,
          },
        }),
      );

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
        headers: {
          'Content-Type': 'application/json',
        },
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
        headers: {
          'Content-Type': 'application/json',
        },
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
    if (!OdooConfig.isAuthenticated) {
      final authResult = await authenticate();
      if (!authResult.success) {
        throw Exception('Authentication failed: ${authResult.error}');
      }
    }

    try {
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          throw Exception('Odoo RPC Error: ${data['error']}');
        }
        return data['result'];
      }
      throw Exception('HTTP Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('RPC call failed: $e');
    }
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
        ['type', '=', 'product'],
      ];

      if (categories != null && categories.isNotEmpty) {
        domain.add(['categ_id', 'in', categories]);
      }

      if (inStock) {
        domain.add(['qty_available', '>', 0]);
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
          'image_1920',
          'qty_available',
          'default_code',
          'barcode',
        ],
      );

      return records.map((record) => OdooProduct.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get services from Odoo
  Future<List<OdooService>> getServices() async {
    try {
      final records = await searchRead(
        model: OdooConfig.productTemplateModel,
        domain: [
          ['sale_ok', '=', true],
          ['type', '=', 'service'],
        ],
        fields: [
          'id',
          'name',
          'description',
          'list_price',
          'categ_id',
          'image_1920',
          'default_code',
        ],
      );

      return records.map((record) => OdooService.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
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
          'seats_availability',
          'seats_available',
          'event_type_id',
          'image_1920',
        ],
        order: 'date_begin asc',
      );

      return records.map((record) => OdooEvent.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Create a sale order
  Future<Map<String, dynamic>> createSaleOrder({
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

      return result ?? {};
    } catch (e) {
      throw Exception('Failed to create sale order: $e');
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


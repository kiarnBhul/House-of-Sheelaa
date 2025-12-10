/// Script to publish all appointment types in Odoo
/// Run this once to make appointment types visible on website
/// 
/// Usage: dart run scripts/publish_appointment_types.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Your Odoo configuration
  const baseUrl = 'https://house-of-sheelaa-proxy-server.onrender.com';
  const database = 'house-of-sheelaa';
  const username = 'info@houseofsheelaa.com'; // Replace with your admin email
  const password = 'your-password-here'; // Replace with your password
  
  print('🔐 Authenticating with Odoo...');
  
  // Step 1: Authenticate
  final authResponse = await http.post(
    Uri.parse('$baseUrl/api/odoo/web/session/authenticate'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': database,
        'login': username,
        'password': password,
      },
      'id': 1,
    }),
  );
  
  if (authResponse.statusCode != 200) {
    print('❌ Authentication failed: ${authResponse.statusCode}');
    print(authResponse.body);
    exit(1);
  }
  
  final authData = jsonDecode(authResponse.body);
  if (authData['error'] != null) {
    print('❌ Authentication error: ${authData['error']['message']}');
    exit(1);
  }
  
  print('✅ Authenticated successfully');
  
  // Extract session cookie
  final cookies = authResponse.headers['set-cookie'];
  
  // Step 2: Get all appointment types
  print('\n📋 Fetching appointment types...');
  
  final searchResponse = await http.post(
    Uri.parse('$baseUrl/api/odoo/web/dataset/call_kw'),
    headers: {
      'Content-Type': 'application/json',
      'Cookie': cookies ?? '',
    },
    body: jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'appointment.type',
        'method': 'search_read',
        'args': [
          [], // Get ALL appointment types
          ['id', 'name', 'website_published'],
        ],
        'kwargs': {},
      },
      'id': 2,
    }),
  );
  
  if (searchResponse.statusCode != 200) {
    print('❌ Failed to fetch appointment types: ${searchResponse.statusCode}');
    exit(1);
  }
  
  final searchData = jsonDecode(searchResponse.body);
  final appointmentTypes = (searchData['result'] as List?) ?? [];
  
  print('Found ${appointmentTypes.length} appointment types:');
  for (var type in appointmentTypes) {
    final published = type['website_published'] == true;
    print('  - ${type['name']} (ID: ${type['id']}) - Published: ${published ? "✅" : "❌"}');
  }
  
  // Step 3: Publish all unpublished appointment types
  print('\n📢 Publishing appointment types...');
  
  int publishedCount = 0;
  for (var type in appointmentTypes) {
    if (type['website_published'] != true) {
      print('  Publishing: ${type['name']}...');
      
      final writeResponse = await http.post(
        Uri.parse('$baseUrl/api/odoo/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies ?? '',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'appointment.type',
            'method': 'write',
            'args': [
              [type['id']], // Record ID
              {'website_published': true}, // Update values
            ],
            'kwargs': {},
          },
          'id': 3 + publishedCount,
        }),
      );
      
      if (writeResponse.statusCode == 200) {
        print('    ✅ Published successfully');
        publishedCount++;
      } else {
        print('    ❌ Failed to publish: ${writeResponse.statusCode}');
      }
    }
  }
  
  print('\n✨ Done! Published $publishedCount appointment types');
  print('Now restart your Flutter app and they should appear!');
}

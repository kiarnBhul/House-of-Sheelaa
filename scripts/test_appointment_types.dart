import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_api_service.dart';

/// Quick diagnostic tool to check Odoo Appointment Types configuration
/// Run this to verify your appointment types are set up correctly
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('════════════════════════════════════════════════');
  print('🔧 APPOINTMENT TYPES DIAGNOSTIC TOOL');
  print('════════════════════════════════════════════════');
  print('');
  
  final odooApi = OdooApiService();
  
  try {
    // Initialize Odoo connection
    print('📡 Connecting to Odoo...');
    // Connection happens automatically on first API call
    
    // Test 1: List all appointment types
    print('');
    print('═══════════════════════════════════════════════');
    print('TEST 1: Fetching all appointment types');
    print('═══════════════════════════════════════════════');
    
    final appointmentTypes = await odooApi.searchRead(
      model: 'appointment.type',
      domain: [],
      fields: ['id', 'name', 'staff_user_ids', 'appointment_duration', 'appointment_tz'],
    );
    
    if (appointmentTypes.isEmpty) {
      print('❌ NO APPOINTMENT TYPES FOUND!');
      print('');
      print('💡 ACTION REQUIRED:');
      print('   1. Go to Odoo → Appointments');
      print('   2. Create appointment types for your services:');
      print('      - TRAUMA HEALING');
      print('      - Prosperity Healing');
      print('      - Manifestation Healing');
      print('      - Cutting chords healing');
      print('      - Lemurian Healing');
      print('      - Chakra Healing');
      print('      - Extraction Healing');
      print('');
      return;
    }
    
    print('✅ Found ${appointmentTypes.length} appointment types:');
    print('');
    
    for (var type in appointmentTypes) {
      final id = type['id'];
      final name = type['name'];
      final staffIds = type['staff_user_ids'];
      final duration = type['appointment_duration'];
      final timezone = type['appointment_tz'];
      
      print('┌─────────────────────────────────────────────┐');
      print('│ ID: $id');
      print('│ Name: "$name"');
      print('│ Duration: $duration minutes');
      print('│ Timezone: $timezone');
      print('│ Staff Users: $staffIds');
      
      if (staffIds == null || (staffIds is List && staffIds.isEmpty)) {
        print('│ ⚠️  WARNING: No staff assigned!');
      } else if (staffIds is List) {
        print('│ ✅ ${staffIds.length} staff member(s) assigned');
      }
      
      print('└─────────────────────────────────────────────┘');
      print('');
    }
    
    // Test 2: Try to find specific service appointment types
    print('═══════════════════════════════════════════════');
    print('TEST 2: Checking required service appointment types');
    print('═══════════════════════════════════════════════');
    print('');
    
    final requiredServices = [
      'Chakra Healing',
      'TRAUMA HEALING',
      'Prosperity Healing',
      'Manifestation Healing',
      'Cutting chords healing',
      'Lemurian Healing',
      'Extraction Healing',
    ];
    
    for (var serviceName in requiredServices) {
      final found = await odooApi.searchRead(
        model: 'appointment.type',
        domain: [['name', '=', serviceName]],
        fields: ['id', 'name', 'staff_user_ids'],
        limit: 1,
      );
      
      if (found.isEmpty) {
        print('❌ "$serviceName" - NOT FOUND');
      } else {
        final type = found.first;
        final staffIds = type['staff_user_ids'];
        final hasStaff = staffIds != null && staffIds is List && staffIds.isNotEmpty;
        
        if (hasStaff) {
          print('✅ "$serviceName" - Found (ID: ${type['id']}, Staff: ${staffIds.length})');
        } else {
          print('⚠️  "$serviceName" - Found (ID: ${type['id']}) but NO STAFF ASSIGNED');
        }
      }
    }
    
    // Test 3: Check calendar.event model access
    print('');
    print('═══════════════════════════════════════════════');
    print('TEST 3: Verifying calendar.event model access');
    print('═══════════════════════════════════════════════');
    print('');
    
    try {
      final recentEvents = await odooApi.searchRead(
        model: 'calendar.event',
        domain: [],
        fields: ['id', 'name', 'appointment_type_id', 'user_id', 'state'],
        limit: 3,
        order: 'id DESC',
      );
      
      print('✅ Can access calendar.event model');
      print('📊 Found ${recentEvents.length} recent calendar events');
      
      if (recentEvents.isNotEmpty) {
        print('');
        print('Recent events:');
        for (var event in recentEvents) {
          print('  - ID ${event['id']}: ${event['name']} (Type: ${event['appointment_type_id']}, State: ${event['state']})');
        }
      }
    } catch (e) {
      print('❌ Cannot access calendar.event model: $e');
      print('💡 Check user permissions for Calendar module');
    }
    
    // Test 4: Check sales order model access
    print('');
    print('═══════════════════════════════════════════════');
    print('TEST 4: Verifying sale.order model access');
    print('═══════════════════════════════════════════════');
    print('');
    
    try {
      final recentOrders = await odooApi.searchRead(
        model: 'sale.order',
        domain: [],
        fields: ['id', 'name', 'state', 'partner_id'],
        limit: 3,
        order: 'id DESC',
      );
      
      print('✅ Can access sale.order model');
      print('📊 Found ${recentOrders.length} recent sales orders');
      
      if (recentOrders.isNotEmpty) {
        print('');
        print('Recent orders:');
        for (var order in recentOrders) {
          print('  - ${order['name']}: State=${order['state']}, Customer=${order['partner_id']}');
        }
      }
    } catch (e) {
      print('❌ Cannot access sale.order model: $e');
      print('💡 Check user permissions for Sales module');
    }
    
    print('');
    print('════════════════════════════════════════════════');
    print('✅ DIAGNOSTIC COMPLETE');
    print('════════════════════════════════════════════════');
    
  } catch (e, stackTrace) {
    print('');
    print('❌❌❌ DIAGNOSTIC FAILED!');
    print('Error: $e');
    print('Stack: $stackTrace');
    print('');
    print('💡 Check:');
    print('   1. Odoo server is running');
    print('   2. CORS proxy is configured');
    print('   3. API credentials are correct');
  }
}

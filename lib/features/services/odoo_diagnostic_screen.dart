import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_state.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

/// Diagnostic screen to check Odoo field availability and service configuration
/// Run this to troubleshoot appointment type linking issues
class OdooDiagnosticScreen extends StatefulWidget {
  const OdooDiagnosticScreen({super.key});

  @override
  State<OdooDiagnosticScreen> createState() => _OdooDiagnosticScreenState();
}

class _OdooDiagnosticScreenState extends State<OdooDiagnosticScreen> {
  String _output = 'Tap "Run Diagnostic" to check Odoo configuration';
  bool _isRunning = false;

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _output = 'Running diagnostic...\n';
    });

    final odooState = Provider.of<OdooState>(context, listen: false);
    final buffer = StringBuffer();

    try {
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('ODOO APPOINTMENT DIAGNOSTIC REPORT');
      buffer.writeln('═══════════════════════════════════════\n');

      // Check authentication
      buffer.writeln('1. Authentication Status:');
      buffer.writeln('   Authenticated: ${odooState.isAuthenticated}');
      buffer.writeln('   Database: Configured\n');

      // Check appointment types
      buffer.writeln('2. Appointment Types Loaded:');
      if (odooState.appointmentTypes.isEmpty) {
        buffer.writeln('   ❌ No appointment types found!');
        buffer.writeln('   Action: Load appointment types first\n');
      } else {
        buffer.writeln('   ✅ Found ${odooState.appointmentTypes.length} appointment types\n');
        for (var apt in odooState.appointmentTypes) {
          buffer.writeln('   📅 ${apt.name}');
          buffer.writeln('      ID: ${apt.id}');
          buffer.writeln('      Duration: ${apt.duration} hours');
          buffer.writeln('      Product ID: ${apt.productId ?? "NOT LINKED"}');
          if (apt.productId != null) {
            buffer.writeln('      ✅ Has product link');
          } else {
            buffer.writeln('      ❌ Missing product link (set in Up-front Payment)');
          }
          buffer.writeln('');
        }
      }

      // Check services
      buffer.writeln('3. Services Configuration:');
      if (odooState.services.isEmpty) {
        buffer.writeln('   ❌ No services loaded!');
        buffer.writeln('   Action: Load services first\n');
      } else {
        buffer.writeln('   ✅ Found ${odooState.services.length} services\n');
        
        // Group by appointment status
        final withAppointments = odooState.services.where((s) => s.hasAppointment).toList();
        final withoutAppointments = odooState.services.where((s) => !s.hasAppointment).toList();

        buffer.writeln('   Appointment-Based Services (${withAppointments.length}):');
        if (withAppointments.isEmpty) {
          buffer.writeln('      None\n');
        } else {
          for (var service in withAppointments) {
            buffer.writeln('      ✅ ${service.name}');
            buffer.writeln('         ID: ${service.id}');
            buffer.writeln('         Appointment Type ID: ${service.appointmentTypeId}');
            buffer.writeln('');
          }
        }

        buffer.writeln('   Digital/Instant Services (${withoutAppointments.length}):');
        if (withoutAppointments.isEmpty) {
          buffer.writeln('      None\n');
        } else {
          for (var service in withoutAppointments) {
            buffer.writeln('      📦 ${service.name}');
            buffer.writeln('         ID: ${service.id}');
            buffer.writeln('         Appointment Type ID: ${service.appointmentTypeId ?? "null"}');
            buffer.writeln('');
          }
        }
      }

      // Check for mismatches
      buffer.writeln('4. Configuration Issues:');
      bool hasIssues = false;

      // Check appointments without product links
      final unlinkedAppointments = odooState.appointmentTypes
          .where((apt) => apt.productId == null)
          .toList();
      if (unlinkedAppointments.isNotEmpty) {
        hasIssues = true;
        buffer.writeln('   ⚠️ Appointments without product links:');
        for (var apt in unlinkedAppointments) {
          buffer.writeln('      - ${apt.name} (ID: ${apt.id})');
          buffer.writeln('        Fix: Edit appointment type → Up-front Payment → Select product');
        }
        buffer.writeln('');
      }

      // Check services that should have appointments but don't
      final potentialAppointments = odooState.services.where((s) {
        // Service doesn't have appointment but there's an appointment type with matching name
        return !s.hasAppointment && 
               odooState.appointmentTypes.any((apt) => 
                 apt.name.toLowerCase() == s.name.toLowerCase());
      }).toList();

      if (potentialAppointments.isNotEmpty) {
        hasIssues = true;
        buffer.writeln('   ⚠️ Services missing appointment links:');
        for (var service in potentialAppointments) {
          final matchingApt = odooState.appointmentTypes.firstWhere(
            (apt) => apt.name.toLowerCase() == service.name.toLowerCase()
          );
          buffer.writeln('      - ${service.name} (Product ID: ${service.id})');
          buffer.writeln('        Matching appointment: ${matchingApt.name} (ID: ${matchingApt.id})');
          buffer.writeln('        Fix: Set appointment_type_id = ${matchingApt.id} on product');
          buffer.writeln('');
        }
      }

      if (!hasIssues) {
        buffer.writeln('   ✅ No configuration issues detected!\n');
      }

      // Recommendations
      buffer.writeln('5. Recommendations:');
      buffer.writeln('   For services that NEED calendar booking:');
      buffer.writeln('   1. Create appointment type in Odoo Appointments app');
      buffer.writeln('   2. Set product in "Up-front Payment" section');
      buffer.writeln('   3. Manually set appointment_type_id on product (see guide)');
      buffer.writeln('');
      buffer.writeln('   For services that DON\'T need calendar:');
      buffer.writeln('   1. Leave appointment_type_id empty on product');
      buffer.writeln('   2. Service will automatically show "Add to Cart"\n');

      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('END OF DIAGNOSTIC REPORT');
      buffer.writeln('═══════════════════════════════════════');

    } catch (e) {
      buffer.writeln('\n❌ ERROR: $e');
    }

    setState(() {
      _output = buffer.toString();
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Diagnostic'),
        backgroundColor: BrandColors.jacaranda,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrandColors.jacaranda,
              Color(0xFF1A0119),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDiagnostic,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'Running...' : 'Run Diagnostic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.ecstasy,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will check your Odoo configuration for appointment type linking issues',
                    style: TextStyle(
                      color: BrandColors.alabaster,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BrandColors.ecstasy.withOpacity(0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

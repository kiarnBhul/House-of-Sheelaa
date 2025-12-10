import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminAuthState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;
  Map<String, dynamic>? _profile;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  Map<String, dynamic>? get profile => _profile;
  bool get isInitialized => _isInitialized;

  AdminAuthState() {
    _loadSession();
  }

  // Load saved session on app start
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('admin_email');
      final savedProfile = prefs.getString('admin_profile');
      
      if (savedEmail != null && savedProfile != null) {
        _email = savedEmail;
        _profile = jsonDecode(savedProfile);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Failed to load admin session: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('HofS-admin').doc(email).get();
      if (!doc.exists) {
        return false;
      }
      final data = doc.data()!;
      final storedPassword = data['password']?.toString();
      if (storedPassword == null) return false;
      if (storedPassword != password) return false;

      _isAuthenticated = true;
      _email = email;
      _profile = data;
      
      // Save session to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_email', email);
      await prefs.setString('admin_profile', jsonEncode(data));
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _email = null;
    _profile = null;
    
    // Clear saved session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_email');
    await prefs.remove('admin_profile');
    
    notifyListeners();
  }
}
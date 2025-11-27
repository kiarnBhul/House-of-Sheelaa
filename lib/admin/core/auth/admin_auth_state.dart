import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;
  Map<String, dynamic>? _profile;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  Map<String, dynamic>? get profile => _profile;

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
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void signOut() {
    _isAuthenticated = false;
    _email = null;
    _profile = null;
    notifyListeners();
  }
}
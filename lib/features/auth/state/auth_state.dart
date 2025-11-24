import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  bool loading = false;
  String? phone;
  bool otpSent = false;
  String? name;
  String? firstName;
  String? lastName;
  DateTime? dob;
  List<String> interests = [];
  String? gender;
  String? language;

  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 600));
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String emailOrPhone, String password) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    loading = false;
    final ok = emailOrPhone.isNotEmpty && password.length >= 6;
    if (ok) status = AuthStatus.authenticated;
    notifyListeners();
    return ok;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    loading = false;
    final ok =
        name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        password.length >= 6;
    if (ok) status = AuthStatus.authenticated;
    notifyListeners();
    return ok;
  }

  Future<void> sendOtp(String phone) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    this.phone = phone;
    otpSent = true;
    // Reset onboarding-related fields so a brand new user flows through
    // Language -> Gender -> Details after OTP verification.
    name = null;
    firstName = null;
    lastName = null;
    dob = null;
    interests = [];
    gender = null;
    language = null;
    loading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String code) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    loading = false;
    final ok = code.length == 6;
    if (ok) {
      await loadUserByPhone();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    required DateTime dob,
    required List<String> interests,
    String? gender,
    String? language,
  }) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    this.firstName = firstName;
    this.lastName = lastName;
    name = ('$firstName $lastName').trim();
    this.dob = dob;
    this.interests = interests;
    this.gender = gender ?? this.gender;
    this.language = language ?? this.language;
    try {
      if (phone != null && phone!.isNotEmpty) {
        final users = FirebaseFirestore.instance.collection('users');
        await users.doc(phone!).set({
          'phone': phone,
          'firstName': firstName,
          'lastName': lastName,
          'name': name,
          'dob': dob.toIso8601String(),
          'interests': interests,
          'gender': this.gender,
          'language': this.language,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      status = AuthStatus.authenticated;
    } catch (_) {}
    loading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateLanguage(String? value) {
    language = value;
    notifyListeners();
  }

  void updateGender(String? value) {
    gender = value;
    notifyListeners();
  }

  Future<bool> loadUserByPhone() async {
    if (phone == null || phone!.isEmpty) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone!)
          .get();
      if (doc.exists) {
        final data = doc.data();
        firstName = data?['firstName'] as String?;
        lastName = data?['lastName'] as String?;
        name =
            data?['name'] as String? ??
            ([firstName, lastName].whereType<String>().join(' ').trim());
        final dobStr = data?['dob'];
        if (dobStr is String) {
          dob = DateTime.tryParse(dobStr);
        }
        final ints = data?['interests'];
        if (ints is List) {
          interests = ints.cast<String>();
        }
        final g = data?['gender'];
        if (g is String) gender = g;
        final lang = data?['language'];
        if (lang is String) language = lang;
        status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

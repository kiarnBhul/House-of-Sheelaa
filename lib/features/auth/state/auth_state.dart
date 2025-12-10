import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends ChangeNotifier {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  
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
  String? userId; // Firebase Auth UID
  String? email;

  // Getter for phoneNumber (alias for phone)
  String? get phoneNumber => phone;

  Future<void> initialize() async {
    // Quick sync check first (no network, instant)
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      email = currentUser.email;
      phone = currentUser.phoneNumber;
      status = AuthStatus.authenticated;
      notifyListeners();
      _loadUserDataAsync();
    } else {
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void _loadUserDataAsync() {
    _loadUserData().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('[AuthState] User data load timed out'),
    ).catchError((e) => debugPrint('[AuthState] Error loading user async: $e'));
  }

  Future<void> _loadUserData() async {
    if (userId == null) return;
    
    try {
      // Try loading by userId first
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!)
          .get();
          
      if (doc.exists) {
        _populateFromFirestore(doc.data()!);
        return;
      }
      
      // If not found and phone exists, try phone
      if (phone != null && phone!.isNotEmpty) {
        final phoneDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(phone!)
            .get();
            
        if (phoneDoc.exists) {
          _populateFromFirestore(phoneDoc.data()!);
        }
      }
    } catch (e) {
      debugPrint('[AuthState] Error loading user data: $e');
    }
  }

  void _populateFromFirestore(Map<String, dynamic> data) {
    firstName = data['firstName'] as String?;
    lastName = data['lastName'] as String?;
    name = data['name'] as String? ?? ([firstName, lastName].whereType<String>().join(' ').trim());
    email = data['email'] as String?;
    phone = data['phone'] as String?;
    
    final dobStr = data['dob'];
    if (dobStr is String) {
      dob = DateTime.tryParse(dobStr);
    }
    
    final ints = data['interests'];
    if (ints is List) {
      interests = ints.cast<String>();
    }
    
    gender = data['gender'] as String?;
    language = data['language'] as String?;
  }

  Future<bool> login(String emailOrPhone, String password) async {
    loading = true;
    notifyListeners();
    
    try {
      // Determine if input is email or phone
      final isEmail = emailOrPhone.contains('@');
      
      if (isEmail) {
        // Email & Password login
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: emailOrPhone,
          password: password,
        );
        
        if (credential.user != null) {
          userId = credential.user!.uid;
          email = credential.user!.email;
          phone = credential.user!.phoneNumber;
          
          await _loadUserData();
          
          loading = false;
          status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      } else {
        // Phone number login - check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(emailOrPhone)
            .get();
            
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final storedEmail = data['email'] as String?;
          
          if (storedEmail != null) {
            // Try to sign in with stored email
            try {
              final credential = await _firebaseAuth.signInWithEmailAndPassword(
                email: storedEmail,
                password: password,
              );
              
              if (credential.user != null) {
                userId = credential.user!.uid;
                email = credential.user!.email;
                phone = emailOrPhone;
                
                _populateFromFirestore(data);
                
                loading = false;
                status = AuthStatus.authenticated;
                notifyListeners();
                return true;
              }
            } catch (e) {
              debugPrint('[AuthState] Phone login failed: $e');
            }
          }
        }
      }
      
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthState] Login error: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    loading = true;
    notifyListeners();
    
    try {
      // Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        userId = credential.user!.uid;
        this.email = email;
        this.phone = phone;
        this.name = name;
        
        // Split name into first and last
        final nameParts = name.split(' ');
        firstName = nameParts.first;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        // Save to Firestore using userId as document ID
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId!)
            .set({
          'userId': userId,
          'email': email,
          'phone': phone,
          'name': name,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Also save with phone as document ID for backward compatibility
        if (phone.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(phone)
              .set({
            'userId': userId,
            'email': email,
            'phone': phone,
            'name': name,
            'firstName': firstName,
            'lastName': lastName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        loading = false;
        status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthState] Registration error: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendOtp(String phone) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    this.phone = phone;
    otpSent = true;
    
    // DON'T reset user data yet - we'll check after OTP verification
    loading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String code) async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    
    final ok = code.length == 6;
    if (ok) {
      // Check if user already exists
      final userExists = await loadUserByPhone();
      
      if (userExists) {
        // User exists - mark as authenticated and skip onboarding
        loading = false;
        status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // New user - reset fields for onboarding flow
        name = null;
        firstName = null;
        lastName = null;
        dob = null;
        interests = [];
        gender = null;
        language = null;
      }
    }
    
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required DateTime dob,
    required List<String> interests,
    String? gender,
    String? language,
  }) async {
    loading = true;
    notifyListeners();
    
    this.firstName = firstName;
    this.lastName = lastName;
    name = ('$firstName $lastName').trim();
    if (email != null && email.isNotEmpty) this.email = email;
    if (phone != null && phone.isNotEmpty) this.phone = phone;
    this.dob = dob;
    this.interests = interests;
    this.gender = gender ?? this.gender;
    this.language = language ?? this.language;
    
    try {
      final updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'name': name,
        'email': this.email,
        'phone': this.phone,
        'dob': dob.toIso8601String(),
        'interests': interests,
        'gender': this.gender,
        'language': this.language,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Update by userId
      if (userId != null && userId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId!)
            .set(updateData, SetOptions(merge: true));
      }
      
      // Also update by phone if exists
      if (phone != null && phone!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(phone!)
            .set({
          ...updateData,
          'userId': userId,
          'email': email,
          'phone': phone,
        }, SetOptions(merge: true));
      }
      
      status = AuthStatus.authenticated;
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthState] Save profile error: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _firebaseAuth.signOut();
    status = AuthStatus.unauthenticated;
    userId = null;
    email = null;
    phone = null;
    name = null;
    firstName = null;
    lastName = null;
    dob = null;
    interests = [];
    gender = null;
    language = null;
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

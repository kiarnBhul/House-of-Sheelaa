import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:house_of_sheelaa/core/odoo/odoo_api_service.dart';

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
  
  // Address fields
  String? street;
  String? city;
  String? state;
  String? pincode;
  String? country;

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
      
      // Load user data properly with retry
      await _loadUserData();
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
    if (userId == null && phone == null) {
      debugPrint('[AuthState] No userId or phone to load data');
      return;
    }
    
    try {
      debugPrint('[AuthState] Loading user data - userId: $userId, phone: $phone');
      
      // Try loading by userId first (if available)
      if (userId != null && userId!.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId!)
            .get();
            
        if (doc.exists) {
          debugPrint('[AuthState] Found user by userId: $userId');
          _populateFromFirestore(doc.data()!);
          notifyListeners();
          return;
        }
      }
      
      // If not found by userId, try phone
      if (phone != null && phone!.isNotEmpty) {
        debugPrint('[AuthState] Trying to load by phone: $phone');
        final phoneDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(phone!)
            .get();
            
        if (phoneDoc.exists) {
          debugPrint('[AuthState] Found user by phone: $phone');
          _populateFromFirestore(phoneDoc.data()!);
          notifyListeners();
          
          // Update userId if it exists in the document
          final data = phoneDoc.data()!;
          if (data['userId'] != null && userId == null) {
            userId = data['userId'] as String?;
            debugPrint('[AuthState] Updated userId from document: $userId');
          }
          return;
        } else {
          debugPrint('[AuthState] No user data found for phone: $phone');
        }
      }
      
      debugPrint('[AuthState] No user data found in Firestore');
    } catch (e) {
      debugPrint('[AuthState] Error loading user data: $e');
    }
  }

  void _populateFromFirestore(Map<String, dynamic> data) {
    debugPrint('[AuthState] Populating from Firestore: ${data.keys}');
    
    firstName = data['firstName'] as String?;
    lastName = data['lastName'] as String?;
    name = data['name'] as String? ?? ([firstName, lastName].whereType<String>().join(' ').trim());
    email = data['email'] as String? ?? email; // Keep existing email if not in data
    phone = data['phone'] as String? ?? phone; // Keep existing phone if not in data
    
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
    
    // Load address fields
    street = data['street'] as String?;
    city = data['city'] as String?;
    state = data['state'] as String?;
    pincode = data['pincode'] as String?;
    country = data['country'] as String?;
    
    debugPrint('[AuthState] Populated: $firstName $lastName, email: $email, phone: $phone');
  }

  /// Reload user data from Firestore (useful for refreshing profile data)
  Future<void> reloadUserData() async {
    debugPrint('[AuthState] Reloading user data...');
    await _loadUserData();
    notifyListeners();
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
    String? street,
    String? city,
    String? state,
    String? pincode,
    String? country,
  }) async {
    loading = true;
    notifyListeners();
    
    debugPrint('[AuthState] Saving profile for userId: $userId');
    
    // Update local state first
    this.firstName = firstName;
    this.lastName = lastName;
    name = ('$firstName $lastName').trim();
    if (email != null && email.isNotEmpty) this.email = email;
    if (phone != null && phone.isNotEmpty) this.phone = phone;
    this.dob = dob;
    this.interests = interests;
    this.gender = gender ?? this.gender;
    this.language = language ?? this.language;
    this.street = street;
    this.city = city;
    this.state = state;
    this.pincode = pincode;
    this.country = country;
    
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
        'street': this.street,
        'city': this.city,
        'state': this.state,
        'pincode': this.pincode,
        'country': this.country,
        'userId': userId, // Always save userId
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Update by userId (primary)
      if (userId != null && userId!.isNotEmpty) {
        debugPrint('[AuthState] Saving to users/$userId');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId!)
            .set(updateData, SetOptions(merge: true));
      }
      
      // Also update by phone if exists (for phone login compatibility)
      if (this.phone != null && this.phone!.isNotEmpty) {
        debugPrint('[AuthState] Saving to users/${this.phone}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(this.phone!)
            .set(updateData, SetOptions(merge: true));
      }
      
      debugPrint('[AuthState] Profile saved successfully');
      
      // NEW: Sync profile to Odoo to ensure customer record exists
      if (this.email != null && this.email!.isNotEmpty) {
        try {
          debugPrint('[AuthState] 🔄 Syncing profile to Odoo...');
          final odooApi = OdooApiService();
          
          // Search for existing partner by email
          final partners = await odooApi.searchRead(
            model: 'res.partner',
            domain: [['email', '=', this.email]],
            fields: ['id', 'name', 'email', 'phone', 'is_company'],
            limit: 1,
          );
          
          final fullAddress = [
            this.street,
            this.city,
            this.state,
            this.pincode,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          
          if (partners.isNotEmpty) {
            // Update existing partner
            final partnerId = partners.first['id'] as int;
            debugPrint('[AuthState] ✏️ Updating existing Odoo partner: $partnerId');
            
            await odooApi.executeRpc(
              model: 'res.partner',
              method: 'write',
              args: [
                [partnerId],
                {
                  'name': name,
                  'email': this.email,
                  'phone': this.phone,
                  'street': fullAddress.isNotEmpty ? fullAddress : null,
                  'is_company': false,
                }
              ],
            );
            
            debugPrint('[AuthState] ✅ Odoo partner updated: $partnerId');
          } else {
            // Create new partner
            debugPrint('[AuthState] ➕ Creating new Odoo partner');
            
            final partnerId = await odooApi.executeRpc(
              model: 'res.partner',
              method: 'create',
              args: [
                {
                  'name': name,
                  'email': this.email,
                  'phone': this.phone,
                  'street': fullAddress.isNotEmpty ? fullAddress : null,
                  'is_company': false,
                }
              ],
            );
            
            debugPrint('[AuthState] ✅ Odoo partner created: $partnerId');
          }
          
          debugPrint('[AuthState] ✅ Profile synced to Odoo successfully');
        } catch (e) {
          debugPrint('[AuthState] ⚠️ Failed to sync to Odoo (non-critical): $e');
          // Don't fail the whole save if Odoo sync fails
        }
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

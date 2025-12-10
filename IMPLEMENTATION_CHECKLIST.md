# Implementation Checklist & Code Snippets

---

## 📋 Phase 1: Local Product Caching - DETAILED CHECKLIST

### Step 1: Create ProductCacheService Class
- [ ] Create file: `lib/core/cache/product_cache_service.dart`
- [ ] Copy complete code from Technical Implementation Guide
- [ ] Verify imports are correct:
  - `shared_preferences`
  - `json` 
  - `odoo_models`
- [ ] Test compilation: `flutter pub get` && `flutter analyze`

### Step 2: Update OdooState
- [ ] Open `lib/core/odoo/odoo_state.dart`
- [ ] Add import: `import '../cache/product_cache_service.dart';`
- [ ] Add property: `late ProductCacheService _productCacheService;`
- [ ] Update `_initialize()` method with cache loading
- [ ] Add method: `_loadCachedProducts()`
- [ ] Update `_loadDataInBackground()` to save to cache
- [ ] Add methods: `getCacheStatus()`, `refreshCache()`, `clearCache()`

### Step 3: Ensure OdooModels Have toJson()
- [ ] Check `lib/core/models/odoo_models.dart`
- [ ] Verify `OdooProduct` has `toJson()` method
- [ ] Verify `OdooService` has `toJson()` method
- [ ] Verify `OdooCategory` has `toJson()` method
- [ ] Verify all have `fromJson()` factory constructor
- [ ] If missing, add serialization using `json_serializable` or manual

### Step 4: Test Phase 1
- [ ] Run app: `flutter run`
- [ ] Configure Odoo connection
- [ ] Verify products load
- [ ] Close app completely
- [ ] Reopen app
- [ ] ✅ Verify products load INSTANTLY from cache
- [ ] ✅ Verify fresh data updates in background
- [ ] Check debug console for cache messages

### Step 5: Commit Code
- [ ] Git add new files: `git add lib/core/cache/product_cache_service.dart`
- [ ] Git add modified files: `git add lib/core/odoo/odoo_state.dart`
- [ ] Commit: `git commit -m "feat: Add local product caching (Phase 1)"`

---

## 📋 Phase 2: Remote Product Cache - DETAILED CHECKLIST

### Step 1: Create RemoteProductCacheService
- [ ] Create file: `lib/core/cache/remote_product_cache_service.dart`
- [ ] Copy complete code from Technical Implementation Guide
- [ ] Verify imports:
  - `cloud_firestore`
  - `odoo_models`
  - `json`
- [ ] Fix `_userId` getter to use actual Firebase auth (TODO comment)

### Step 2: Integrate with OdooState
- [ ] Open `lib/core/odoo/odoo_state.dart`
- [ ] Add import: `import '../cache/remote_product_cache_service.dart';`
- [ ] Add property: `final RemoteProductCacheService _remoteCacheService = RemoteProductCacheService();`
- [ ] Update `_loadDataInBackground()` to upload to Firestore:
  ```dart
  // After local cache save, also upload to Firestore (background)
  unawaited(_remoteCacheService.uploadProducts(
    freshProducts,
    services: freshServices,
    categories: freshCategories,
  ));
  ```

### Step 3: Update OdooState Initialization
- [ ] Add loading from Firestore on cold start:
  ```dart
  if (_products.isEmpty && OdooConfig.isConfigured) {
    // Try to load from Firestore as fallback
    final remoteData = await _remoteCacheService.downloadProducts();
    if ((remoteData['products'] as List).isNotEmpty) {
      // Deserialize and use
    }
  }
  ```

### Step 4: Setup Firestore Security Rules
- [ ] Go to Firebase Console
- [ ] Update Firestore Security Rules:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /products_cache/{userId=**} {
        allow read, write: if request.auth != null && 
                              request.auth.uid == userId;
      }
    }
  }
  ```
- [ ] Publish rules

### Step 5: Test Phase 2
- [ ] Configure Odoo connection
- [ ] Products fetch and cache to Firestore
- [ ] Check Firebase Console → Firestore → products_cache collection
- [ ] ✅ Verify documents created
- [ ] Clear app data
- [ ] Reopen app
- [ ] ✅ Verify products load from Firestore

### Step 6: Commit Code
- [ ] Git add: `git add lib/core/cache/remote_product_cache_service.dart`
- [ ] Git add modified: `git add lib/core/odoo/odoo_state.dart`
- [ ] Commit: `git commit -m "feat: Add remote product caching to Firestore (Phase 2)"`

---

## 📋 Phase 3: Auto-Save Configuration - DETAILED CHECKLIST

### Step 1: Update OdooConfig
- [ ] Open `lib/core/odoo/odoo_config.dart`
- [ ] Add new static methods at end of class:
  ```dart
  static Future<bool> saveAndSyncConfig({...})
  static void _autoSyncConfigToFirestore()
  static Future<bool> loadConfigWithFallback()
  ```
- [ ] Copy code from Technical Implementation Guide

### Step 2: Update Firestore Config Document
- [ ] Go to `lib/core/odoo/odoo_config.dart`
- [ ] Find `saveToFirestore()` method
- [ ] Ensure it saves to: `app_settings/odoo_config` collection
- [ ] Verify encryption is applied

### Step 3: Update OdooState Initialization
- [ ] Open `lib/core/odoo/odoo_state.dart`
- [ ] Update `_initialize()` to use new fallback:
  ```dart
  await OdooConfig.loadConfigWithFallback();
  ```

### Step 4: Update OdooConfigScreen
- [ ] Open `lib/features/admin/odoo_config_screen.dart`
- [ ] Find `_onConnect()` method
- [ ] Change from: `await odooState.configure(...)`
- [ ] Change to: `await OdooConfig.saveAndSyncConfig(...)`
- [ ] Add sync status indicator:
  ```dart
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Connected & Configuration saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  ```

### Step 5: Test Phase 3
- [ ] Clear app data: Settings → Apps → App → Storage → Clear Data
- [ ] Open app
- [ ] Go to Odoo Config screen
- [ ] Enter credentials and connect
- [ ] ✅ See "Connected & saved" message
- [ ] Close app completely
- [ ] Reopen app
- [ ] ✅ Config loads automatically (no config screen shown)
- [ ] Check Firebase Console → Firestore → app_settings collection
- [ ] ✅ Verify config document exists and is encrypted

### Step 6: Commit Code
- [ ] Git add modified: `git add lib/core/odoo/odoo_config.dart`
- [ ] Git add modified: `git add lib/core/odoo/odoo_state.dart`
- [ ] Git add modified: `git add lib/features/admin/odoo_config_screen.dart`
- [ ] Commit: `git commit -m "feat: Auto-save Odoo config with Firestore backup (Phase 3)"`

---

## 📋 Phase 4: Cache Management UI - DETAILED CHECKLIST

### Step 1: Create Cache Management Screen
- [ ] Create file: `lib/features/admin/cache_management_screen.dart`
- [ ] Copy complete code from Technical Implementation Guide
- [ ] Verify imports are correct

### Step 2: Add Route
- [ ] Open `lib/features/admin/app_admin.dart` (or router file)
- [ ] Add import: `import 'cache_management_screen.dart';`
- [ ] Add route:
  ```dart
  GoRoute(
    path: CacheManagementScreen.route,
    builder: (context, state) => const CacheManagementScreen(),
  ),
  ```

### Step 3: Add Menu Item
- [ ] Open your admin menu/navigation file
- [ ] Add list tile:
  ```dart
  ListTile(
    leading: Icon(Icons.cached),
    title: Text('Cache Management'),
    onTap: () => context.go(CacheManagementScreen.route),
  ),
  ```

### Step 4: Test Phase 4
- [ ] Run app
- [ ] Go to admin menu
- [ ] ✅ See "Cache Management" option
- [ ] Click it
- [ ] ✅ See cache status with product counts
- [ ] Click "Refresh Cache Now"
- [ ] ✅ Status updates
- [ ] Click "Clear All Cache"
- [ ] ✅ Confirm dialog appears
- [ ] Confirm clear
- [ ] ✅ Cache cleared message shows

### Step 5: Commit Code
- [ ] Git add: `git add lib/features/admin/cache_management_screen.dart`
- [ ] Git add modified: `git add lib/features/admin/app_admin.dart`
- [ ] Commit: `git commit -m "feat: Add cache management UI (Phase 4)"`

---

## 📋 Phase 5: Background Sync Service - DETAILED CHECKLIST

### Step 1: Create Background Sync Service
- [ ] Create file: `lib/core/sync/background_sync_service.dart`
- [ ] Create basic structure:
  ```dart
  import 'package:flutter/foundation.dart';
  
  class BackgroundSyncService {
    static const Duration _syncInterval = Duration(hours: 24);
    
    Future<void> scheduleDailySync() async {
      // Implementation
    }
    
    Future<void> syncIfNeeded() async {
      // Implementation
    }
  }
  ```

### Step 2: Implement Core Logic
- [ ] Add method to check if sync needed:
  ```dart
  bool _shouldSync(DateTime? lastSync) {
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > _syncInterval;
  }
  ```
- [ ] Add method to perform sync:
  ```dart
  Future<void> _performSync() async {
    // Fetch from Odoo and update cache
  }
  ```

### Step 3: Integrate with OdooState
- [ ] Add to `OdooState`:
  ```dart
  final BackgroundSyncService _syncService = BackgroundSyncService();
  ```
- [ ] Call after initialization:
  ```dart
  _syncService.scheduleDailySync();
  ```

### Step 4: Handle Connectivity
- [ ] Add connectivity_plus package to pubspec.yaml:
  ```yaml
  connectivity_plus: ^5.0.0
  ```
- [ ] Listen for connectivity changes:
  ```dart
  Connectivity().onConnectivityChanged.listen((result) {
    if (result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile) {
      _syncService.syncIfNeeded();
    }
  });
  ```

### Step 5: Test Phase 5
- [ ] Run app with simulation
- [ ] Verify sync scheduled
- [ ] Check logs for sync completion
- [ ] Disconnect internet
- [ ] ✅ Verify sync pauses
- [ ] Reconnect internet
- [ ] ✅ Verify sync resumes

### Step 6: Commit Code
- [ ] Git add: `git add lib/core/sync/background_sync_service.dart`
- [ ] Git add modified: `git add lib/core/odoo/odoo_state.dart`
- [ ] Commit: `git commit -m "feat: Add background sync service (Phase 5)"`

---

## 🧪 Testing Checklist (All Phases)

### Functionality Tests
- [ ] **Test 1:** Fresh app start with no config
  - [ ] Shows config screen
  - [ ] Can enter credentials
  - [ ] Products load
  - [ ] Config saved locally ✅
  - [ ] Config saved to Firestore ✅

- [ ] **Test 2:** App restart with config
  - [ ] Config loads instantly
  - [ ] Products load instantly from cache
  - [ ] Fresh products fetch in background
  - [ ] UI updates with fresh data

- [ ] **Test 3:** Offline mode
  - [ ] Close internet
  - [ ] Open app
  - [ ] Products display from cache ✅
  - [ ] No errors shown

- [ ] **Test 4:** App reinstall (Android)
  - [ ] Uninstall app
  - [ ] Clear app data
  - [ ] Reinstall app
  - [ ] Open app
  - [ ] Config restores from Firestore ✅
  - [ ] Products restore from Firestore ✅
  - [ ] No re-configuration needed ✅

- [ ] **Test 5:** Manual refresh
  - [ ] Go to Cache Management
  - [ ] Click "Refresh Now"
  - [ ] New data fetches ✅
  - [ ] Cache updates ✅

- [ ] **Test 6:** Clear cache
  - [ ] Go to Cache Management
  - [ ] Click "Clear All"
  - [ ] Confirm
  - [ ] Cache cleared ✅
  - [ ] Products gone ✅
  - [ ] Next startup, fetches fresh ✅

### Performance Tests
- [ ] App startup time < 2 seconds
- [ ] Cache load time < 500ms
- [ ] Firestore sync doesn't block UI
- [ ] Products display before sync completes

### Data Integrity Tests
- [ ] No duplicate products after sync
- [ ] Product prices match Odoo
- [ ] Product images load correctly
- [ ] Stock quantities accurate

### Security Tests
- [ ] Passwords encrypted in Firestore ✅
- [ ] API keys encrypted in Firestore ✅
- [ ] Firestore rules restrict access ✅
- [ ] Local storage uses SharedPreferences ✅

---

## 🐛 Troubleshooting Guide

### Problem: "Products not loading on restart"
**Solution:**
1. Check debug console for cache errors
2. Verify `toJson()`/`fromJson()` methods exist
3. Check SharedPreferences data exists:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   print(prefs.getKeys()); // Should include 'cached_products'
   ```

### Problem: "Firestore sync not working"
**Solution:**
1. Check Firebase Console → Firestore exists
2. Verify security rules are correct
3. Check user is authenticated
4. Check network connectivity
5. Verify document structure in console

### Problem: "Config not persisting"
**Solution:**
1. Verify `saveAndSyncConfig()` is called
2. Check `loadConfigWithFallback()` is used
3. Test manual save in debug mode
4. Check Firestore document exists

### Problem: "Cache getting too large"
**Solution:**
1. Implement cache TTL (7 days)
2. Compress JSON before saving
3. Implement periodic cleanup
4. Limit product count

---

## 📊 Before/After Verification

### Before Implementation
```
❌ Admin must reconfigure Odoo on each restart
❌ Products lost on app close
❌ Must wait for Odoo fetch each startup
❌ Doesn't work offline
❌ Reinstall = reconfigure again
```

### After Implementation
```
✅ Config persists forever
✅ Products available instantly
✅ Works offline with cache
✅ Firestore backup survives reinstall
✅ No re-configuration needed
```

---

## 📝 Git Commit History (Expected)

```
commit 1: "feat: Add local product caching (Phase 1)"
commit 2: "feat: Add remote product caching to Firestore (Phase 2)"
commit 3: "feat: Auto-save Odoo config with Firestore backup (Phase 3)"
commit 4: "feat: Add cache management UI (Phase 4)"
commit 5: "feat: Add background sync service (Phase 5)"
```

---

## ✅ Final Verification

After completing all phases:

- [ ] Local caching works (Phase 1) ✅
- [ ] Firestore backup works (Phase 2) ✅
- [ ] Config auto-saves (Phase 3) ✅
- [ ] Cache management UI works (Phase 4) ✅
- [ ] Background sync works (Phase 5) ✅
- [ ] All tests pass ✅
- [ ] No errors in console ✅
- [ ] UI is responsive ✅
- [ ] Works offline ✅
- [ ] Survives app reinstall ✅

---

## 🚀 Deployment Checklist

- [ ] All tests passing
- [ ] No console errors/warnings
- [ ] Code reviewed
- [ ] Security rules verified
- [ ] Database backups enabled
- [ ] Release notes prepared
- [ ] Beta testing completed
- [ ] Performance verified (startup < 2s)
- [ ] Production Firebase configured
- [ ] Rollback plan ready

---

**Document Status:** ✅ COMPLETE  
**Last Updated:** December 7, 2025  
**Ready for Development Team:** YES ✅

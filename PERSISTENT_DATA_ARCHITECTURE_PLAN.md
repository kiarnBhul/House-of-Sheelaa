# Persistent Data & Configuration Architecture Plan
**Date:** December 7, 2025  
**Goal:** Make Odoo configuration and product data persistent so users don't need to reconfigure on each app restart

---

## 🎯 Problem Statement

**Current Issue:**
- Every time the admin app restarts, Odoo configuration is lost
- Admin must re-enter credentials (URL, database, API key, username, password)
- Products must be fetched from Odoo again each session
- Not practical for production use

**Desired Outcome:**
- Configure Odoo **once** during initial setup
- Configuration persists **across app restarts**
- Products are **cached in Firestore** for offline access
- Admin can **skip Odoo connection** if data is already cached
- Optional: Ability to **update configuration** without losing cached data

---

## 📊 Current Architecture Analysis

### What We Have Now ✅

1. **Local Persistence (SharedPreferences)**
   - Stores configuration locally: base URL, database, API key, username, password
   - File: `lib/core/odoo/odoo_config.dart`
   - **Issue:** Lost on app uninstall or data clear

2. **Firestore Remote Backup**
   - Can save config to Firestore collection: `app_settings/odoo_config`
   - Can restore from Firestore when local storage is empty
   - Uses encryption for sensitive fields (via `CryptoHelper`)
   - **Issue:** Not automatic; must be explicitly triggered

3. **Auto-Connection Logic**
   - `OdooState` can auto-connect if config exists
   - Loads data in background on app start
   - File: `lib/core/odoo/odoo_state.dart`
   - **Issue:** Doesn't cache product data in Firestore

4. **Product Data Model**
   - Products fetched from Odoo: `OdooProduct`, `OdooService`, `OdooCategory`
   - Currently stored in memory only (not persisted)
   - **Issue:** Lost on app restart; requires fresh Odoo fetch

---

## 🏗️ Proposed Solution Architecture

### Three-Layer Persistence Strategy

```
┌─────────────────────────────────────────────────────┐
│          LAYER 1: LOCAL CACHE (RAM)                 │
│  (OdooState in-memory: products, services, events)  │
│           [Fastest, lost on restart]                │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│     LAYER 2: LOCAL PERSISTENCE (SharedPrefs)        │
│  (Config + Cached metadata, structured JSON)        │
│      [Fast, persists on app restart]                │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│    LAYER 3: REMOTE BACKUP (Firestore)               │
│  (Full config + product cache, encrypted)           │
│  [Slower, syncs across devices & reinstalls]        │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Implementation Plan (Step-by-Step)

### Phase 1: Local Product Caching (SharedPreferences)
**Timeline:** ~2-3 hours  
**Impact:** Products persist on app restart

#### 1.1 Create `ProductCacheService`
**File:** `lib/core/cache/product_cache_service.dart`

**Responsibilities:**
- Save products/services/categories to SharedPreferences as JSON
- Load cached products on app start
- Track last sync timestamp
- Provide TTL (Time-To-Live) for cache invalidation

**Methods:**
```dart
Future<void> saveProducts(List<OdooProduct> products)
Future<List<OdooProduct>> loadProducts() 
Future<void> saveServices(List<OdooService> services)
Future<List<OdooService>> loadServices()
Future<void> saveCategories(List<OdooCategory> categories)
Future<List<OdooCategory>> loadCategories()
Future<bool> isCacheExpired() // Check if older than 24 hours
Future<void> clearCache()
```

#### 1.2 Modify `OdooState` to use cache
**File:** `lib/core/odoo/odoo_state.dart`

**Changes:**
- On app initialization:
  1. Load products from cache first (instant load)
  2. Then fetch fresh data from Odoo in background
  3. Update cache if fresh data is newer
  
**Code Pattern:**
```dart
Future<void> _initialize() async {
  // 1. Load cached products immediately
  final cachedProducts = await _productCacheService.loadProducts();
  if (cachedProducts.isNotEmpty) {
    _products = cachedProducts;
    notifyListeners(); // UI shows cached data instantly
  }
  
  // 2. Fetch fresh data in background
  if (OdooConfig.isConfigured && _isAuthenticated) {
    _loadDataInBackground(); // Updates cache automatically
  }
}
```

---

### Phase 2: Remote Product Caching (Firestore)
**Timeline:** ~3-4 hours  
**Impact:** Products sync across devices; works after app reinstall

#### 2.1 Create `RemoteProductCacheService`
**File:** `lib/core/cache/remote_product_cache_service.dart`

**Firestore Collection Structure:**
```
products_cache/{userId}/
  ├── products: [serialized product list]
  ├── services: [serialized service list]
  ├── categories: [serialized category list]
  ├── lastSync: timestamp
  └── syncStatus: "complete" | "pending" | "failed"
```

**Responsibilities:**
- Save products to Firestore (encrypted or as-is)
- Load products from Firestore
- Sync products periodically (background)
- Handle conflicts (local vs remote)

**Methods:**
```dart
Future<bool> uploadProducts(List<OdooProduct> products)
Future<List<OdooProduct>> downloadProducts()
Future<DateTime?> getLastRemoteSyncTime()
Future<void> syncProductsToRemote() // Background task
```

#### 2.2 Modify `OdooState` to sync with Firestore
**File:** `lib/core/odoo/odoo_state.dart`

**Changes:**
- After fetching products from Odoo, save to Firestore
- On app start, try to load from Firestore if available
- Fall back to local cache if Firestore fails

**Loading Priority:**
1. Try RAM cache
2. Try local SharedPreferences cache
3. Try Firestore remote cache
4. Fetch from Odoo if all else fails

---

### Phase 3: Configuration Persistence Automation
**Timeline:** ~2 hours  
**Impact:** Configuration is always available (don't need to re-enter)

#### 3.1 Automatic Config Saving
**File:** `lib/core/odoo/odoo_config.dart`

**Modifications:**
- Add automatic save to Firestore after successful configuration
- Save to Firestore **on every login**
- Add sync status indicator

```dart
static Future<bool> saveAndSyncConfig({...}) async {
  // 1. Save locally
  await saveConfig(...);
  
  // 2. Save to Firestore (background)
  unawaited(_autoSyncConfigToFirestore());
  
  return true;
}

static Future<void> _autoSyncConfigToFirestore() async {
  try {
    await saveToFirestore();
  } catch (e) {
    debugPrint('[OdooConfig] Auto-sync failed: $e');
  }
}
```

#### 3.2 Improved Initialization Logic
**File:** `lib/core/odoo/odoo_state.dart`

```dart
Future<void> _initialize() async {
  // 1. Load local config first (instant)
  await OdooConfig.loadConfig();
  _isAuthenticated = OdooConfig.isAuthenticated;
  
  // 2. If local config missing, try Firestore (non-blocking)
  if (!OdooConfig.isConfigured) {
    unawaited(_tryRestoreFromFirestore());
  }
  
  // 3. If already configured, load cached data
  if (OdooConfig.isConfigured) {
    unawaited(_loadCachedDataAndRefresh());
  }
  
  notifyListeners();
}

Future<void> _loadCachedDataAndRefresh() async {
  // Load from cache first
  await _loadCachedProducts();
  
  // Refresh from Odoo in background
  if (_isAuthenticated) {
    unawaited(_refreshDataFromOdoo());
  }
}
```

---

### Phase 4: Cache Management & Updates
**Timeline:** ~2-3 hours  
**Impact:** Admin can manually update without re-entering everything

#### 4.1 Create `CacheManagementService`
**File:** `lib/core/cache/cache_management_service.dart`

**Responsibilities:**
- Manual cache refresh button
- Cache expiration logic
- Cache clearing on demand
- Sync status indicator

**Methods:**
```dart
Future<void> manualRefreshCache() // Force update from Odoo
Future<Map<String, dynamic>> getCacheStatus()
Future<void> clearAllCache()
Future<void> clearOldCache() // Clear if > 7 days old
```

#### 4.2 Add Cache Management UI
**File:** `lib/features/admin/cache_management_screen.dart` (NEW)

**Features:**
- Show last sync timestamp
- Show cache size
- "Refresh Now" button
- "Clear Cache" button
- Sync status indicator

---

### Phase 5: Background Sync Service (Optional)
**Timeline:** ~3-4 hours  
**Impact:** Products stay fresh without user action

#### 5.1 Create `BackgroundSyncService`
**File:** `lib/core/sync/background_sync_service.dart`

**Responsibilities:**
- Periodic Odoo sync (e.g., every 24 hours)
- Only sync if Wifi available
- Handle offline scenarios gracefully

**Features:**
```dart
Future<void> scheduleDailySync()
Future<void> syncIfNeeded() // Only if > 24 hours old
void onConnectivityChanged() // Re-sync when online
```

---

## 🔄 Data Flow Diagram

### On App Start (After Initial Configuration)
```
┌─ App Starts ─┐
│              │
├→ Load Local Config (SharedPrefs) ✓ FAST
│  │
│  ├→ Config found? YES
│  │  │
│  │  ├→ Load Cached Products (SharedPrefs) ✓ INSTANT
│  │  │  │
│  │  │  └→ Display to UI (OLD DATA - but available)
│  │  │
│  │  └→ Background: Fetch Fresh from Odoo
│  │     │
│  │     ├→ Success?
│  │     │  ├→ Save to Local Cache
│  │     │  ├→ Upload to Firestore (async)
│  │     │  └→ Update UI (NEW DATA)
│  │     │
│  │     └→ Failed? (No internet)
│  │        └→ Keep using cached data
│  │
│  └→ Config NOT found locally?
│     │
│     ├→ Try Firestore (REMOTE BACKUP)
│     │  │
│     │  └→ Found?
│     │     ├→ YES → Load from Firestore
│     │     │        Save to Local (for next time)
│     │     │
│     │     └→ NO → Show Config Screen
│     │            (Admin must configure)
│
└─ Ready ─┘
```

### On Admin Configuration
```
┌─ Admin fills config form ─┐
│                            │
├→ Test & Connect ✓
│  │
│  ├→ Success?
│  │  │
│  │  ├→ Save to SharedPrefs (local)
│  │  ├→ Save to Firestore (remote)
│  │  │
│  │  ├→ Fetch Products from Odoo
│  │  ├→ Cache to SharedPrefs
│  │  ├→ Upload to Firestore
│  │  │
│  │  └→ Show Success + Close
│  │
│  └→ Failed?
│     └→ Show Error (retry)
│
└─ Config Persisted ─┘
```

---

## 💾 Firestore Collection Schema

### 1. Configuration (encrypted)
```
app_settings/odoo_config
├── baseUrl: string
├── database: string
├── apiKey: string (encrypted)
├── username: string
├── password: string (encrypted)
├── proxyUrl: string
├── uid: number
├── sessionId: string (encrypted)
├── createdAt: timestamp
├── updatedAt: timestamp
└── version: number
```

### 2. Product Cache (normal or gzipped)
```
products_cache/{userId}
├── products: [
│    {
│      id: number,
│      name: string,
│      price: number,
│      image: string,
│      category: string,
│      description: string,
│      stock: number
│    },
│    ...
│  ]
├── services: [...]
├── categories: [...]
├── lastSync: timestamp
├── syncStatus: "complete" | "pending" | "failed"
└── version: number
```

---

## 🛡️ Security Considerations

### Sensitive Data Handling
- ✅ Already using `CryptoHelper.encryptString()` for:
  - API keys
  - Passwords
  - Session IDs
- ✅ Use Firebase Rules to restrict access (only authenticated admins)

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write their own config
    match /app_settings/{docId=**} {
      allow read, write: if request.auth != null && 
                             request.auth.uid == resource.data.uid;
    }
    
    // Only authenticated users can access product cache
    match /products_cache/{userId=**} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
```

---

## 📊 Implementation Timeline

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 1     | Local Product Caching | 2-3h | 🔴 CRITICAL |
| 2     | Remote Product Caching | 3-4h | 🟠 HIGH |
| 3     | Config Auto-Persistence | 2h | 🟠 HIGH |
| 4     | Cache Management UI | 2-3h | 🟡 MEDIUM |
| 5     | Background Sync | 3-4h | 🟡 MEDIUM |
| **Total** | | **12-17h** | |

---

## 📝 Implementation Checklist

### Phase 1 Checklist
- [ ] Create `ProductCacheService` class
- [ ] Add serialization/deserialization for products
- [ ] Add cache TTL logic
- [ ] Modify `OdooState._initialize()` to load from cache
- [ ] Test: Products appear instantly on restart
- [ ] Test: Fresh data updates cache in background

### Phase 2 Checklist
- [ ] Create `RemoteProductCacheService` class
- [ ] Add Firestore upload logic
- [ ] Add Firestore download logic
- [ ] Add conflict resolution (local vs remote)
- [ ] Modify `OdooState` to sync with Firestore
- [ ] Test: Products sync to Firestore after fetch
- [ ] Test: App loads from Firestore after clear local cache

### Phase 3 Checklist
- [ ] Add auto-save to Firestore in `OdooConfig`
- [ ] Modify init logic to try Firestore restore
- [ ] Test: Config persists after app restart
- [ ] Test: Config loads from Firestore if local cleared

### Phase 4 Checklist
- [ ] Create `CacheManagementService` class
- [ ] Create cache management UI screen
- [ ] Add "Refresh" button
- [ ] Add "Clear" button
- [ ] Add cache status indicators
- [ ] Add to admin menu

### Phase 5 Checklist
- [ ] Create `BackgroundSyncService` class
- [ ] Add periodic sync scheduling
- [ ] Add connectivity change listener
- [ ] Test background sync

---

## 🎯 Success Criteria

- ✅ Admin configures Odoo **once**
- ✅ Configuration persists **indefinitely** across restarts
- ✅ Products load from cache on app start (instant)
- ✅ Fresh products update in background (no wait)
- ✅ Works **offline** (shows cached products)
- ✅ Optional manual cache refresh available
- ✅ Works across **device reinstall** (via Firestore)
- ✅ No manual re-configuration needed after app restart

---

## 🚀 Next Steps

1. **Choose which phases to implement:**
   - Minimum viable: Phases 1 + 3 (2-4 days)
   - Full solution: All phases (5-7 days)
   - Quick win: Phase 1 only (1 day)

2. **Review & approval:** Share this plan with your team

3. **Start implementation:** Phases in order (dependencies)

4. **Testing:** Comprehensive testing after each phase

5. **Deploy:** Release when Phases 1-3 are complete

---

## 📞 Questions to Answer

1. **Should admin be able to change config after initial setup?**
   - Answer: ✅ YES (add "Update Configuration" option)

2. **Should products sync automatically in background?**
   - Answer: Consider Phase 5 (background sync)

3. **How often should cache refresh?**
   - Suggested: Every 24 hours or on manual request

4. **Should users (non-admin) see cached products?**
   - Answer: ✅ YES (main app should load from cache too)

5. **What happens if Odoo is offline?**
   - Answer: Show cached products (graceful degradation)

---

## 📚 Related Files to Modify

```
lib/
├── core/
│   ├── odoo/
│   │   ├── odoo_config.dart ← MODIFY (auto-save)
│   │   ├── odoo_state.dart ← MODIFY (load cache & Firestore)
│   │   └── odoo_api_service.dart (no changes needed)
│   └── cache/ ← NEW
│       ├── product_cache_service.dart ← NEW
│       ├── remote_product_cache_service.dart ← NEW
│       └── cache_management_service.dart ← NEW (Phase 4)
├── features/
│   └── admin/
│       ├── odoo_config_screen.dart ← MODIFY (show sync status)
│       └── cache_management_screen.dart ← NEW (Phase 4)
└── models/
    └── odoo_models.dart (add JSON serialization if not present)
```

---

**Document Status:** ✅ Complete & Ready for Implementation  
**Last Updated:** December 7, 2025

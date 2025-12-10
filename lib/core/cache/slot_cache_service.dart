import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/odoo_models.dart';

/// Ultra-fast slot caching service for instant calendar loading
/// Caches appointment slots with intelligent invalidation
class SlotCacheService {
  static const String _keyPrefix = 'cached_slots_';
  static const String _keyAvailabilityPrefix = 'cached_availability_';
  static const Duration _slotCacheDuration = Duration(minutes: 15); // Slots valid for 15 minutes (quick refresh)
  static const Duration _availabilityCacheDuration = Duration(hours: 2); // Availability schedule valid for 2 hours
  
  // In-memory cache for ultra-fast access
  static final Map<String, List<OdooAppointmentSlot>> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheTimestamps = {};
  static final Map<String, List<Map<String, dynamic>>> _availabilityMemoryCache = {};
  static final Map<String, DateTime> _availabilityMemoryTimestamps = {};
  
  /// Generate cache key for slots
  static String _slotCacheKey(int appointmentTypeId, String dateStr, int? staffId) {
    return '$_keyPrefix${appointmentTypeId}_${dateStr}_${staffId ?? 'all'}';
  }
  
  /// Generate cache key for availability schedule
  static String _availabilityCacheKey(int appointmentTypeId) {
    return '$_keyAvailabilityPrefix$appointmentTypeId';
  }
  
  /// Cache appointment slots (both memory and persistent)
  static Future<void> cacheSlots({
    required int appointmentTypeId,
    required DateTime date,
    int? staffId,
    required List<OdooAppointmentSlot> slots,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final cacheKey = _slotCacheKey(appointmentTypeId, dateStr, staffId);
      
      // Memory cache (instant access)
      _memoryCache[cacheKey] = slots;
      _memoryCacheTimestamps[cacheKey] = DateTime.now();
      
      // Persistent cache (survives app restart)
      final prefs = await SharedPreferences.getInstance();
      final jsonList = slots.map((s) => {
        'startTime': s.startTime.toIso8601String(),
        'endTime': s.endTime.toIso8601String(),
        'staffId': s.staffId,
        'staffName': s.staffName,
      }).toList();
      
      await prefs.setString('$cacheKey', jsonEncode(jsonList));
      await prefs.setInt('${cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[SlotCache] ✅ Cached ${slots.length} slots for $dateStr (staff: ${staffId ?? 'all'})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to cache slots: $e');
      }
    }
  }
  
  /// Load cached slots (memory-first, then persistent)
  static Future<List<OdooAppointmentSlot>?> loadSlots({
    required int appointmentTypeId,
    required DateTime date,
    int? staffId,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final cacheKey = _slotCacheKey(appointmentTypeId, dateStr, staffId);
      
      // Check memory cache first (instant)
      if (_memoryCache.containsKey(cacheKey)) {
        final timestamp = _memoryCacheTimestamps[cacheKey];
        if (timestamp != null && DateTime.now().difference(timestamp) < _slotCacheDuration) {
          final slots = _memoryCache[cacheKey]!;
          if (kDebugMode) {
            debugPrint('[SlotCache] ⚡ Instant load from memory: ${slots.length} slots');
          }
          return slots;
        }
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_ts');
      
      if (jsonString != null && timestamp != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp)
        );
        
        if (cacheAge < _slotCacheDuration) {
          final jsonList = jsonDecode(jsonString) as List;
          final slots = jsonList.map((json) => OdooAppointmentSlot(
            startTime: DateTime.parse(json['startTime']),
            endTime: DateTime.parse(json['endTime']),
            staffId: json['staffId'] as int? ?? 0,
            staffName: json['staffName'] as String?,
          )).toList();
          
          // Update memory cache
          _memoryCache[cacheKey] = slots;
          _memoryCacheTimestamps[cacheKey] = DateTime.fromMillisecondsSinceEpoch(timestamp);
          
          if (kDebugMode) {
            debugPrint('[SlotCache] ✅ Loaded ${slots.length} cached slots (age: ${cacheAge.inMinutes}m)');
          }
          return slots;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to load cached slots: $e');
      }
      return null;
    }
  }
  
  /// Cache availability schedule (reusable across dates)
  static Future<void> cacheAvailabilitySchedule({
    required int appointmentTypeId,
    required List<Map<String, dynamic>> availabilitySlots,
  }) async {
    try {
      final cacheKey = _availabilityCacheKey(appointmentTypeId);
      
      // Memory cache
      _availabilityMemoryCache[cacheKey] = availabilitySlots;
      _availabilityMemoryTimestamps[cacheKey] = DateTime.now();
      
      // Persistent cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(availabilitySlots));
      await prefs.setInt('${cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('[SlotCache] ✅ Cached availability schedule (${availabilitySlots.length} rules)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to cache availability: $e');
      }
    }
  }
  
  /// Load cached availability schedule
  static Future<List<Map<String, dynamic>>?> loadAvailabilitySchedule({
    required int appointmentTypeId,
  }) async {
    try {
      final cacheKey = _availabilityCacheKey(appointmentTypeId);
      
      // Check memory cache first
      if (_availabilityMemoryCache.containsKey(cacheKey)) {
        final timestamp = _availabilityMemoryTimestamps[cacheKey];
        if (timestamp != null && DateTime.now().difference(timestamp) < _availabilityCacheDuration) {
          if (kDebugMode) {
            debugPrint('[SlotCache] ⚡ Instant availability from memory');
          }
          return _availabilityMemoryCache[cacheKey];
        }
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_ts');
      
      if (jsonString != null && timestamp != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp)
        );
        
        if (cacheAge < _availabilityCacheDuration) {
          final jsonList = jsonDecode(jsonString) as List;
          final availability = jsonList.cast<Map<String, dynamic>>();
          
          // Update memory cache
          _availabilityMemoryCache[cacheKey] = availability;
          _availabilityMemoryTimestamps[cacheKey] = DateTime.fromMillisecondsSinceEpoch(timestamp);
          
          if (kDebugMode) {
            debugPrint('[SlotCache] ✅ Loaded cached availability (age: ${cacheAge.inHours}h)');
          }
          return availability;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to load availability: $e');
      }
      return null;
    }
  }
  
  /// Pre-cache slots for multiple dates (batch operation)
  static Future<void> preCacheMultipleDates({
    required int appointmentTypeId,
    required List<DateTime> dates,
    int? staffId,
    required Future<List<OdooAppointmentSlot>> Function(DateTime date) fetchSlots,
  }) async {
    if (kDebugMode) {
      debugPrint('[SlotCache] 🚀 Pre-caching ${dates.length} dates...');
    }
    
    final futures = dates.map((date) async {
      try {
        final slots = await fetchSlots(date);
        await cacheSlots(
          appointmentTypeId: appointmentTypeId,
          date: date,
          staffId: staffId,
          slots: slots,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SlotCache] ⚠️ Failed to pre-cache date $date: $e');
        }
      }
    });
    
    await Future.wait(futures);
    
    if (kDebugMode) {
      debugPrint('[SlotCache] ✅ Pre-caching complete');
    }
  }
  
  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      int cleared = 0;
      
      for (var key in keys) {
        if (key.startsWith(_keyPrefix) && key.endsWith('_ts')) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final age = now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
            if (age > _slotCacheDuration) {
              final dataKey = key.replaceAll('_ts', '');
              await prefs.remove(dataKey);
              await prefs.remove(key);
              cleared++;
            }
          }
        }
      }
      
      if (kDebugMode && cleared > 0) {
        debugPrint('[SlotCache] 🧹 Cleared $cleared expired entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to clear expired cache: $e');
      }
    }
  }
  
  /// Clear all slot cache
  static Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _memoryCacheTimestamps.clear();
      _availabilityMemoryCache.clear();
      _availabilityMemoryTimestamps.clear();
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(_keyPrefix) || key.startsWith(_keyAvailabilityPrefix)) {
          await prefs.remove(key);
        }
      }
      
      if (kDebugMode) {
        debugPrint('[SlotCache] ✅ Cleared all slot cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SlotCache] ❌ Failed to clear cache: $e');
      }
    }
  }
}

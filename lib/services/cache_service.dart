import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../models/team.dart';

/// Cache service for managing API data and image caching
class CacheService {
  static const String _citiesCacheKey = 'cached_cities';
  static const String _userStatsCacheKey = 'cached_user_stats';
  static const String _teamsCacheKey = 'cached_teams';

  static const Duration _citiesCacheDuration = Duration(hours: 24);
  static const Duration _userStatsCacheDuration = Duration(hours: 1);
  static const Duration _teamsCacheDuration = Duration(hours: 6);

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late final DefaultCacheManager _imageCacheManager;
  late final SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _imageCacheManager = DefaultCacheManager();
  }

  // Image caching methods
  DefaultCacheManager get imageCacheManager => _imageCacheManager;

  Future<FileInfo?> getCachedImage(String url) async {
    return await _imageCacheManager.getFileFromCache(url);
  }

  Future<FileInfo> downloadAndCacheImage(String url) async {
    return await _imageCacheManager.downloadFile(url);
  }

  Future<void> clearImageCache() async {
    await _imageCacheManager.emptyCache();
  }

  // API data caching methods
  Future<void> _setCacheData(String key, dynamic data, DateTime expiry) async {
    final cacheData = {'data': data, 'expiry': expiry.toIso8601String()};
    await _prefs.setString(key, jsonEncode(cacheData));
  }

  Map<String, dynamic>? _getCacheData(String key) {
    final cachedString = _prefs.getString(key);
    if (cachedString == null) return null;

    try {
      final cacheData = jsonDecode(cachedString);
      final expiry = DateTime.parse(cacheData['expiry']);
      if (DateTime.now().isAfter(expiry)) {
        // Cache expired, remove it
        _prefs.remove(key);
        return null;
      }
      return cacheData['data'];
    } catch (e) {
      // Invalid cache data, remove it
      _prefs.remove(key);
      return null;
    }
  }

  // Cities caching
  Future<void> cacheCities(List<City> cities) async {
    final expiry = DateTime.now().add(_citiesCacheDuration);
    await _setCacheData(
      _citiesCacheKey,
      cities.map((c) => c.toJson()).toList(),
      expiry,
    );
  }

  List<City>? getCachedCities() {
    final data = _getCacheData(_citiesCacheKey);
    if (data == null) return null;
    try {
      return (data as List).map((json) => City.fromJson(json)).toList();
    } catch (e) {
      _prefs.remove(_citiesCacheKey);
      return null;
    }
  }

  // User stats caching
  Future<void> cacheUserStats(Map<String, dynamic> stats) async {
    final expiry = DateTime.now().add(_userStatsCacheDuration);
    await _setCacheData(_userStatsCacheKey, stats, expiry);
  }

  Map<String, dynamic>? getCachedUserStats() {
    return _getCacheData(_userStatsCacheKey);
  }

  // Teams caching
  Future<void> cacheTeams(List<Team> teams) async {
    final expiry = DateTime.now().add(_teamsCacheDuration);
    await _setCacheData(
      _teamsCacheKey,
      teams.map((t) => t.toJson()).toList(),
      expiry,
    );
  }

  List<Team>? getCachedTeams() {
    final data = _getCacheData(_teamsCacheKey);
    if (data == null) return null;
    try {
      return (data as List).map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      _prefs.remove(_teamsCacheKey);
      return null;
    }
  }

  // Cache invalidation methods with smart refresh
  Future<void> invalidateCitiesCache({bool refresh = false}) async {
    await _prefs.remove(_citiesCacheKey);
  }

  Future<void> invalidateUserStatsCache({bool refresh = false}) async {
    await _prefs.remove(_userStatsCacheKey);
  }

  Future<void> invalidateTeamsCache({bool refresh = false}) async {
    await _prefs.remove(_teamsCacheKey);
  }

  // Cache warming - preload critical data
  Future<void> warmCache({
    Future<List<City>> Function()? fetchCities,
    Future<List<Team>> Function()? fetchTeams,
  }) async {
    try {
      if (fetchCities != null && getCachedCities() == null) {
        final cities = await fetchCities();
        await cacheCities(cities);
      }
      if (fetchTeams != null && getCachedTeams() == null) {
        final teams = await fetchTeams();
        await cacheTeams(teams);
      }
    } catch (e) {
      // Silently fail cache warming
    }
  }

  Future<void> invalidateAllCaches() async {
    await _prefs.remove(_citiesCacheKey);
    await _prefs.remove(_userStatsCacheKey);
    await _prefs.remove(_teamsCacheKey);
    await clearImageCache();
  }

  // Background cache refresh
  Future<void> refreshCriticalData(Function refreshCallback) async {
    try {
      await refreshCallback();
    } catch (e) {
      // Silently fail background refresh - cached data will be used
      // Background refresh failures are not critical for app functionality
    }
  }

  // Cache size management
  Future<int> getCacheSize() async {
    final keys = _prefs.getKeys();
    int size = 0;
    for (final key in keys) {
      if (key.startsWith('cached_')) {
        final value = _prefs.getString(key);
        if (value != null) {
          size += value.length * 2; // Rough estimate in bytes
        }
      }
    }
    return size;
  }

  Future<void> clearExpiredCache() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith('cached_'))
        .toList();

    for (final key in keys) {
      final cachedString = _prefs.getString(key);
      if (cachedString != null) {
        try {
          final cacheData = jsonDecode(cachedString);
          final expiry = DateTime.parse(cacheData['expiry']);
          if (DateTime.now().isAfter(expiry)) {
            await _prefs.remove(key);
          }
        } catch (e) {
          await _prefs.remove(key);
        }
      }
    }
  }

  // Offline support
  bool get isOfflineMode => false; // Could be enhanced with connectivity check

  Future<List<City>> getCitiesWithOfflineSupport() async {
    final cached = getCachedCities();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    throw Exception(
      'No cached cities available and offline mode not supported',
    );
  }

  Future<Map<String, dynamic>> getUserStatsWithOfflineSupport() async {
    final cached = getCachedUserStats();
    if (cached != null) {
      return cached;
    }
    return {'matches_joined': 0, 'matches_created': 0, 'teams_owned': 0};
  }
}

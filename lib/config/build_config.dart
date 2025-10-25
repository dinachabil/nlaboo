import 'package:flutter/foundation.dart';

/// Build-time configuration constants
/// These values are injected at build time using --dart-define flags
class BuildConfig {
  // Environment constants (injected at build time)
  static const String _environment = String.fromEnvironment(
    'BUILD_ENV',
    defaultValue: 'development',
  );

  static const String _appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'FootConnect',
  );

  static const String _appSuffix = String.fromEnvironment(
    'APP_SUFFIX',
    defaultValue: '',
  );

  static const String _bundleId = String.fromEnvironment(
    'BUNDLE_ID',
    defaultValue: 'com.example.frontend',
  );

  static const bool _enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const bool _enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );

  static const bool _enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: kDebugMode,
  );

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8001/api/v1',
  );

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Computed properties
  static AppEnvironment get environment {
    switch (_environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  static String get appName {
    return _appSuffix.isNotEmpty ? '$_appName $_appSuffix' : _appName;
  }

  static String get bundleId => _bundleId;
  static bool get enableAnalytics => _enableAnalytics;
  static bool get enableCrashReporting => _enableCrashReporting;
  static bool get enableDebugLogging => _enableDebugLogging;
  static String get apiBaseUrl => _apiBaseUrl;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  // Environment checks
  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;

  // Feature flags based on environment
  static bool get enableDevTools => isDevelopment;
  static bool get enablePerformanceMonitoring => isProduction || isStaging;
  static bool get enableErrorReporting => isProduction || isStaging;
  static bool get enableRemoteConfig => isProduction || isStaging;

  // Debug helpers - only available in debug builds
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('=== BuildConfig ===');
      debugPrint('Environment: $_environment');
      debugPrint('App Name: $appName');
      debugPrint('Bundle ID: $bundleId');
      debugPrint('Analytics: $enableAnalytics');
      debugPrint('Crash Reporting: $enableCrashReporting');
      debugPrint('Debug Logging: $enableDebugLogging');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint(
        'Supabase URL: ${supabaseUrl.isNotEmpty ? "configured" : "not configured"}',
      );
      debugPrint('==================');
    }
  }
}

/// Environment enum for type safety
enum AppEnvironment { development, staging, production }

/// Extension for environment display names
extension AppEnvironmentExtension on AppEnvironment {
  String get displayName {
    switch (this) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  String get shortName {
    switch (this) {
      case AppEnvironment.development:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'prod';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment types supported by the application
enum AppEnvironment { development, staging, production }

/// Configuration validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Centralized application configuration management
class AppConfig {
  static AppConfig? _instance;
  late final AppEnvironment _environment;
  late final Map<String, String> _envVars;

  // Configuration sections
  late final SupabaseConfig _supabase;
  late final ApiConfig _api;
  late final AuthConfig _auth;
  late final AppSettings _appSettings;

  // Private constructor
  AppConfig._();

  /// Get the singleton instance
  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig not initialized. Call AppConfig.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize the configuration with environment validation
  static Future<ValidationResult> initialize({
    required AppEnvironment environment,
  }) async {
    if (_instance != null) {
      throw StateError('AppConfig already initialized');
    }

    final config = AppConfig._();
    _instance = config;

    try {
      await dotenv.load(fileName: '.env');
    
      config._environment = environment;
      config._envVars = Map<String, String>.from(dotenv.env);

      // Initialize configuration sections with the resolved env vars
      config._supabase = SupabaseConfig._fromEnv(config._envVars);
      config._api = ApiConfig._fromEnv(config._envVars);
      config._auth = AuthConfig._fromEnv(config._envVars);
      config._appSettings = AppSettings._fromEnv(config._envVars);

      // Validate configuration
      return config._validateConfiguration();
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Failed to initialize configuration: $e'],
      );
    }
  }


  /// Validate the entire configuration
  ValidationResult _validateConfiguration() {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate Supabase configuration
    final supabaseResult = _supabase.validate(_environment);
    errors.addAll(supabaseResult.errors);
    warnings.addAll(supabaseResult.warnings);

    // Validate API configuration
    final apiResult = _api.validate();
    errors.addAll(apiResult.errors);
    warnings.addAll(apiResult.warnings);

    // Validate Auth configuration
    final authResult = _auth.validate();
    errors.addAll(authResult.errors);
    warnings.addAll(authResult.warnings);

    // Validate App settings
    final appResult = _appSettings.validate();
    errors.addAll(appResult.errors);
    warnings.addAll(appResult.warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Getters for configuration sections
  AppEnvironment get environment => _environment;
  SupabaseConfig get supabase => _supabase;
  ApiConfig get api => _api;
  AuthConfig get auth => _auth;
  AppSettings get appSettings => _appSettings;

  /// Get raw environment variable (for debugging)
  String? getEnv(String key) => _envVars[key];

  /// Check if running in development
  bool get isDevelopment => _environment == AppEnvironment.development;

  /// Check if running in staging
  bool get isStaging => _environment == AppEnvironment.staging;

  /// Check if running in production
  bool get isProduction => _environment == AppEnvironment.production;

  /// Get environment name as string
  String get environmentName {
    switch (_environment) {
      case AppEnvironment.development:
        return 'development';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }
}

/// Supabase configuration section
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig._({required this.url, required this.anonKey});

  factory SupabaseConfig._fromEnv(Map<String, String> env) {
    return SupabaseConfig._(
      url: env['SUPABASE_URL'] ?? '',
      anonKey: env['SUPABASE_ANON_KEY'] ?? '',
    );
  }

  ValidationResult validate(AppEnvironment environment) {
    final errors = <String>[];
    final warnings = <String>[];

    if (url.isEmpty) {
      errors.add('SUPABASE_URL is required but not set');
    } else if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      warnings.add('SUPABASE_URL does not appear to be a valid Supabase URL');
    }

    if (anonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY is required but not set');
    } else if (anonKey.length < 100) {
      warnings.add('SUPABASE_ANON_KEY appears to be unusually short');
    }

    // Additional validation for production
    if (environment == AppEnvironment.production) {
      if (url.contains('localhost') || url.contains('127.0.0.1')) {
        errors.add('SUPABASE_URL cannot use localhost in production');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// API configuration section
class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;

  const ApiConfig._({
    required this.baseUrl,
    required this.timeout,
    required this.maxRetries,
  });

  factory ApiConfig._fromEnv(Map<String, String> env) {
    return ApiConfig._(
      baseUrl: env['API_BASE_URL'] ?? 'http://localhost:8001/api/v1',
      timeout: Duration(
        seconds: int.tryParse(env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30,
      ),
      maxRetries: int.tryParse(env['API_MAX_RETRIES'] ?? '3') ?? 3,
    );
  }

  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (baseUrl.isEmpty) {
      errors.add('API_BASE_URL is required but not set');
    } else {
      try {
        final uri = Uri.parse(baseUrl);
        if (!uri.isAbsolute) {
          errors.add('API_BASE_URL must be an absolute URL');
        }
        if (!uri.scheme.startsWith('http')) {
          warnings.add('API_BASE_URL should use HTTPS in production');
        }
      } catch (e) {
        errors.add('API_BASE_URL is not a valid URL: $e');
      }
    }

    if (timeout.inSeconds < 5) {
      warnings.add(
        'API_TIMEOUT_SECONDS is very low (${timeout.inSeconds}s), consider increasing',
      );
    }

    if (maxRetries < 0) {
      errors.add('API_MAX_RETRIES cannot be negative');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Authentication configuration section
class AuthConfig {
  final String webRedirectUrl;
  final String mobileRedirectUrl;
  final Duration sessionTimeout;

  const AuthConfig._({
    required this.webRedirectUrl,
    required this.mobileRedirectUrl,
    required this.sessionTimeout,
  });

  factory AuthConfig._fromEnv(Map<String, String> env) {
    return AuthConfig._(
      webRedirectUrl:
          env['WEB_REDIRECT_URL'] ?? 'https://yourapp.vercel.app/auth-callback',
      mobileRedirectUrl: env['MOBILE_REDIRECT_URL'] ?? 'myapp://auth-callback/',
      sessionTimeout: Duration(
        hours: int.tryParse(env['SESSION_TIMEOUT_HOURS'] ?? '24') ?? 24,
      ),
    );
  }

  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (webRedirectUrl.isEmpty) {
      errors.add('WEB_REDIRECT_URL is required but not set');
    } else {
      try {
        final uri = Uri.parse(webRedirectUrl);
        if (!uri.isAbsolute) {
          errors.add('WEB_REDIRECT_URL must be an absolute URL');
        }
      } catch (e) {
        errors.add('WEB_REDIRECT_URL is not a valid URL: $e');
      }
    }

    if (mobileRedirectUrl.isEmpty) {
      errors.add('MOBILE_REDIRECT_URL is required but not set');
    } else if (!mobileRedirectUrl.contains('://')) {
      warnings.add(
        'MOBILE_REDIRECT_URL should be a deep link URL (e.g., myapp://callback)',
      );
    }

    if (sessionTimeout.inHours < 1) {
      warnings.add(
        'SESSION_TIMEOUT_HOURS is very low (${sessionTimeout.inHours}h)',
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Application settings section
class AppSettings {
  final bool enableLogging;
  final bool enableAnalytics;
  final int cacheSizeMb;
  final Duration cacheExpiration;

  const AppSettings._({
    required this.enableLogging,
    required this.enableAnalytics,
    required this.cacheSizeMb,
    required this.cacheExpiration,
  });

  factory AppSettings._fromEnv(Map<String, String> env) {
    return AppSettings._(
      enableLogging: env.containsKey('ENABLE_LOGGING')
          ? env['ENABLE_LOGGING']!.toLowerCase() == 'true'
          : true,
      enableAnalytics: env.containsKey('ENABLE_ANALYTICS')
          ? env['ENABLE_ANALYTICS']!.toLowerCase() == 'true'
          : !kDebugMode,
      cacheSizeMb: int.tryParse(env['CACHE_SIZE_MB'] ?? '50') ?? 50,
      cacheExpiration: Duration(
        hours: int.tryParse(env['CACHE_EXPIRATION_HOURS'] ?? '24') ?? 24,
      ),
    );
  }

  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (cacheSizeMb < 10) {
      warnings.add(
        'CACHE_SIZE_MB is very low (${cacheSizeMb}MB), consider increasing',
      );
    }

    if (cacheExpiration.inHours < 1) {
      warnings.add(
        'CACHE_EXPIRATION_HOURS is very low (${cacheExpiration.inHours}h)',
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loaded from environment variables via flutter_dotenv.
/// These are defined as getters so the values are read at access time (after
/// dotenv.load has been called in main).
String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

/// API configuration for backend endpoints
String get apiBaseUrl =>
    dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8001/api/v1';

/// Redirect URLs for email confirmation
String get webRedirectUrl =>
    dotenv.env['WEB_REDIRECT_URL'] ??
    'https://yourapp.vercel.app/auth-callback';
String get mobileRedirectUrl =>
    dotenv.env['MOBILE_REDIRECT_URL'] ?? 'myapp://auth-callback/';

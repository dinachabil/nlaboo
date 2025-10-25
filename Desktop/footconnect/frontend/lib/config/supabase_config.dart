import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loaded from environment variables via flutter_dotenv.
/// These are defined as getters so the values are read at access time (after
/// dotenv.load has been called in main).
String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

/// Redirect URLs for email confirmation
String get webRedirectUrl =>
    dotenv.env['WEB_REDIRECT_URL'] ?? 'https://yourapp.vercel.app/auth-callback';
String get mobileRedirectUrl =>
    dotenv.env['MOBILE_REDIRECT_URL'] ?? 'myapp://auth-callback/';
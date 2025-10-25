import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'config/environment_validator.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/match_provider.dart';
import 'providers/team_provider.dart';
import 'providers/notification_provider.dart';
import 'repositories/match_repository.dart';
import 'repositories/team_repository.dart';
import 'repositories/user_repository.dart';
import 'services/api_service.dart';
import 'services/localization_service.dart';
import 'services/error_handler.dart';
import 'services/cache_service.dart';
import 'widgets/enhanced_error_boundary.dart';
import 'app_router.dart';

/// Determine environment based on build flavor or runtime detection
AppEnvironment _detectEnvironment() {
  // Check for environment override in system properties
  const environment = String.fromEnvironment('ENVIRONMENT');
  if (environment.isNotEmpty) {
    switch (environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
    }
  }

  // Default to development for debug builds
  return AppEnvironment.development;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect environment
  final environment = _detectEnvironment();

  try {
    // Validate environment configuration
    await EnvironmentValidator.validateAndThrow(environment: environment);

    // Get validated configuration
    final config = AppConfig.instance;

    // Initialize Supabase with validated configuration
    await Supabase.initialize(
      url: config.supabase.url,
      anonKey: config.supabase.anonKey,
    );
  } catch (e) {
    // Log the initialization error
    ErrorHandler.logError(e, null, 'AppInitialization');

    // Show detailed error screen for configuration issues
    runApp(
      ScreenErrorBoundary(
        screenName: 'ConfigurationError',
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Configuration Error',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e is EnvironmentValidationException
                            ? e.toString()
                            : 'App initialization failed: $e\n\nPlease check your configuration and try again.',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Restart the app (this will re-run main)
                          runApp(
                            const MaterialApp(
                              home: Scaffold(
                                body: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          );
                          main();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Load initial language from shared preferences
  final localizationService = LocalizationService();
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language_code') ?? 'en';
  await localizationService.loadLanguage(savedLanguage);

  // Initialize cache service
  final cacheService = CacheService();
  await cacheService.initialize();

  // Start app immediately
  runApp(const MyApp());

  // Warm cache in background (non-blocking)
  Future.microtask(() async {
    try {
      final apiService = ApiService();
      await cacheService.warmCache(
        fetchCities: () => apiService.getCities(),
        fetchTeams: () => apiService.getAllTeams(limit: 50),
      );
    } catch (e) {
      // Silently fail cache warming - app will fetch data on demand
      debugPrint('Cache warming failed: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services and repositories
    final apiService = ApiService();
    final matchRepository = MatchRepository(apiService);
    final teamRepository = TeamRepository(apiService);
    final userRepository = UserRepository(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => apiService),
        Provider(create: (_) => matchRepository),
        Provider(create: (_) => teamRepository),
        Provider(create: (_) => userRepository),
        ChangeNotifierProvider(
          create: (_) => MatchProvider(matchRepository, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TeamProvider(teamRepository, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(userRepository, apiService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: LocalizationService().translate('app_name'),
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B5E20),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
                titleLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B5E20),
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF424242)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF424242)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('fr', ''), // French
              Locale('ar', ''), // Arabic
            ],
            locale: Locale(themeProvider.languageCode),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

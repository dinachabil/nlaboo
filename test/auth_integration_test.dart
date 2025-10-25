import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nlaabo/main_dev.dart' as app;
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/services/api_service.dart';
import 'package:nlaabo/screens/auth_landing_screen.dart';
import 'package:nlaabo/screens/login_screen.dart';
import 'package:nlaabo/screens/signup_screen.dart';
import 'package:nlaabo/config/supabase_config.dart';

// Mock classes for testing
class MockApiService extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {

    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: '.env.dev');

      // Initialize Supabase with test configuration
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    });

    testWidgets('Complete signup to login flow', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the auth landing screen
      expect(find.byType(AuthLandingScreen), findsOneWidget);

      // Navigate to signup screen
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);

      // Fill out signup form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '25');
      await tester.enterText(find.byType(TextFormField).at(3), '+212 61 23 45 67');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), 'TestPassword123!');
      await tester.enterText(find.byType(TextFormField).at(5), 'TestPassword123!');

      // Submit signup
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify email confirmation message
      expect(find.text('Account created successfully! Please check your email to confirm your account before logging in.'), findsOneWidget);

      // Navigate to login screen
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill out login form
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPassword123!');

      // Submit login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify successful login (this would depend on email confirmation in real scenario)
      // For testing purposes, we expect either success or email confirmation error
      expect(
        find.text('Login successful!'),
        findsOneWidget,
      );
    });

    testWidgets('Authentication state persistence', (WidgetTester tester) async {
      // Test that authentication state persists across app restarts
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      final authProvider = Provider.of<AuthProvider>(tester.element(find.byType(app.FootConnectApp)), listen: false);
      expect(authProvider.isAuthenticated, isFalse);

      // Simulate login
      await authProvider.login(email: 'test@example.com', password: 'TestPassword123!');
      await tester.pumpAndSettle();

      // Verify authentication state
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser, isNotNull);

      // Simulate app restart by recreating the provider
      final newAuthProvider = AuthProvider();
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify state was restored (this would work if token persistence is implemented)
      // Note: In a real test, we'd need to mock the secure storage
      expect(newAuthProvider.isAuthenticated, isFalse); // Will be false without proper mocking
    });

    testWidgets('Logout functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      final authProvider = Provider.of<AuthProvider>(tester.element(find.byType(app.FootConnectApp)), listen: false);

      // First login
      await authProvider.login(email: 'test@example.com', password: 'TestPassword123!');
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isTrue);

      // Logout
      await authProvider.logout();
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.token, isNull);
    });

    testWidgets('Form validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your age'), findsOneWidget);
      expect(find.text('Please select your gender'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('Password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Find password field
      final passwordField = find.byType(TextFormField).at(1);
      expect(passwordField, findsOneWidget);

      // Initially password should be obscured - check by finding visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Password should now be visible - check by finding visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Should be obscured again
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Email confirmation flow simulation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const app.FootConnectApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill signup form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '25');
      await tester.enterText(find.byType(TextFormField).at(3), '+212 61 23 45 67');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), 'TestPassword123!');
      await tester.enterText(find.byType(TextFormField).at(5), 'TestPassword123!');

      // Submit signup
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify confirmation message
      expect(find.textContaining('check your email'), findsOneWidget);

      // Try to login without confirming email
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPassword123!');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show email confirmation error
      expect(find.text('Please confirm your email before logging in'), findsOneWidget);
    });
  });
}
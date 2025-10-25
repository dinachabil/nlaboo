import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/services/api_service.dart';
import 'package:nlaabo/models/user.dart' as app_user;

// Create a test user factory function
app_user.User createTestUser({
  required String id,
  required String name,
  required String email,
  String role = 'player',
  DateTime? createdAt,
}) {
  return app_user.User(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt ?? DateTime.now(),
  );
}

// Mock classes
class MockApiService extends Mock implements ApiService {}

void main() {
  group('AuthProvider Unit Tests', () {
    late AuthProvider authProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();

      // Create auth provider with mocked dependencies
      authProvider = AuthProvider();
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('Initial state should be unauthenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.token, null);
      expect(authProvider.isLoading, false);
    });

    test('Signup with valid data should return true for confirmed accounts', () async {
      // Arrange
      final testUser = createTestUser(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'player',
      );

      when(mockApiService.signup(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        age: 25,
        phone: '+212 61 23 45 67',
        gender: 'male',
        role: 'player',
      )).thenAnswer((_) async => {
        'user': testUser.toJson(),
        'session': {'access_token': 'test-token'},
        'message': 'Account created successfully',
      });

      // Act
      final result = await authProvider.signup(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        age: 25,
        phone: '+212 61 23 45 67',
        gender: 'male',
        role: 'player',
      );

      // Assert
      expect(result, true);
      expect(authProvider.currentUser?.email, 'test@example.com');
      expect(authProvider.token, 'test-token');
    });

    test('Signup requiring email confirmation should return false', () async {
      // Arrange
      final testUser = app_user.User(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      when(mockApiService.signup(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        age: 25,
        phone: '+212 61 23 45 67',
        gender: 'male',
        role: 'player',
      )).thenAnswer((_) async => {
        'user': testUser.toJson(),
        'session': null, // No session means email confirmation required
        'message': 'Account created successfully. Please check your email.',
      });

      // Act
      final result = await authProvider.signup(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        age: 25,
        phone: '+212 61 23 45 67',
        gender: 'male',
        role: 'player',
      );

      // Assert
      expect(result, false);
      expect(authProvider.currentUser?.email, 'test@example.com');
      expect(authProvider.token, null); // No token without confirmation
    });

    test('Login with valid credentials should succeed', () async {
      // Arrange
      final testUser = app_user.User(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      when(mockApiService.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      )).thenAnswer((_) async => {
        'user': testUser.toJson(),
        'session': {'access_token': 'test-token'},
        'message': 'Login successful',
      });

      // Act
      await authProvider.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      // Assert
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser?.email, 'test@example.com');
      expect(authProvider.token, 'test-token');
    });

    test('Login with invalid credentials should throw error', () async {
      // Arrange
      when(mockApiService.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid email or password'));

      // Act & Assert
      expect(
        () => authProvider.login(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
        throwsException,
      );
    });

    test('Logout should clear authentication state', () async {
      // Arrange - set up authenticated state
      final testUser = app_user.User(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      when(mockApiService.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      )).thenAnswer((_) async => {
        'user': testUser.toJson(),
        'session': {'access_token': 'test-token'},
        'message': 'Login successful',
      });

      await authProvider.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      expect(authProvider.isAuthenticated, true);

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.token, null);
    });

    test('Admin role detection should work correctly', () async {
      // Arrange
      final adminUser = app_user.User(
        id: 'admin-id',
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
        createdAt: DateTime.now(),
      );

      final regularUser = app_user.User(
        id: 'user-id',
        name: 'Regular User',
        email: 'user@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      // Test admin user
      when(mockApiService.login(
        email: 'admin@example.com',
        password: 'TestPassword123!',
      )).thenAnswer((_) async => {
        'user': adminUser.toJson(),
        'session': {'access_token': 'admin-token'},
        'message': 'Login successful',
      });

      await authProvider.login(
        email: 'admin@example.com',
        password: 'TestPassword123!',
      );

      expect(authProvider.isAdmin, true);

      // Logout and test regular user
      await authProvider.logout();

      when(mockApiService.login(
        email: 'user@example.com',
        password: 'TestPassword123!',
      )).thenAnswer((_) async => {
        'user': regularUser.toJson(),
        'session': {'access_token': 'user-token'},
        'message': 'Login successful',
      });

      await authProvider.login(
        email: 'user@example.com',
        password: 'TestPassword123!',
      );

      expect(authProvider.isAdmin, false);
    });

    test('Profile update should update current user', () async {
      // Arrange - set up authenticated state
      final originalUser = app_user.User(
        id: 'test-id',
        name: 'Original Name',
        email: 'test@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      final updatedUser = app_user.User(
        id: 'test-id',
        name: 'Updated Name',
        email: 'test@example.com',
        role: 'player',
        createdAt: DateTime.now(),
      );

      when(mockApiService.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      )).thenAnswer((_) async => {
        'user': originalUser.toJson(),
        'session': {'access_token': 'test-token'},
        'message': 'Login successful',
      });

      await authProvider.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      when(mockApiService.updateProfile(name: 'Updated Name'))
          .thenAnswer((_) async => Future.value(updatedUser));

      // Act
      await authProvider.updateProfile(name: 'Updated Name');

      // Assert
      expect(authProvider.currentUser?.name, 'Updated Name');
    });
  });
}
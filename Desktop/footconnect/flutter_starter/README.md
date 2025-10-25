# Flutter Starter Project

A complete Flutter starter project with authentication, routing, dark mode, and multi-language support.

## Features

- ✅ **Authentication System**: Login, signup, logout with state management
- ✅ **GoRouter Navigation**: Protected routes with authentication guards
- ✅ **Dark Mode**: System/light/dark theme support
- ✅ **Multi-language**: English, French, and Arabic support using ARB files
- ✅ **State Management**: Provider pattern for app state
- ✅ **Responsive UI**: Material Design 3 with proper localization

## Project Structure

```
lib/
├── main.dart                 # App entry point with localization setup
├── app_router.dart           # GoRouter configuration with auth guards
├── providers/
│   └── auth_provider.dart    # Authentication state management
├── screens/
│   ├── home_screen.dart      # Public home screen with navigation buttons
│   ├── login_screen.dart     # Login form with validation
│   ├── signup_screen.dart    # Signup form with validation
│   ├── profile_screen.dart   # Protected profile screen (requires login)
│   └── admin_screen.dart     # Protected admin screen (requires admin role)
└── l10n/                     # Localization files
    ├── app_localizations.dart # Generated localization class
    ├── app_en.arb           # English translations
    ├── app_fr.arb           # French translations
    └── app_ar.arb           # Arabic translations
```

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate Localization Files**:
   ```bash
   flutter gen-l10n
   ```

3. **Run the App**:
   ```bash
   flutter run -d web-server --web-port=8080
   ```

4. **Open in Browser**:
   Navigate to `http://localhost:8080`

## Authentication Flow

- **Unauthenticated users** are redirected to `/login`
- **Authenticated users** can access `/profile`
- **Admin users** (role: 'admin') can access `/admin`
- **Login with email containing 'admin'** to get admin role

## Localization

The app supports three languages:
- **English** (en)
- **French** (fr)
- **Arabic** (ar) - Right-to-left layout

Language preference is saved using SharedPreferences.

## Dependencies

- `go_router`: Declarative routing
- `provider`: State management
- `shared_preferences`: Local storage
- `flutter_localizations`: Built-in localization support
- `intl`: Internationalization

## Usage Examples

### Navigation
```dart
// Navigate to login
context.go('/login');

// Navigate to profile (protected)
context.go('/profile');
```

### Authentication
```dart
final authProvider = Provider.of<AuthProvider>(context);

// Login
await authProvider.login(email, password);

// Check authentication
if (authProvider.isAuthenticated) {
  // User is logged in
}

// Logout
authProvider.logout();
```

### Localization
```dart
final l10n = AppLocalizations.of(context)!;

// Use localized strings
Text(l10n.welcome);
Text(l10n.welcomeUser(user.email));
```

## Testing

Run tests:
```bash
flutter test
```

## Building for Production

```bash
flutter build web
```

## Notes

- Mock authentication (no real backend)
- Email containing 'admin' gets admin role
- Language preference persists across app restarts
- Theme follows system preference by default

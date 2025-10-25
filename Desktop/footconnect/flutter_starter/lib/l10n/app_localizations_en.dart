// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get admin => 'Admin';

  @override
  String welcomeUser(Object email) {
    return 'Welcome $email';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get arabic => 'Arabic';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get goToSignup => 'Go to Signup';

  @override
  String get goToProfile => 'Go to Profile';

  @override
  String get goToAdmin => 'Go to Admin';

  @override
  String get adminOnly => 'Admin Only Access';
}

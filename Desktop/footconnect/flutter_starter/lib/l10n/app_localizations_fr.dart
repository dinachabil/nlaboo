// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcome => 'Bienvenue';

  @override
  String get login => 'Connexion';

  @override
  String get signup => 'S\'inscrire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get home => 'Accueil';

  @override
  String get profile => 'Profil';

  @override
  String get admin => 'Admin';

  @override
  String welcomeUser(Object email) {
    return 'Bienvenue $email';
  }

  @override
  String get loading => 'Chargement...';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'Arabe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get goToLogin => 'Aller à la connexion';

  @override
  String get goToSignup => 'Aller à l\'inscription';

  @override
  String get goToProfile => 'Aller au profil';

  @override
  String get goToAdmin => 'Aller à l\'admin';

  @override
  String get adminOnly => 'Accès administrateur uniquement';
}

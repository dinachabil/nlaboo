import '../services/localization_service.dart';

/// Shared synchronous form validators used across screens.
/// Each validator returns a localized error string via LocalizationService.tr(key)
/// or null when the value is valid.

final RegExp _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
final RegExp _numericRegExp = RegExp(r'^\d+$');

/// Validate email: non-empty + valid email regex.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('email_required');
  }
  if (!_emailRegExp.hasMatch(value.trim())) {
    return LocalizationService.tr('invalid_email');
  }
  return null;
}

/// Validate password: non-empty + minimum length 8.
/// Returns an error string when invalid, otherwise null.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return LocalizationService.tr('password_required');
  }
  if (value.length < 8) {
    // New key added for 8-char minimum
    return LocalizationService.tr('password_too_short_8');
  }
  return null;
}

/// Validate confirm password matches [password].
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return LocalizationService.tr('password_required');
  }
  if (value != password) {
    return LocalizationService.tr('passwords_not_match');
  }
  return null;
}

/// Validate full name: non-empty, min length 2.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('name_required');
  }
  if (value.trim().length < 2) {
    return LocalizationService.tr('name_too_short');
  }
  return null;
}

/// Validate optional phone: if present must be numeric and length between 7 and 15.
String? validatePhoneOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final v = value.trim();
  if (!_numericRegExp.hasMatch(v)) return LocalizationService.tr('phone_invalid');
  if (v.length < 7 || v.length > 15) return LocalizationService.tr('phone_invalid');
  return null;
}

/// Validate age: required, numeric and within sensible range (13-100).
String? validateAge(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('age_required');
  }
  final age = int.tryParse(value.trim());
  if (age == null || age < 13 || age > 100) {
    return LocalizationService.tr('age_invalid');
  }
  return null;
}

/// Validate location: non-empty.
String? validateLocation(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('location_required');
  }
  return null;
}

/// Validate match title: non-empty and reasonable length (>=3).
String? validateMatchTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('match_title_required');
  }
  if (value.trim().length < 3) {
    return LocalizationService.tr('match_title_too_short');
  }
  return null;
}

/// Validate total players / maxPlayers: must be > 0.
String? validateTotalPlayers(int? value) {
  if (value == null || value <= 0) {
    return LocalizationService.tr('total_players_required');
  }
  return null;
}

/// Validate team name: non-empty and min length 2.
String? validateTeamName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('team_name_required');
  }
  if (value.trim().length < 2) {
    return LocalizationService.tr('team_name_too_short');
  }
  return null;
}

/// Validate match date/time is in the future.
String? validateMatchDateTime(DateTime matchDateTime) {
  if (matchDateTime.isBefore(DateTime.now())) {
    return LocalizationService.tr('match_date_time_future');
  }
  return null;
}
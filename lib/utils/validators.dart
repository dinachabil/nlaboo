import '../services/localization_service.dart';
import 'package:logger/logger.dart';

/// Shared synchronous form validators used across screens.
/// Each validator returns a localized error string via LocalizationService.tr(key)
/// or null when the value is valid.

final RegExp _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
final Logger _logger = Logger();

/// Validate email: non-empty + valid email regex with stricter validation.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('email_required');
  }

  final email = value.trim().toLowerCase();

  // Check basic format
  if (!_emailRegExp.hasMatch(email)) {
    return LocalizationService.tr('invalid_email');
  }

  // Additional validation for common issues
  if (email.startsWith('.') ||
      email.startsWith('@') ||
      email.endsWith('.') ||
      email.endsWith('@')) {
    return LocalizationService.tr('invalid_email');
  }

  // Check for consecutive dots
  if (email.contains('..')) {
    return LocalizationService.tr('invalid_email');
  }

  // Check for valid domain (at least one dot after @)
  final atIndex = email.indexOf('@');
  if (atIndex == -1 || !email.substring(atIndex).contains('.')) {
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

/// Validate full name: required, min length 2, must contain at least one letter.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService.tr('name_required');
  }

  final name = value.trim();

  if (name.length < 2) {
    return LocalizationService.tr('name_too_short');
  }

  // Check if name contains at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(name)) {
    return LocalizationService.tr('name_must_contain_letter');
  }

  // Check for placeholder/invalid names
  final lowerName = name.toLowerCase();
  if (lowerName.contains('development') ||
      lowerName.contains('test') ||
      lowerName.contains('user') ||
      lowerName.contains('admin') ||
      lowerName.contains('placeholder') ||
      lowerName.length < 3) {
    return LocalizationService.tr('name_invalid_placeholder');
  }

  return null;
}

/// Validate optional phone: if present must contain at least 7 digits after removing non-digit characters.
/// Supports international phone numbers (7-25 digits) to accommodate various formats.
/// Only allows digits, spaces, +, -, (, ) in the input.
String? validatePhoneOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final trimmed = value.trim();

  // Check for invalid characters - only allow digits, spaces, +, -, (, )
  if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed)) {
    _logger.w('Phone validation failed - contains invalid characters');
    return LocalizationService.tr('phone_invalid');
  }

  final cleaned = trimmed.replaceAll(RegExp(r'\D'), '');
  _logger.d(
    'Phone validation - input: "$value", cleaned: "$cleaned", length: ${cleaned.length}',
  );

  if (cleaned.length < 7 || cleaned.length > 25) {
    _logger.w(
      'Phone validation failed - length ${cleaned.length} not between 7-25 digits',
    );
    return LocalizationService.tr('phone_invalid');
  }

  // Allow international numbers that may start with 0 (like Moroccan numbers: 0612345678)
  // Only reject if the number is suspiciously short and starts with 0
  if (cleaned.length < 7 && cleaned.startsWith('0')) {
    _logger.w('Phone validation failed - suspiciously short number starting with 0');
    return LocalizationService.tr('phone_invalid');
  }

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

/// Validate age: optional, numeric and within sensible range (13-100) if provided.
String? validateAgeOptional(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Allow empty
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

/// Validate max players: must be > 0.
String? validateMaxPlayers(int? value) {
  if (value == null || value <= 0) {
    return LocalizationService.tr('max_players_required');
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

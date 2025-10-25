import 'dart:convert';
import 'package:flutter/services.dart';

/// Enhanced LocalizationService with robust error handling and fallback mechanisms
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, String> _localizedStrings = {};
  String _currentLanguage = 'en';

  // Supported languages with their base language mappings
  static const Map<String, String> _languageVariants = {
    'en-GB': 'en',
    'en-US': 'en',
    'fr-CA': 'fr',
    'fr-FR': 'fr',
    'ar-SA': 'ar',
    'ar-AE': 'ar',
  };

  String get currentLanguage => _currentLanguage;

  /// Validates if a JSON string is valid and contains expected structure
  bool _isValidJson(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      return decoded is Map<String, dynamic> &&
             decoded.isNotEmpty &&
             decoded.values.every((value) => value != null);
    } catch (e) {
      return false;
    }
  }

  /// Extracts base language from language variant (e.g., 'fr-CA' -> 'fr')
  String _getBaseLanguage(String languageCode) {
    return _languageVariants[languageCode] ?? languageCode.split('-').first;
  }

  /// Attempts to load a translation file with validation
  Future<Map<String, String>?> _loadTranslationFile(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );

      if (!_isValidJson(jsonString)) {
        return null;
      }

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return null;
    }
  }

  /// Loads language with robust fallback chain: specific → base → English → key name
  Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;

    // Step 1: Try to load the specific language variant (e.g., 'fr-CA')
    Map<String, String>? translations = await _loadTranslationFile(languageCode);

    // Step 2: If specific variant failed, try base language (e.g., 'fr')
    if (translations == null && languageCode.contains('-')) {
      final baseLanguage = _getBaseLanguage(languageCode);
      if (baseLanguage != languageCode) {
        translations = await _loadTranslationFile(baseLanguage);
        if (translations != null) {
          _currentLanguage = baseLanguage;
        }
      }
    }

    // Step 3: If base language failed, try English as ultimate fallback
    if (translations == null && languageCode != 'en') {
      translations = await _loadTranslationFile('en');
      if (translations != null) {
        _currentLanguage = 'en';
      }
    }

    // Step 4: If all loading attempts failed, use empty map (graceful degradation)
    if (translations == null) {
      _localizedStrings = <String, String>{};
    } else {
      _localizedStrings = translations;
    }
  }

  /// Translates a key with fallback to key name if translation not found
  String translate(String key) {
    if (key.isEmpty) return key;
    return _localizedStrings[key] ?? key;
  }

  /// Checks if a translation key exists in current translations
  bool hasKey(String key) {
    return _localizedStrings.containsKey(key);
  }

  /// Gets all available translation keys
  Set<String> get availableKeys => _localizedStrings.keys.toSet();

  /// Helper method for easier access
  static String tr(String key) {
    return LocalizationService().translate(key);
  }

  /// Get text direction for RTL languages
  TextDirection get textDirection {
    return _currentLanguage.startsWith('ar') ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Check if current language is RTL
  bool get isRTL => _currentLanguage.startsWith('ar');

  /// Get the base language code (without variant)
  String get baseLanguage => _getBaseLanguage(_currentLanguage);

  /// Check if current language is a variant
  bool get isLanguageVariant => _currentLanguage.contains('-');

  /// Get supported language variants
  static Map<String, String> get supportedVariants => Map.unmodifiable(_languageVariants);
}

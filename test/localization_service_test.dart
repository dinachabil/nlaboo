import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlaabo/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService', () {
    late LocalizationService service;

    setUp(() {
      service = LocalizationService();
    });

    test('should be a singleton', () {
      final service1 = LocalizationService();
      final service2 = LocalizationService();
      expect(identical(service1, service2), true);
    });

    test('should load English translations successfully', () async {
      await service.loadLanguage('en');
      expect(service.currentLanguage, 'en');
      expect(service.translate('app_title'), 'nlaabo');
      expect(service.translate('welcome'), 'Welcome');
    });

    test('should load French translations successfully', () async {
      await service.loadLanguage('fr');
      expect(service.currentLanguage, 'fr');
      expect(service.translate('welcome'), 'Bienvenue'); // Should be translated
    });

    test('should load Arabic translations successfully', () async {
      await service.loadLanguage('ar');
      expect(service.currentLanguage, 'ar');
      expect(service.translate('welcome'), 'مرحباً'); // Should be translated
      expect(service.isRTL, true);
      expect(service.textDirection, TextDirection.rtl);
    });

    test('should fallback to English for unknown language', () async {
      await service.loadLanguage('unknown');
      expect(service.currentLanguage, 'en');
      expect(service.translate('app_title'), 'nlaabo');
    });

    test('should handle language variants correctly', () async {
      // Test fr-CA -> fr fallback
      await service.loadLanguage('fr-CA');
      expect(service.currentLanguage, 'fr');
      expect(service.baseLanguage, 'fr');
      expect(service.isLanguageVariant, true);

      // Test en-GB -> en fallback
      await service.loadLanguage('en-GB');
      expect(service.currentLanguage, 'en');
      expect(service.baseLanguage, 'en');
      expect(service.isLanguageVariant, true);
    });

    test('should check key existence', () async {
      await service.loadLanguage('en');
      expect(service.hasKey('app_title'), true);
      expect(service.hasKey('nonexistent_key'), false);
    });

    test('should return key name when translation not found', () async {
      await service.loadLanguage('en');
      expect(service.translate('nonexistent_key'), 'nonexistent_key');
    });

    test('should handle empty key', () async {
      await service.loadLanguage('en');
      expect(service.translate(''), '');
    });

    test('should provide available keys', () async {
      await service.loadLanguage('en');
      final keys = service.availableKeys;
      expect(keys, isNotEmpty);
      expect(keys.contains('app_title'), true);
    });

    test('should handle RTL detection correctly', () async {
      await service.loadLanguage('en');
      expect(service.isRTL, false);
      expect(service.textDirection, TextDirection.ltr);

      await service.loadLanguage('ar');
      expect(service.isRTL, true);
      expect(service.textDirection, TextDirection.rtl);

      await service.loadLanguage('ar-SA'); // Variant should still be RTL
      expect(service.isRTL, true);
      expect(service.textDirection, TextDirection.rtl);
    });

    test('should provide supported variants', () {
      final variants = LocalizationService.supportedVariants;
      expect(variants, isNotEmpty);
      expect(variants.containsKey('fr-CA'), true);
      expect(variants['fr-CA'], 'fr');
    });
  });
}
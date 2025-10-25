import 'package:flutter_test/flutter_test.dart';
import 'package:nlaabo/services/phone_service.dart';

void main() {
  setUp(() async {
    // Initialize the phone service
    await PhoneService.initialize();
    // Clear caches before each test
    PhoneService.clearAllCaches();
  });

  tearDown(() {
    // Clean up after each test
    PhoneService.clearAllCaches();
  });

  group('PhoneService Validation', () {
    test('validatePhoneNumber - valid Moroccan mobile number', () async {
      final result = await PhoneService.validatePhoneNumber('+212 6 41 17 00 12');
      expect(result, isNull); // null means valid
    });

    test('validatePhoneNumber - valid Moroccan number without formatting', () async {
      final result = await PhoneService.validatePhoneNumber('0641170012');
      expect(result, isNull); // null means valid
    });

    test('validatePhoneNumber - invalid empty string', () async {
      final result = await PhoneService.validatePhoneNumber('');
      expect(result, isNotNull); // not null means error message
    });

    test('validatePhoneNumber - invalid null input', () async {
      final result = await PhoneService.validatePhoneNumber(null);
      expect(result, isNotNull); // not null means error message
    });

    test('validateMoroccanPhone - valid Moroccan number', () async {
      final result = await PhoneService.validateMoroccanPhone('+212641170012');
      expect(result, isNull); // null means valid
    });
  });

  group('PhoneService Formatting', () {
    test('formatPhoneNumber - formats Moroccan number', () async {
      final result = await PhoneService.formatPhoneNumber('0641170012', countryCode: 'MA');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
    });

    test('normalizePhoneNumber - normalizes to international format', () async {
      final result = await PhoneService.normalizePhoneNumber('0641170012', countryCode: 'MA');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
    });

    test('formatMoroccanPhone - formats Moroccan number', () async {
      final result = await PhoneService.formatMoroccanPhone('0641170012');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
    });

    test('normalizeMoroccanPhone - normalizes Moroccan number', () async {
      final result = await PhoneService.normalizeMoroccanPhone('0641170012');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
    });
  });

  group('PhoneService Parsing', () {
    test('parsePhoneNumber - parses valid number', () async {
      final result = await PhoneService.parsePhoneNumber('+212641170012');
      expect(result, isNotNull);
      expect(result!.phoneNumber, isNotNull);
    });

    test('getCountryInfo - detects country from number', () async {
      final result = await PhoneService.getCountryInfo('+212641170012');
      expect(result, isNotNull);
      expect(result!.isoCode, equals('MA'));
    });
  });

  group('PhoneService Utility Methods', () {
    test('isValidForCountry - validates for specific country', () async {
      final result = await PhoneService.isValidForCountry('+212641170012', 'MA');
      expect(result, isTrue);
    });

    test('formatAsYouType - formats input progressively', () async {
      final result = await PhoneService.formatAsYouType('0641170012');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
    });

    test('getSupportedRegions - returns list of regions', () async {
      final result = await PhoneService.getSupportedRegions();
      expect(result, isNotNull);
      expect(result!.isNotEmpty, true);
      expect(result!.contains('MA'), true);
    });
  });

  group('PhoneService Caching', () {
    test('validatePhoneNumber - caches validation results', () async {
      final phoneNumber = '+212641170012';

      // First call should perform validation
      final result1 = await PhoneService.validatePhoneNumber(phoneNumber);
      expect(result1, isNull);

      // Second call should use cache
      final result2 = await PhoneService.validatePhoneNumber(phoneNumber);
      expect(result2, isNull);

      // Check that cache contains the entry
      final stats = PhoneService.getCacheStats();
      expect(stats['validation_cache_size'], greaterThan(0));
    });

    test('formatPhoneNumber - caches format results', () async {
      final phoneNumber = '0641170012';

      // First call
      final result1 = await PhoneService.formatPhoneNumber(phoneNumber);
      expect(result1, isNotNull);

      // Second call should use cache
      final result2 = await PhoneService.formatPhoneNumber(phoneNumber);
      expect(result2, equals(result1));

      // Check cache stats
      final stats = PhoneService.getCacheStats();
      expect(stats['format_cache_size'], greaterThan(0));
    });

    test('parsePhoneNumber - caches parse results', () async {
      final phoneNumber = '+212641170012';

      // First call
      final result1 = await PhoneService.parsePhoneNumber(phoneNumber);
      expect(result1, isNotNull);

      // Second call should use cache
      final result2 = await PhoneService.parsePhoneNumber(phoneNumber);
      expect(result2, equals(result1));

      // Check cache stats
      final stats = PhoneService.getCacheStats();
      expect(stats['parse_cache_size'], greaterThan(0));
    });

    test('clearAllCaches - clears all cache entries', () async {
      // Perform some operations to populate caches
      await PhoneService.validatePhoneNumber('+212641170012');
      await PhoneService.formatPhoneNumber('0641170012');
      await PhoneService.parsePhoneNumber('+212641170012');

      // Verify caches are populated
      var stats = PhoneService.getCacheStats();
      expect(stats['validation_cache_size'], greaterThan(0));
      expect(stats['format_cache_size'], greaterThan(0));
      expect(stats['parse_cache_size'], greaterThan(0));

      // Clear all caches
      PhoneService.clearAllCaches();

      // Verify caches are empty
      stats = PhoneService.getCacheStats();
      expect(stats['validation_cache_size'], equals(0));
      expect(stats['format_cache_size'], equals(0));
      expect(stats['parse_cache_size'], equals(0));
    });

    test('cleanupExpiredCache - removes expired entries', () async {
      // This test would need to manipulate time or use a mock timer
      // For now, just verify the method exists and doesn't throw
      expect(() => PhoneService.cleanupExpiredCache(), returnsNormally);
    });
  });

  group('PhoneService Security Features', () {
    test('input sanitization - removes malicious characters', () async {
      // Test with potentially malicious input
      final maliciousInputs = [
        '<script>alert("xss")</script>+212641170012',
        'javascript:alert("xss");+212641170012',
        'onload=alert("xss");+212641170012',
        '+212641170012<style>body{background:red}</style>',
      ];

      for (final input in maliciousInputs) {
        final result = await PhoneService.validatePhoneNumber(input);
        // Should either validate as invalid or sanitize successfully
        expect(result, isNotNull); // Should be flagged as invalid due to sanitization
      }
    });

    test('input sanitization - allows valid phone characters', () async {
      final validInputs = [
        '+212 6 41 17 00 12',
        '+1 (555) 123-4567',
        '+44 20 7123 4567',
        '0641170012',
      ];

      for (final input in validInputs) {
        final result = await PhoneService.validatePhoneNumber(input);
        // Should validate successfully (null means valid)
        expect(result, isNull);
      }
    });

    test('rate limiting - allows normal usage', () async {
      const clientId = 'test-client';

      // Make several requests within limits
      for (int i = 0; i < 10; i++) {
        final result = await PhoneService.validatePhoneNumber(
          '+212641170012',
          clientId: clientId,
        );
        expect(result, isNull); // Should validate successfully
      }
    });

    test('rate limiting - blocks excessive requests', () async {
      const clientId = 'test-client-rate-limited';

      // Make excessive requests to trigger rate limiting
      for (int i = 0; i < 120; i++) {
        await PhoneService.validatePhoneNumber(
          '+212641170012',
          clientId: clientId,
        );
      }

      // Next request should be rate limited
      final result = await PhoneService.validatePhoneNumber(
        '+212641170012',
        clientId: clientId,
      );
      expect(result, isNotNull); // Should be rate limited
    });

    test('secure storage - normalizes for storage', () async {
      final result = await PhoneService.normalizePhoneNumber(
        '+212 6 41 17 00 12',
        encryptForStorage: false,
      );
      expect(result, isNotNull);
      expect(result!.startsWith('+'), true); // Should be in E.164 format
    });

    test('secure storage - hashes for encrypted storage', () async {
      final result = await PhoneService.normalizePhoneNumber(
        '+212 6 41 17 00 12',
        encryptForStorage: true,
      );
      expect(result, isNotNull);
      expect(result!.length, 64); // SHA-256 hash length
      expect(result, matches(r'^[a-f0-9]+$')); // Should be hexadecimal
    });

    test('secure storage - sanitizes input before hashing', () async {
      final maliciousInput = '<script>+212641170012</script>';
      final result = await PhoneService.normalizePhoneNumber(
        maliciousInput,
        encryptForStorage: true,
      );
      expect(result, isNull); // Should fail sanitization
    });
  });

  group('PhoneService Debounced Validation', () {
    test('debouncedValidate - delays validation execution', () async {
      bool callbackCalled = false;
      String? callbackResult;

      PhoneService.debouncedValidate(
        '+212641170012',
        'MA',
        (result) {
          callbackCalled = true;
          callbackResult = result;
        },
      );

      // Should not be called immediately
      expect(callbackCalled, isFalse);

      // Wait for debounce duration
      await Future.delayed(const Duration(milliseconds: 350));

      // Should be called after debounce
      expect(callbackCalled, isTrue);
      expect(callbackResult, isNull); // Valid number
    });

    test('cancelDebouncedValidation - cancels pending validation', () async {
      bool callbackCalled = false;

      PhoneService.debouncedValidate(
        '+212641170012',
        'MA',
        (result) {
          callbackCalled = true;
        },
      );

      // Cancel immediately
      PhoneService.cancelDebouncedValidation();

      // Wait for debounce duration
      await Future.delayed(const Duration(milliseconds: 350));

      // Should not be called due to cancellation
      expect(callbackCalled, isFalse);
    });
  });
}
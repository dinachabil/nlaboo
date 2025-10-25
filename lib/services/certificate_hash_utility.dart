import 'secure_http_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CertificateHashUtility');

/// Utility class to help obtain certificate hashes for pinning
class CertificateHashUtility {
  /// Get certificate hash for a Supabase project
  /// Usage: Call this method during development to obtain the correct hash
  /// Example: CertificateHashUtility.getSupabaseCertificateHash('your-project.supabase.co')
  static Future<String> getSupabaseCertificateHash(String projectDomain) async {
    try {
      final hash = await SecureHttpClient.getCertificateHash(
        projectDomain,
        443,
      );
      _logger.info('Certificate hash for $projectDomain: $hash');
      _logger.info('Add this hash to certificate_pinning_config.dart');
      return hash;
    } catch (e) {
      _logger.info('Error getting certificate hash: $e');
      rethrow;
    }
  }

  /// Batch get hashes for multiple domains
  static Future<Map<String, String>> getMultipleCertificateHashes(
    List<String> domains,
  ) async {
    final results = <String, String>{};

    for (final domain in domains) {
      try {
        final hash = await getSupabaseCertificateHash(domain);
        results[domain] = hash;
      } catch (e) {
        _logger.info('Failed to get hash for $domain: $e');
        results[domain] = 'ERROR: $e';
      }
    }

    return results;
  }

  /// Instructions for developers
  static const String setupInstructions = '''
CERTIFICATE PINNING SETUP INSTRUCTIONS:

1. During development, temporarily disable certificate pinning by commenting out
   the pinned hashes in certificate_pinning_config.dart

2. Run the app and call getSupabaseCertificateHash() for your Supabase domains:
   - For production: your-project.supabase.co
   - For staging: your-staging-project.supabase.co

3. Copy the printed hashes and update certificate_pinning_config.dart

4. Re-enable certificate pinning

5. Test that the app works with the pinned certificates

6. For production deployment, ensure all environment configurations have correct hashes

EXAMPLE USAGE IN DEVELOPMENT:

```dart
// In a debug/test function or during app initialization
await CertificateHashUtility.getSupabaseCertificateHash('your-project.supabase.co');
```

This will print the hash to console. Copy it to your configuration.
''';
}

/// Configuration for certificate pinning
class CertificatePinningConfig {
  /// Supabase certificate hashes for different environments
  static const Map<String, List<String>> supabaseCertificateHashes = {
    'production': [
      // Replace these with actual Supabase production certificate hashes
      // Obtain these by running the getCertificateHash utility method
      'sha256//TODO: Replace with actual production Supabase certificate hash',
    ],
    'staging': [
      // Replace these with actual Supabase staging certificate hashes
      'sha256//TODO: Replace with actual staging Supabase certificate hash',
    ],
    'development': [
      // For development, you might want to allow all certificates or use test certificates
      // 'sha256//TODO: Replace with actual development Supabase certificate hash',
    ],
  };

  /// Get certificate hashes for current environment
  static List<String> getCertificateHashesForEnvironment(String environment) {
    return supabaseCertificateHashes[environment] ??
        supabaseCertificateHashes['production']!;
  }

  /// Supabase domains that require certificate pinning
  static const List<String> pinnedDomains = [
    'supabase.co',
    'supabase.com',
    '*.supabase.co',
    '*.supabase.com',
  ];

  /// Check if a domain should be pinned
  static bool shouldPinDomain(String host) {
    return pinnedDomains.any((domain) {
      if (domain.startsWith('*.')) {
        final baseDomain = domain.substring(2);
        return host.endsWith(baseDomain);
      }
      return host == domain;
    });
  }

  /// Instructions for obtaining certificate hashes
  static const String certificateHashInstructions = '''
To obtain the correct certificate hash for pinning:

1. Run the app in debug mode with certificate pinning disabled temporarily
2. Use the getCertificateHash utility method from SecureHttpClient
3. Call: SecureHttpClient.getCertificateHash('your-supabase-project.supabase.co', 443)
4. Replace the TODO placeholders in this file with the actual hashes
5. Re-enable certificate pinning

For production, obtain hashes from:
- supabase.co (main domain)
- *.supabase.co (project subdomains)

Example command to get hash manually:
openssl s_client -connect your-project.supabase.co:443 -servername your-project.supabase.co | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256
''';
}

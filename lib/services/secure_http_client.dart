import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'certificate_pinning_config.dart';

/// Secure HTTP client with certificate pinning for Supabase
class SecureHttpClient {
  static http.Client createSecureClient({String environment = 'production'}) {
    final ioClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) =>
          _validateCertificate(cert, host, port, environment);

    return IOClient(ioClient);
  }

  /// Validates SSL certificates against pinned hashes
  static bool _validateCertificate(
    X509Certificate cert,
    String host,
    int port,
    String environment,
  ) {
    // Only apply pinning for configured domains
    if (!CertificatePinningConfig.shouldPinDomain(host)) {
      return true; // Allow other domains without pinning
    }

    try {
      // Get the certificate's public key
      final publicKey = cert.pem;
      final publicKeyBytes = utf8.encode(publicKey);

      // Calculate SHA-256 hash
      final digest = sha256.convert(publicKeyBytes);
      final hash = 'sha256/${base64.encode(digest.bytes)}';

      // Get pinned hashes for current environment
      final pinnedHashes =
          CertificatePinningConfig.getCertificateHashesForEnvironment(
            environment,
          );

      // Check if the hash matches any of our pinned hashes
      final isValid = pinnedHashes.contains(hash);

      if (!isValid) {
        throw CertificatePinningException(
          'Certificate hash mismatch for $host. Expected one of: $pinnedHashes, got: $hash',
          host: host,
        );
      }

      return true;
    } catch (e) {
      if (e is CertificatePinningException) {
        rethrow;
      }
      // If there's any error in validation, reject the certificate
      throw CertificatePinningException(
        'Certificate validation failed for $host: $e',
        host: host,
      );
    }
  }

  /// Utility method to get certificate hash for pinning
  /// This can be used during development to obtain the correct hash
  static Future<String> getCertificateHash(String host, int port) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.https(host, '/'));
      final connection = await request.close();

      // Get the certificate from the connection
      final certificate = connection.certificate;
      if (certificate == null) {
        throw Exception('No certificate found');
      }

      final publicKey = certificate.pem;
      final publicKeyBytes = utf8.encode(publicKey);
      final digest = sha256.convert(publicKeyBytes);

      return 'sha256/${base64.encode(digest.bytes)}';
    } finally {
      client.close();
    }
  }
}

/// Custom exception for certificate pinning failures
class CertificatePinningException implements Exception {
  final String message;
  final String? host;

  CertificatePinningException(this.message, {this.host});

  @override
  String toString() =>
      'CertificatePinningException: $message${host != null ? ' (Host: $host)' : ''}';
}

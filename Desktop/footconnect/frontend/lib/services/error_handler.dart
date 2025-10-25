import 'package:flutter/foundation.dart';
import 'localization_service.dart';
 
class ErrorHandler {
  /// Log errors securely. In release builds hide sensitive details.
  /// Use context to help locate the error source without exposing secrets.
  static void logError(Object e, [StackTrace? st, String? context]) {
    final ctx = context != null ? ' [$context]' : '';
    if (kReleaseMode) {
      // In release mode avoid leaking error details (messages, stack traces).
      debugPrint('Error$ctx: ${e.runtimeType}');
    } else {
      // In debug mode print full details for developers.
      debugPrint('Error$ctx: $e');
      if (st != null) debugPrint(st.toString());
    }
  }
 
  /// Map exceptions to user-friendly localized messages.
  /// Keep mapping simple and conservative to avoid leaking internal info.
  static String userMessage(Object e) {
    final message = e.toString();
    final lower = message.toLowerCase();
 
    // Unauthorized / auth errors
    if (lower.contains('unauthor') || lower.contains('401') || lower.contains('not authenticated')) {
      return LocalizationService.tr('error_unauthorized');
    }

    // Network related
    if (lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('timed out') ||
        lower.contains('timeout')) {
      return LocalizationService.tr('error_network');
    }

    // Upload / storage errors
    if (lower.contains('upload') || lower.contains('storage') || lower.contains('s3') || lower.contains('avatar')) {
      return LocalizationService.tr('error_upload_failed');
    }

    // Validation / invalid input
    if (lower.contains('invalid') || lower.contains('validation') || lower.contains('missing') || lower.contains('required')) {
      return LocalizationService.tr('error_invalid_input');
    }

    // Database / server errors
    if (lower.contains('database') || lower.contains('duplicate') || lower.contains('null value') || lower.contains('pg')) {
      return LocalizationService.tr('error_database');
    }

    // Fallback generic message
    return LocalizationService.tr('error_generic');
  }
}
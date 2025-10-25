import 'package:flutter/foundation.dart';
import 'localization_service.dart';
import 'dart:async';

/// Standardized error types for consistent error handling across the app
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => message;
}

/// Network-related errors (connection, timeout, etc.)
class NetworkError extends AppError {
  NetworkError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'NETWORK_ERROR');
}

/// Authentication and authorization errors
class AuthError extends AppError {
  AuthError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'AUTH_ERROR');
}

/// Validation errors (invalid input, missing fields, etc.)
class ValidationError extends AppError {
  ValidationError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'VALIDATION_ERROR');
}

/// Database and server errors
class DatabaseError extends AppError {
  DatabaseError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'DATABASE_ERROR');
}

/// Upload/storage related errors
class UploadError extends AppError {
  UploadError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'UPLOAD_ERROR');
}

/// Generic application errors
class GenericError extends AppError {
  GenericError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'GENERIC_ERROR');
}

/// Retry configuration for failed operations
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(AppError)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });
}

/// Enhanced error handler with retry logic and standardized error types
class ErrorHandler {
  static const RetryConfig defaultRetryConfig = RetryConfig();

  /// Convert any exception to a standardized AppError
  static AppError standardizeError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('timed out') ||
        errorString.contains('timeout') ||
        errorString.contains('connection refused')) {
      return NetworkError(
        LocalizationService.tr('error_network'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Auth errors
    if (errorString.contains('unauthor') ||
        errorString.contains('401') ||
        errorString.contains('not authenticated') ||
        errorString.contains('invalid token') ||
        errorString.contains('expired token')) {
      return AuthError(
        LocalizationService.tr('error_unauthorized'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Validation errors
    if (errorString.contains('invalid') ||
        errorString.contains('validation') ||
        errorString.contains('missing') ||
        errorString.contains('required') ||
        errorString.contains('bad request') ||
        errorString.contains('400')) {
      return ValidationError(
        LocalizationService.tr('error_invalid_input'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Upload/storage errors
    if (errorString.contains('upload') ||
        errorString.contains('storage') ||
        errorString.contains('s3') ||
        errorString.contains('avatar')) {
      return UploadError(
        LocalizationService.tr('error_upload_failed'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('duplicate') ||
        errorString.contains('null value') ||
        errorString.contains('pg') ||
        errorString.contains('constraint') ||
        errorString.contains('foreign key')) {
      return DatabaseError(
        LocalizationService.tr('error_database'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Show detailed signup errors
    if (errorString.contains('signup failed:')) {
      return ValidationError(
        error.toString(), // Return the full error message for signup failures
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic fallback
    return GenericError(
      LocalizationService.tr('error_generic'),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log errors securely. In release builds hide sensitive details.
  /// Use context to help locate the error source without exposing secrets.
  static void logError(Object e, [StackTrace? st, String? context]) {
    final ctx = context != null ? ' [$context]' : '';
    final standardizedError = standardizeError(e, st);

    // Log errors securely - only log error type and code in production
    // Full details are only available in debug builds for development
    debugPrint(
      'Error$ctx: ${standardizedError.runtimeType} (${standardizedError.code})',
    );
  }

  /// Map exceptions to user-friendly localized messages.
  /// Keep mapping simple and conservative to avoid leaking internal info.
  static String userMessage(Object e) {
    final standardizedError = standardizeError(e);
    return standardizedError.message;
  }

  /// Get recovery suggestions for different error types
  static String? getRecoverySuggestion(AppError error) {
    switch (error) {
      case NetworkError():
        return LocalizationService.tr('error_recovery_network');
      case AuthError():
        return LocalizationService.tr('error_recovery_auth');
      case ValidationError():
        return LocalizationService.tr('error_recovery_validation');
      case UploadError():
        return LocalizationService.tr('error_recovery_upload');
      default:
        return null;
    }
  }

  /// Check if an error is recoverable
  static bool isRecoverable(AppError error) {
    return error is NetworkError || error is GenericError;
  }

  /// Execute an async operation with retry logic
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = defaultRetryConfig,
    String? context,
  }) async {
    int attempts = 0;
    Duration delay = config.initialDelay;

    while (attempts < config.maxAttempts) {
      try {
        return await operation();
      } catch (e, st) {
        attempts++;
        final error = standardizeError(e, st);

        // Log the error attempt
        logError(
          error,
          st,
          '$context (attempt $attempts/${config.maxAttempts})',
        );

        // Check if we should retry
        final shouldRetry =
            config.shouldRetry?.call(error) ??
            (error is NetworkError || error is GenericError);

        if (!shouldRetry || attempts >= config.maxAttempts) {
          rethrow;
        }

        // Add jitter to prevent thundering herd
        final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.1).round());
        final actualDelay = delay + Duration(milliseconds: (jitter.inMilliseconds * (0.5 - (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).round());

        // Wait before retrying
        await Future.delayed(actualDelay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier)
              .round(),
        );

        // Cap the delay
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }
      }
    }

    throw GenericError('Max retry attempts exceeded');
  }

  /// Execute an operation with fallback value on failure
  static Future<T> withFallback<T>(
    Future<T> Function() operation,
    T fallbackValue, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      logError(e, st, context ?? 'withFallback');
      return fallbackValue;
    }
  }

  /// Execute an operation with custom error handling
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? context,
    bool rethrowOnError = true,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      logError(e, st, context);

      if (fallbackValue != null) {
        return fallbackValue;
      }

      if (rethrowOnError) {
        rethrow;
      }

      throw standardizeError(e, st);
    }
  }
}

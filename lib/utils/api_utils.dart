import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/error_handler.dart';

/// Enhanced API response validation and error handling utilities
class ApiResponseValidator {
  /// Validates that a JSON object contains required fields
  static void validateRequiredFields(
    Map<String, dynamic> json,
    List<String> requiredFields,
  ) {
    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        missingFields.add(field);
      }
    }
    if (missingFields.isNotEmpty) {
      throw FormatException(
        'Missing required fields: ${missingFields.join(', ')}',
      );
    }
  }

  /// Validates field types and converts values safely
  static T validateAndConvert<T>(
    dynamic value,
    T Function(dynamic) converter, {
    String? fieldName,
    T? defaultValue,
  }) {
    if (value == null) {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw FormatException('${fieldName ?? 'Field'} cannot be null');
    }

    try {
      return converter(value);
    } catch (e) {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw FormatException('Invalid ${fieldName ?? 'field'} format: $e');
    }
  }

  /// Safely parses DateTime with validation
  static DateTime parseDateTime(
    dynamic value, {
    String? fieldName,
    DateTime? defaultValue,
  }) {
    return validateAndConvert(
      value,
      (v) => DateTime.parse(v.toString()),
      fieldName: fieldName ?? 'date',
      defaultValue: defaultValue,
    );
  }

  /// Safely parses integers with range validation
  static int parseInt(
    dynamic value, {
    String? fieldName,
    int? min,
    int? max,
    int? defaultValue,
  }) {
    final result = validateAndConvert(
      value,
      (v) => int.parse(v.toString()),
      fieldName: fieldName ?? 'integer',
      defaultValue: defaultValue,
    );

    if (min != null && result < min) {
      throw FormatException('${fieldName ?? 'Field'} must be >= $min');
    }
    if (max != null && result > max) {
      throw FormatException('${fieldName ?? 'Field'} must be <= $max');
    }

    return result;
  }

  /// Safely parses doubles with range validation
  static double parseDouble(
    dynamic value, {
    String? fieldName,
    double? min,
    double? max,
    double? defaultValue,
  }) {
    final result = validateAndConvert(
      value,
      (v) => double.parse(v.toString()),
      fieldName: fieldName ?? 'double',
      defaultValue: defaultValue,
    );

    if (min != null && result < min) {
      throw FormatException('${fieldName ?? 'Field'} must be >= $min');
    }
    if (max != null && result > max) {
      throw FormatException('${fieldName ?? 'Field'} must be <= $max');
    }

    return result;
  }

  /// Validates string fields with length constraints
  static String validateString(
    dynamic value, {
    String? fieldName,
    int? minLength,
    int? maxLength,
    String? defaultValue,
  }) {
    final result = validateAndConvert(
      value,
      (v) => v.toString().trim(),
      fieldName: fieldName ?? 'string',
      defaultValue: defaultValue,
    );

    if (minLength != null && result.length < minLength) {
      throw FormatException(
        '${fieldName ?? 'Field'} must be at least $minLength characters',
      );
    }
    if (maxLength != null && result.length > maxLength) {
      throw FormatException(
        '${fieldName ?? 'Field'} must be at most $maxLength characters',
      );
    }

    return result;
  }

  /// Validates enum values
  static T validateEnum<T>(
    dynamic value,
    List<T> validValues, {
    String? fieldName,
    T? defaultValue,
  }) {
    final result = validateAndConvert(
      value,
      (v) => v,
      fieldName: fieldName ?? 'enum',
      defaultValue: defaultValue,
    );

    if (!validValues.contains(result)) {
      throw FormatException(
        '${fieldName ?? 'Field'} must be one of: ${validValues.join(', ')}',
      );
    }

    return result;
  }
}

/// Common API response handler utilities
class ApiUtils {
  /// Handle HTTP response and extract data or throw appropriate error
  static T handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
    List<String>? requiredFields,
  }) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        // Validate required fields if specified
        if (requiredFields != null && requiredFields.isNotEmpty) {
          validateRequiredFields(jsonData, requiredFields);
        }

        return fromJson(jsonData);
      } else {
        // Enhanced error handling with specific status codes
        _handleHttpError(response, context ?? 'ApiUtils.handleResponse');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, context ?? 'ApiUtils.handleResponse');
      rethrow;
    }
  }

  /// Enhanced HTTP error handling
  static Never _handleHttpError(http.Response response, String context) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['detail'] ??
          errorData['message'] ??
          errorData['error'] ??
          'Request failed with status ${response.statusCode}';

      // Map HTTP status codes to appropriate error types
      switch (response.statusCode) {
        case 400:
          throw ValidationError(errorMessage);
        case 401:
          throw AuthError('Authentication required');
        case 403:
          throw AuthError('Access denied');
        case 404:
          throw ValidationError('Resource not found');
        case 409:
          throw ValidationError(errorMessage);
        case 413:
          throw ValidationError('Request too large');
        case 415:
          throw ValidationError('Unsupported media type');
        case 422:
          throw ValidationError('Validation failed: $errorMessage');
        case 429:
          throw GenericError('Too many requests. Please try again later.');
        case 500:
        case 502:
        case 503:
        case 504:
          throw GenericError('Server error. Please try again later.');
        default:
          throw GenericError(errorMessage);
      }
    } catch (parseError) {
      // If we can't parse the error response, use the raw body
      throw GenericError('Request failed: ${response.body}');
    }
  }

  /// Handle HTTP response for list data with enhanced validation
  static List<T> handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
    bool allowEmptyList = true,
  }) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedBody = jsonDecode(response.body);

        // Handle different response formats
        List<dynamic> jsonList;
        if (decodedBody is List) {
          jsonList = decodedBody;
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          // Handle wrapped responses like {data: [...]}
          jsonList = decodedBody['data'] as List<dynamic>;
        } else {
          throw FormatException(
            'Expected list response, got ${decodedBody.runtimeType}',
          );
        }

        if (!allowEmptyList && jsonList.isEmpty) {
          throw ValidationError('Empty list response not allowed');
        }

        // Parse each item with error handling
        final List<T> result = [];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final item = fromJson(jsonList[i] as Map<String, dynamic>);
            result.add(item);
          } catch (e) {
            ErrorHandler.logError(
              e,
              null,
              '${context ?? 'ApiUtils.handleListResponse'} - item $i',
            );
            // Continue processing other items instead of failing completely
            // Silently fail for individual item parsing - not critical for list processing
          }
        }

        return result;
      } else {
        // Enhanced error handling with specific status codes
        _handleHttpError(response, context ?? 'ApiUtils.handleListResponse');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, context ?? 'ApiUtils.handleListResponse');
      rethrow;
    }
  }

  /// Handle HTTP response for simple success/failure with enhanced validation
  static void handleSuccessResponse(
    http.Response response, {
    String? context,
    bool allowEmptyBody = true,
  }) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Validate response body if present
        if (!allowEmptyBody && response.body.isEmpty) {
          throw ValidationError('Empty response body not allowed');
        }

        // Try to validate JSON structure if body is present
        if (response.body.isNotEmpty) {
          try {
            jsonDecode(response.body);
          } catch (e) {
            if (!allowEmptyBody) {
              throw ValidationError('Invalid JSON response: $e');
            }
          }
        }

        return; // Success
      } else {
        // Enhanced error handling with specific status codes
        _handleHttpError(response, context ?? 'ApiUtils.handleSuccessResponse');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, context ?? 'ApiUtils.handleSuccessResponse');
      rethrow;
    }
  }

  /// Create query parameters string from map
  static String createQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';

    final queryParams = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        queryParams.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });

    return queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
  }

  /// Validate required fields in request data
  static void validateRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      throw Exception('Missing required fields: ${missingFields.join(', ')}');
    }
  }
}

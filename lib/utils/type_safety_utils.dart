/// Type safety utilities for enhanced data validation and conversion
class TypeSafetyUtils {
  /// Safely converts dynamic value to String with validation
  static String? safeString(dynamic value, {String? defaultValue}) {
    if (value == null) return defaultValue;
    if (value is String) {
      return value.trim().isEmpty ? defaultValue : value.trim();
    }
    return value.toString().trim().isEmpty
        ? defaultValue
        : value.toString().trim();
  }

  /// Safely converts dynamic value to int with validation
  static int? safeInt(dynamic value, {int? defaultValue, int? min, int? max}) {
    if (value == null) return defaultValue;

    int? result;
    if (value is int) {
      result = value;
    } else if (value is String) {
      result = int.tryParse(value);
    } else if (value is double) {
      result = value.toInt();
    } else if (value is num) {
      result = value.toInt();
    }

    if (result == null) return defaultValue;

    if (min != null && result < min) return defaultValue;
    if (max != null && result > max) return defaultValue;

    return result;
  }

  /// Safely converts dynamic value to double with validation
  static double? safeDouble(
    dynamic value, {
    double? defaultValue,
    double? min,
    double? max,
  }) {
    if (value == null) return defaultValue;

    double? result;
    if (value is double) {
      result = value;
    } else if (value is int) {
      result = value.toDouble();
    } else if (value is String) {
      result = double.tryParse(value);
    } else if (value is num) {
      result = value.toDouble();
    }

    if (result == null) return defaultValue;

    if (min != null && result < min) return defaultValue;
    if (max != null && result > max) return defaultValue;

    return result;
  }

  /// Safely converts dynamic value to bool
  static bool safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// Safely converts dynamic value to DateTime with validation
  static DateTime? safeDateTime(dynamic value, {DateTime? defaultValue}) {
    if (value == null) return defaultValue;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }

    if (value is int) {
      try {
        // Assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  /// Validates that a value is of expected type
  static bool isType<T>(dynamic value) {
    return value is T;
  }

  /// Safely casts a value to expected type with fallback
  static T safeCast<T>(dynamic value, T fallback) {
    return value is T ? value : fallback;
  }

  /// Validates enum values safely
  static T? safeEnum<T>(dynamic value, List<T> validValues, {T? defaultValue}) {
    if (value == null) return defaultValue;

    for (final validValue in validValues) {
      if (value == validValue) return validValue;
      if (value.toString() == validValue.toString()) return validValue;
    }

    return defaultValue;
  }

  /// Safely accesses nested map properties
  static T? safeNestedAccess<T>(
    Map<dynamic, dynamic>? map,
    List<dynamic> keys, {
    T? defaultValue,
  }) {
    if (map == null) return defaultValue;

    dynamic current = map;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }

    return current is T ? current : defaultValue;
  }

  /// Validates list contents and converts safely
  static List<T> safeList<T>(
    dynamic value, {
    List<T> defaultValue = const [],
    bool allowEmpty = true,
  }) {
    if (value == null) return defaultValue;

    if (value is List) {
      if (!allowEmpty && value.isEmpty) return defaultValue;

      final result = <T>[];
      for (final item in value) {
        if (item is T) {
          result.add(item);
        }
      }
      return result;
    }

    return defaultValue;
  }

  /// Validates map structure and converts safely
  static Map<K, V> safeMap<K, V>(
    dynamic value, {
    Map<K, V> defaultValue = const {},
    bool allowEmpty = true,
  }) {
    if (value == null) return defaultValue;

    if (value is Map) {
      if (!allowEmpty && value.isEmpty) return defaultValue;

      final result = <K, V>{};
      value.forEach((key, val) {
        if (key is K && val is V) {
          result[key] = val;
        }
      });
      return result;
    }

    return defaultValue;
  }
}

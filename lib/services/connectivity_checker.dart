import 'dart:io';
import 'package:http/http.dart' as http;

/// Service to check backend connectivity and provide helpful diagnostics
class ConnectivityChecker {
  static const String _baseUrl = 'http://127.0.0.1:8001/api/v1';

  /// Check if the backend server is reachable
  static Future<ConnectivityResult> checkBackendConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return ConnectivityResult.success;
      } else {
        return ConnectivityResult.serverError;
      }
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused')) {
        return ConnectivityResult.connectionRefused;
      } else if (e.message.contains('Network is unreachable')) {
        return ConnectivityResult.networkUnreachable;
      } else {
        return ConnectivityResult.networkError;
      }
    } on HttpException {
      return ConnectivityResult.httpError;
    } on FormatException {
      return ConnectivityResult.invalidResponse;
    } catch (e) {
      return ConnectivityResult.unknownError;
    }
  }

  /// Get a user-friendly message for the connectivity result
  static String getConnectivityMessage(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.success:
        return 'Server is running and accessible';
      case ConnectivityResult.connectionRefused:
        return 'Backend server is not running. Please start the server on port 8001.';
      case ConnectivityResult.networkUnreachable:
        return 'Network connection issue. Please check your internet connection.';
      case ConnectivityResult.serverError:
        return 'Server is running but returning errors. Please check server logs.';
      case ConnectivityResult.httpError:
        return 'HTTP protocol error. Please check server configuration.';
      case ConnectivityResult.invalidResponse:
        return 'Invalid response from server. Please check API endpoints.';
      case ConnectivityResult.networkError:
        return 'Network error occurred. Please try again.';
      case ConnectivityResult.unknownError:
        return 'Unknown connectivity issue. Please check server status.';
    }
  }
}

enum ConnectivityResult {
  success,
  connectionRefused,
  networkUnreachable,
  serverError,
  httpError,
  invalidResponse,
  networkError,
  unknownError,
}
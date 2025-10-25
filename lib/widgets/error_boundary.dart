import 'package:flutter/material.dart';
import '../services/error_handler.dart';

/// A widget that catches and handles errors from its child widgets
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(Object error, StackTrace? stackTrace)? onError;
  final bool showRetryButton;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.showRetryButton = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  bool _hasError = false;

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      // Reset error state when child changes
      _hasError = false;
      _error = null;
    }
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    // Log the error
    ErrorHandler.logError(error, stackTrace, 'ErrorBoundary');

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);

    setState(() {
      _hasError = true;
      _error = error;
    });
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.errorWidget != null) {
        return widget.errorWidget!;
      }

      return _buildDefaultErrorWidget();
    }

    // Set up error widget builder to catch Flutter framework errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
      return _buildDefaultErrorWidget();
    };

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    final errorMessage = _error != null
        ? ErrorHandler.userMessage(_error!)
        : 'An unexpected error occurred';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.showRetryButton)
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to home or safe screen
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simpler error boundary for wrapping individual components
class ComponentErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final Function(Object error, StackTrace? stackTrace)? onError;

  const ComponentErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    Widget errorWidget =
        fallback ??
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Component failed to load',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );

    return ErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      showRetryButton: false,
      child: child,
    );
  }
}

/// Extension to easily wrap widgets with error boundaries
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget? errorWidget,
    Function(Object error, StackTrace? stackTrace)? onError,
    bool showRetryButton = true,
  }) {
    return ErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      showRetryButton: showRetryButton,
      child: this,
    );
  }

  Widget withComponentErrorBoundary({
    Widget? fallback,
    Function(Object error, StackTrace? stackTrace)? onError,
  }) {
    return ComponentErrorBoundary(
      fallback: fallback,
      onError: onError,
      child: this,
    );
  }
}

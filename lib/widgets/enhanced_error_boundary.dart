import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/feedback_service.dart';
import 'loading_overlay.dart';

/// Enhanced error boundary with better error recovery and user feedback.
///
/// IMPORTANT: This widget must be rendered inside a [MaterialApp] or [WidgetsApp].
/// Using it outside of these contexts will result in runtime errors such as
/// "No Directionality widget found", "No MediaQuery widget ancestor found", etc.
/// Ensure your widget tree is properly wrapped to provide the required context.
class EnhancedErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(Object error, StackTrace? stackTrace)? onError;
  final bool showRetryButton;
  final bool showFeedback;
  final String? context;

  const EnhancedErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.showRetryButton = true,
    this.showFeedback = true,
    this.context,
  });

  @override
  State<EnhancedErrorBoundary> createState() => _EnhancedErrorBoundaryState();
}

class _EnhancedErrorBoundaryState extends State<EnhancedErrorBoundary> {
  Object? _error;
  bool _hasError = false;
  bool _isRetrying = false;

  // Preserve previous ErrorWidget.builder so we can restore it in dispose.
  Widget Function(FlutterErrorDetails)? _previousErrorWidgetBuilder;

  @override
  void initState() {
    super.initState();
    // Save previous builder and install a safe builder that schedules error handling
    _previousErrorWidgetBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule handling after the current frame to avoid setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleError(details.exception, details.stack);
        }
      });

      // Return a simple, self-contained widget that does not require Theme/Directionality.
      return _buildSimpleErrorWidget(details);
    };
  }

  @override
  void dispose() {
    // Restore previous builder
    if (_previousErrorWidgetBuilder != null) {
      ErrorWidget.builder = _previousErrorWidgetBuilder!;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      // Reset error state when child changes
      _hasError = false;
      _error = null;
    }
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    // Log the error
    ErrorHandler.logError(
      error,
      stackTrace,
      widget.context ?? 'EnhancedErrorBoundary',
    );

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);

    // Show feedback if enabled
    if (widget.showFeedback && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.showError(
            error,
            onRetry: widget.showRetryButton ? _retry : null,
          );
        }
      });
    }

    setState(() {
      _hasError = true;
      _error = error;
    });
  }

  void _retry() {
    setState(() {
      _isRetrying = true;
    });

    // Simulate a brief loading state before resetting
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _error = null;
          _isRetrying = false;
        });
      }
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

    // ErrorWidget.builder is installed in initState to avoid reassigning on every build.

    return LoadingOverlay(
      isLoading: _isRetrying,
      loadingMessage: 'Retrying...',
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    // Make this widget tolerant when running above the MaterialApp (no Theme/Directionality/MediaQuery).
    final themeWidget = context.findAncestorWidgetOfExactType<Theme>();
    final theme = themeWidget?.data ?? ThemeData.fallback();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final errorMessage = _error != null
        ? ErrorHandler.userMessage(_error!)
        : 'An unexpected error occurred';

    Widget content = Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.showRetryButton)
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to home or safe screen
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );

    // If running without Directionality or MediaQuery, provide minimal wrappers.
    if (Directionality.maybeOf(context) == null ||
        MediaQuery.maybeOf(context) == null) {
      content = Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.implicitView!),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Simple, minimal error widget used by the global ErrorWidget.builder where
  /// there is no BuildContext available. This widget avoids relying on Theme or
  /// Directionality so it can be shown safely from the error builder.
  Widget _buildSimpleErrorWidget(FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'An unexpected error occurred',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen-level error boundary that wraps entire screens
class ScreenErrorBoundary extends StatelessWidget {
  final Widget child;
  final String screenName;

  const ScreenErrorBoundary({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedErrorBoundary(
      context: screenName,
      showFeedback: true,
      showRetryButton: true,
      child: child,
    );
  }
}

/// Component-level error boundary for individual widgets
class ComponentErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final Function(Object error, StackTrace? stackTrace)? onError;
  final String? componentName;

  const ComponentErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.componentName,
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

    return EnhancedErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      showRetryButton: false,
      showFeedback: false,
      context: componentName,
      child: child,
    );
  }
}

/// Network operation error boundary with automatic retry
class NetworkErrorBoundary extends StatefulWidget {
  final Widget child;
  final Future<void> Function() operation;
  final Widget? loadingWidget;
  final String operationName;

  const NetworkErrorBoundary({
    super.key,
    required this.child,
    required this.operation,
    this.loadingWidget,
    required this.operationName,
  });

  @override
  State<NetworkErrorBoundary> createState() => _NetworkErrorBoundaryState();
}

class _NetworkErrorBoundaryState extends State<NetworkErrorBoundary> {
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _performOperation();
  }

  Future<void> _performOperation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.operation();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        ErrorHandler.logError(
          error,
          stackTrace,
          'NetworkErrorBoundary.${widget.operationName}',
        );
        setState(() {
          _isLoading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Connection failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                ErrorHandler.userMessage(_error!),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _performOperation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Extension to easily wrap widgets with enhanced error boundaries
extension EnhancedErrorBoundaryExtension on Widget {
  Widget withEnhancedErrorBoundary({
    Widget? errorWidget,
    Function(Object error, StackTrace? stackTrace)? onError,
    bool showRetryButton = true,
    bool showFeedback = true,
    String? context,
  }) {
    return EnhancedErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      showRetryButton: showRetryButton,
      showFeedback: showFeedback,
      context: context,
      child: this,
    );
  }

  Widget withScreenErrorBoundary(String screenName) {
    return ScreenErrorBoundary(screenName: screenName, child: this);
  }

  Widget withComponentErrorBoundary({
    Widget? fallback,
    Function(Object error, StackTrace? stackTrace)? onError,
    String? componentName,
  }) {
    return ComponentErrorBoundary(
      fallback: fallback,
      onError: onError,
      componentName: componentName,
      child: this,
    );
  }
}

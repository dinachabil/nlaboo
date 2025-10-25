import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/localization_service.dart';

/// Standardized feedback service for consistent user notifications
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  /// Shows a success snackbar with consistent styling
  void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
      icon: Icons.check_circle_outline,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error snackbar with consistent styling and retry option
  void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    final standardizedError = ErrorHandler.standardizeError(error);
    final errorMessage = customMessage ?? standardizedError.message;
    final recoverySuggestion = ErrorHandler.getRecoverySuggestion(
      standardizedError,
    );

    // Combine error message with recovery suggestion if available
    final fullMessage = recoverySuggestion != null
        ? '$errorMessage\n\n$recoverySuggestion'
        : errorMessage;

    final action =
        onRetry != null && ErrorHandler.isRecoverable(standardizedError)
        ? SnackBarAction(
            label: LocalizationService.tr('retry'),
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: onRetry,
          )
        : null;

    _showSnackBar(
      context,
      fullMessage,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
      icon: Icons.error_outline,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning snackbar
  void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      textColor: Theme.of(context).colorScheme.onTertiaryContainer,
      icon: Icons.warning_amber_rounded,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info snackbar
  void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
      icon: Icons.info_outline,
      duration: duration,
      action: action,
    );
  }

  /// Shows a loading snackbar that persists until dismissed
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoadingSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onCancel,
  }) {
    final action = onCancel != null
        ? SnackBarAction(
            label: LocalizationService.tr('cancel'),
            onPressed: onCancel,
          )
        : null;

    return _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      textColor: Theme.of(context).colorScheme.onSurface,
      icon: Icons.hourglass_empty,
      duration: const Duration(days: 1), // Persistent until dismissed
      action: action,
      showProgress: true,
    );
  }

  /// Private method to show snackbar with consistent styling
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
    bool showProgress = false,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Hides the current snackbar
  void hideCurrentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Clears all snackbars
  void clearSnackBars(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Extension to easily show feedback from any BuildContext
extension FeedbackExtension on BuildContext {
  FeedbackService get feedback => FeedbackService();

  void showSuccess(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    feedback.showSuccessSnackBar(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
    );
  }

  void showError(
    dynamic error, {
    Duration? duration,
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    feedback.showErrorSnackBar(
      this,
      error,
      duration: duration ?? const Duration(seconds: 5),
      onRetry: onRetry,
      customMessage: customMessage,
    );
  }

  void showWarning(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    feedback.showWarningSnackBar(
      this,
      message,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  void showInfo(String message, {Duration? duration, SnackBarAction? action}) {
    feedback.showInfoSnackBar(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    String message, {
    VoidCallback? onCancel,
  }) {
    return feedback.showLoadingSnackBar(this, message, onCancel: onCancel);
  }

  void hideSnackBar() {
    feedback.hideCurrentSnackBar(this);
  }

  void clearSnackBars() {
    feedback.clearSnackBars(this);
  }
}

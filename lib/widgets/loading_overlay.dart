import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// A loading overlay widget that can be shown over any content.
///
/// **IMPORTANT:** This widget must be rendered inside a [MaterialApp] or [WidgetsApp].
/// Using it outside of these contexts will result in runtime errors such as
/// "No Directionality widget found", "No MediaQuery widget ancestor found", etc.
/// Ensure your widget tree is properly wrapped to provide the required context.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.dismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Use a centered Stack with a Positioned.fill overlay so we don't rely on
    // AlignmentDirectional or other Directionality-dependent defaults.
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loadingMessage ?? LocalizationService.tr('loading'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (dismissible) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: onDismiss,
                            child: Text(
                              LocalizationService.tr('cancel'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A loading button that shows loading state
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final String? loadingText;
  final ButtonStyle? style;
  final double? width;
  final double? height;

  const LoadingButton({
    super.key,
    required this.isLoading,
    this.onPressed,
    required this.child,
    this.loadingText,
    this.style,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText ?? LocalizationService.tr('loading'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              )
            : child,
      ),
    );
  }
}

/// A progress indicator for long-running operations
class ProgressIndicatorCard extends StatelessWidget {
  final double? progress;
  final String title;
  final String? subtitle;
  final bool showPercentage;
  final VoidCallback? onCancel;

  const ProgressIndicatorCard({
    super.key,
    this.progress,
    required this.title,
    this.subtitle,
    this.showPercentage = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progress != null ? (progress! * 100).round() : null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    tooltip: LocalizationService.tr('cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            if (showPercentage && percentage != null) ...[
              const SizedBox(height: 8),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extension to easily wrap widgets with loading overlay
extension LoadingExtension on Widget {
  Widget withLoadingOverlay({
    required bool isLoading,
    String? loadingMessage,
    bool dismissible = false,
    VoidCallback? onDismiss,
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      loadingMessage: loadingMessage,
      dismissible: dismissible,
      onDismiss: onDismiss,
      child: this,
    );
  }
}

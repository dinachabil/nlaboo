import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_management_service.dart';

/// Enhanced cached image widget with loading states, error handling, and fallback images
class EnhancedCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final bool showLoadingIndicator;
  final String? fallbackImageUrl;

  const EnhancedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.showLoadingIndicator = true,
    this.fallbackImageUrl,
  });

  @override
  State<EnhancedCachedImage> createState() => _EnhancedCachedImageState();
}

class _EnhancedCachedImageState extends State<EnhancedCachedImage>
    with TickerProviderStateMixin {
  final ImageManagementService _imageService = ImageManagementService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  File? _cachedImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _loadImage();
  }

  @override
  void didUpdateWidget(EnhancedCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _fadeController.reset();
    });

    try {
      // Try to get cached image first
      final cachedFileInfo = await _imageService.getCachedImageSync(widget.imageUrl);
      if (cachedFileInfo != null && cachedFileInfo is File) {
        setState(() {
          _cachedImage = cachedFileInfo;
          _isLoading = false;
        });
        _fadeController.forward();
        return;
      }

      // If not cached, download and cache
      final downloadedFile = await _imageService.getCachedImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _cachedImage = downloadedFile;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_hasError) {
      content = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: widget.borderRadius,
            ),
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: widget.width != null && widget.height != null
                  ? (widget.width! + widget.height!) / 6
                  : 24,
            ),
          );
    } else if (_isLoading) {
      content = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: widget.borderRadius,
            ),
            child: widget.showLoadingIndicator
                ? Center(
                    child: SizedBox(
                      width: widget.width != null && widget.height != null
                          ? (widget.width! + widget.height!) / 8
                          : 20,
                      height: widget.width != null && widget.height != null
                          ? (widget.width! + widget.height!) / 8
                          : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : null,
          );
    } else if (_cachedImage != null) {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: Image.file(
          _cachedImage!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ??
                Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: widget.borderRadius,
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
          },
        ),
      );
    } else {
      content = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          );
    }

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

/// Avatar widget with enhanced caching and fallback
class EnhancedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double radius;
  final Color? backgroundColor;
  final String? fallbackImageUrl;

  const EnhancedAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        child: ClipOval(
          child: EnhancedCachedImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero, // Already clipped by CircleAvatar
            errorWidget: _buildFallbackAvatar(context),
            placeholder: _buildFallbackAvatar(context),
          ),
        ),
      );
    }

    return _buildFallbackAvatar(context);
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      child: fallbackText != null && fallbackText!.isNotEmpty
          ? Text(
              fallbackText!.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onPrimary,
              size: radius * 1.2,
            ),
    );
  }
}

/// Team logo widget with enhanced caching
class TeamLogo extends StatelessWidget {
  final String? logoUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const TeamLogo({
    super.key,
    this.logoUrl,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: EnhancedCachedImage(
          imageUrl: logoUrl!,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
          errorWidget: fallback ?? _buildDefaultFallback(context),
          placeholder: _buildDefaultFallback(context),
        ),
      );
    }

    return fallback ?? _buildDefaultFallback(context);
  }

  Widget _buildDefaultFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        Icons.sports_soccer,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: width * 0.6,
      ),
    );
  }
}
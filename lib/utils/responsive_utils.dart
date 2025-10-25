import 'package:flutter/material.dart';

/// Screen size types for responsive design
enum ScreenSize { mobile, tablet, desktop }

/// Responsive utilities for FootConnect Flutter app
/// Provides breakpoints, helper methods, and responsive design patterns
class ResponsiveUtils {
  // Breakpoints following Material Design guidelines
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  static const double desktopMinWidth = 900;

  // Touch target minimum sizes (Material Design)
  static const double minTouchTargetSize = 48.0;
  static const double minButtonHeight = 48.0;

  /// Get current screen size based on width
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMaxWidth) {
      return ScreenSize.mobile;
    } else if (width < desktopMinWidth) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(16.0);
      case ScreenSize.tablet:
        return const EdgeInsets.all(24.0);
      case ScreenSize.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24.0);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  /// Get responsive card width for horizontal lists
  static double getCardWidth(BuildContext context, {double? maxWidth}) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenSize) {
      case ScreenSize.mobile:
        return maxWidth ?? (screenWidth * 0.8); // 80% of screen width
      case ScreenSize.tablet:
        return maxWidth ?? 280.0;
      case ScreenSize.desktop:
        return maxWidth ?? 320.0;
    }
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobileCount = 1,
    int tabletCount = 2,
    int desktopCount = 3,
  }) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return mobileCount;
      case ScreenSize.tablet:
        return tabletCount;
      case ScreenSize.desktop:
        return desktopCount;
    }
  }

  /// Get responsive spacing between items
  static double getItemSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return 12.0;
      case ScreenSize.tablet:
        return 16.0;
      case ScreenSize.desktop:
        return 20.0;
    }
  }

  /// Get responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return 1.0;
      case ScreenSize.tablet:
        return 1.1;
      case ScreenSize.desktop:
        return 1.2;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final scaleFactor = getTextScaleFactor(context);
    return baseSize * scaleFactor;
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return minButtonHeight;
      case ScreenSize.tablet:
        return 56.0;
      case ScreenSize.desktop:
        return 60.0;
    }
  }

  /// Get responsive max width for centered content
  static double getMaxContentWidth(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 600.0;
      case ScreenSize.desktop:
        return 800.0;
    }
  }

  /// Get responsive form field width
  static double getFormFieldWidth(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 400.0;
      case ScreenSize.desktop:
        return 450.0;
    }
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Get safe area padding considering keyboard
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding + mediaQuery.viewInsets;
  }

  /// Build responsive layout with LayoutBuilder
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobileLayout,
    required Widget tabletLayout,
    required Widget desktopLayout,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(context);

        switch (screenSize) {
          case ScreenSize.mobile:
            return mobileLayout;
          case ScreenSize.tablet:
            return tabletLayout;
          case ScreenSize.desktop:
            return desktopLayout;
        }
      },
    );
  }

  /// Create responsive grid delegate
  static SliverGridDelegate getResponsiveGridDelegate(
    BuildContext context, {
    double childAspectRatio = 0.75,
    int? mobileCrossAxisCount,
    int? tabletCrossAxisCount,
    int? desktopCrossAxisCount,
  }) {
    final crossAxisCount = getGridCrossAxisCount(
      context,
      mobileCount: mobileCrossAxisCount ?? 1,
      tabletCount: tabletCrossAxisCount ?? 2,
      desktopCount: desktopCrossAxisCount ?? 3,
    );

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: getItemSpacing(context),
      mainAxisSpacing: getItemSpacing(context),
    );
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(
    BuildContext context, {
    double? maxWidth,
    double? maxHeight,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth ?? getMaxContentWidth(context),
      maxHeight: maxHeight ?? double.infinity,
    );
  }
}

/// Extension methods for responsive design
extension ResponsiveContext on BuildContext {
  /// Get current screen size
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);

  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Check if landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Check if portrait
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  /// Get responsive padding
  EdgeInsets get responsivePadding =>
      ResponsiveUtils.getResponsivePadding(this);

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding =>
      ResponsiveUtils.getResponsiveHorizontalPadding(this);

  /// Get responsive item spacing
  double get itemSpacing => ResponsiveUtils.getItemSpacing(this);

  /// Get responsive text scale factor
  double get textScaleFactor => ResponsiveUtils.getTextScaleFactor(this);

  /// Get responsive button height
  double get buttonHeight => ResponsiveUtils.getButtonHeight(this);

  /// Get responsive max content width
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);

  /// Get responsive form field width
  double get formFieldWidth => ResponsiveUtils.getFormFieldWidth(this);

  /// Check if keyboard is visible
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);

  /// Get keyboard height
  double get keyboardHeight => ResponsiveUtils.getKeyboardHeight(this);

  /// Get responsive icon size
  double get iconSize => ResponsiveUtils.getIconSize(this, 24);

  /// Get responsive border radius
  double get borderRadius {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }

  /// Get responsive elevation
  double get cardElevation {
    if (isMobile) return 2;
    if (isTablet) return 4;
    return 6;
  }

  /// Get responsive touch target size (minimum 44px for accessibility)
  double get touchTargetSize => 48;

  /// Get responsive keyboard spacing (extra space when keyboard is visible)
  double get keyboardSpacing {
    final viewInsets = MediaQuery.of(this).viewInsets;
    return viewInsets.bottom > 0 ? viewInsets.bottom + 16 : 0;
  }

  /// Get responsive aspect ratio for cards
  double get cardAspectRatio {
    if (isMobile) return 0.8;
    if (isTablet) return 0.75;
    return 0.7;
  }

  /// Get responsive horizontal list height
  double get horizontalListHeight {
    if (isMobile) return 180;
    if (isTablet) return 200;
    return 220;
  }

  /// Get responsive grid spacing
  double get gridSpacing {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }

  /// Get responsive card width for horizontal lists
  double get cardWidth {
    if (isMobile) return 280;
    if (isTablet) return 320;
    return 360;
  }

  /// Get responsive grid cross axis count
  int get gridCrossAxisCount {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }
}

/// Extension for responsive widgets
extension ResponsiveWidget on Widget {
  /// Add responsive padding
  Widget withResponsivePadding(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: this,
    );
  }

  /// Constrain width responsively
  Widget withResponsiveWidth(BuildContext context, {double? maxWidth}) {
    return Container(
      constraints: ResponsiveUtils.getResponsiveConstraints(
        context,
        maxWidth: maxWidth,
      ),
      child: this,
    );
  }

  /// Center with responsive max width
  Widget centeredWithResponsiveWidth(BuildContext context) {
    return Center(
      child: Container(
        constraints: ResponsiveUtils.getResponsiveConstraints(context),
        child: this,
      ),
    );
  }
}

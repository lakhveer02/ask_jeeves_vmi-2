import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// Check if device is tablet (600 <= width < 900)
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 900;
  }

  /// Check if device is desktop (width >= 900)
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 900;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isMobile(context)) {
      return baseSpacing;
    } else if (isTablet(context)) {
      return baseSpacing * 1.2;
    } else {
      return baseSpacing * 1.5;
    }
  }

  /// Get max content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context);
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 800;
    }
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48;
    } else if (isTablet(context)) {
      return 56;
    } else {
      return 64;
    }
  }

  /// Get responsive card elevation
  static double getResponsiveElevation(BuildContext context) {
    if (isMobile(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 6;
    } else {
      return 8;
    }
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    if (isMobile(context)) {
      return baseRadius;
    } else if (isTablet(context)) {
      return baseRadius * 1.2;
    } else {
      return baseRadius * 1.4;
    }
  }

  /// Get responsive grid column count
  static int getGridColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get responsive aspect ratio for cards
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 1.5;
    } else if (isTablet(context)) {
      return 1.6;
    } else {
      return 1.8;
    }
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return 600;
    }
  }

  /// Get responsive bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    final height = screenHeight(context);
    if (isMobile(context)) {
      return height * 0.9;
    } else if (isTablet(context)) {
      return height * 0.8;
    } else {
      return height * 0.7;
    }
  }

  /// Get responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight * 1.2;
    } else {
      return kToolbarHeight * 1.4;
    }
  }

  /// Get responsive list tile height
  static double getListTileHeight(BuildContext context) {
    if (isMobile(context)) {
      return 72;
    } else if (isTablet(context)) {
      return 80;
    } else {
      return 88;
    }
  }

  /// Get text scale factor (for accessibility)
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Clamp text scale factor for better readability
  static double getClampedTextScaleFactor(BuildContext context, {double min = 0.8, double max = 1.3}) {
    final scaleFactor = getTextScaleFactor(context);
    return scaleFactor.clamp(min, max);
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: getMaxContentWidth(context),
      minHeight: 0,
    );
  }

  /// Get responsive image size
  static double getResponsiveImageSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.3;
    } else {
      return baseSize * 1.6;
    }
  }

  /// Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  /// Get responsive spacing between elements
  static SizedBox getResponsiveVerticalSpacing(BuildContext context, {double small = 8, double medium = 16, double large = 24}) {
    if (isMobile(context)) {
      return SizedBox(height: small);
    } else if (isTablet(context)) {
      return SizedBox(height: medium);
    } else {
      return SizedBox(height: large);
    }
  }

  /// Get responsive horizontal spacing
  static SizedBox getResponsiveHorizontalSpacing(BuildContext context, {double small = 8, double medium = 16, double large = 24}) {
    if (isMobile(context)) {
      return SizedBox(width: small);
    } else if (isTablet(context)) {
      return SizedBox(width: medium);
    } else {
      return SizedBox(width: large);
    }
  }

  /// Get device pixel ratio
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Check if device has high pixel density
  static bool isHighDensity(BuildContext context) {
    return getDevicePixelRatio(context) >= 2.0;
  }

  /// Get responsive modal bottom sheet constraints
  static BoxConstraints getModalBottomSheetConstraints(BuildContext context) {
    return BoxConstraints(
      maxHeight: getBottomSheetHeight(context),
      maxWidth: getMaxContentWidth(context),
    );
  }

  /// Get responsive snackbar width
  static double getSnackBarWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context);
    } else {
      return getMaxContentWidth(context);
    }
  }

  /// Get responsive FAB size
  static double getFABSize(BuildContext context) {
    if (isMobile(context)) {
      return 56;
    } else if (isTablet(context)) {
      return 64;
    } else {
      return 72;
    }
  }

  /// Get responsive chip height
  static double getChipHeight(BuildContext context) {
    if (isMobile(context)) {
      return 32;
    } else if (isTablet(context)) {
      return 36;
    } else {
      return 40;
    }
  }

  /// Get responsive switch scale
  static double getSwitchScale(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Get responsive slider height
  static double getSliderHeight(BuildContext context) {
    if (isMobile(context)) {
      return 40;
    } else if (isTablet(context)) {
      return 48;
    } else {
      return 56;
    }
  }

  /// Get responsive divider thickness
  static double getDividerThickness(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 1.5;
    } else {
      return 2;
    }
  }

  /// Get responsive checkbox size
  static double getCheckboxSize(BuildContext context) {
    if (isMobile(context)) {
      return 24;
    } else if (isTablet(context)) {
      return 28;
    } else {
      return 32;
    }
  }

  /// Get responsive radio button size
  static double getRadioButtonSize(BuildContext context) {
    if (isMobile(context)) {
      return 20;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 28;
    }
  }

  /// Get responsive progress indicator size
  static double getProgressIndicatorSize(BuildContext context) {
    if (isMobile(context)) {
      return 36;
    } else if (isTablet(context)) {
      return 44;
    } else {
      return 52;
    }
  }

  /// Get responsive avatar size
  static double getAvatarSize(BuildContext context, {double baseSize = 40}) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }

  /// Get responsive tooltip padding
  static EdgeInsets getTooltipPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  /// Get responsive menu item height
  static double getMenuItemHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48;
    } else if (isTablet(context)) {
      return 56;
    } else {
      return 64;
    }
  }

  /// Get responsive tab height
  static double getTabHeight(BuildContext context) {
    if (isMobile(context)) {
      return 46;
    } else if (isTablet(context)) {
      return 52;
    } else {
      return 58;
    }
  }

  /// Get responsive expansion tile padding
  static EdgeInsets getExpansionTilePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
  }
}

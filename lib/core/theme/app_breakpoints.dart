import 'package:flutter/material.dart';

/// Responsive breakpoints:
/// mobile < 768, tablet 768-1023, desktop 1024-1439, large desktop 1440+.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

/// Convenience helpers so screens never hardcode screen widths.
class Responsive {
  const Responsive._();

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => widthOf(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= AppBreakpoints.mobile && w < AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= AppBreakpoints.tablet;

  static bool isLargeDesktop(BuildContext context) => widthOf(context) >= AppBreakpoints.desktop;

  /// Returns [mobile] below 768, [tablet] between 768 and 1023,
  /// otherwise [desktop]. [tablet] falls back to [desktop] when omitted.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }
}

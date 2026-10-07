import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_spacing.dart';

/// Builds exactly one layout variant for the current breakpoint, so widget
/// trees are never built twice.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return mobile(context);
    if (Responsive.isTablet(context)) return (tablet ?? desktop)(context);
    return desktop(context);
  }
}

/// Centers content with a max width and responsive page padding.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppDimensions.contentMaxWidth,
    this.padding,
    this.scroll = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? AppSpacing.pagePadding(context),
          child: child,
        ),
      ),
    );
    if (!scroll) return content;
    return SingleChildScrollView(child: content);
  }
}

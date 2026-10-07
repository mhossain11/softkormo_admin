import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Spacing scale. Only these values should be used in the app.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);
  static const EdgeInsets formGap = EdgeInsets.only(bottom: lg);

  /// Page padding adapts to the viewport width.
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppBreakpoints.mobile) return const EdgeInsets.all(lg);
    if (w < AppBreakpoints.desktop) return const EdgeInsets.all(xxl);
    return const EdgeInsets.fromLTRB(xxxl, xxl, xxxl, xxxl);
  }

  static SizedBox get h4 => const SizedBox(height: xs);
  static SizedBox get h8 => const SizedBox(height: sm);
  static SizedBox get h12 => const SizedBox(height: md);
  static SizedBox get h16 => const SizedBox(height: lg);
  static SizedBox get h24 => const SizedBox(height: xxl);
  static SizedBox get h32 => const SizedBox(height: xxxl);
  static SizedBox get w4 => const SizedBox(width: xs);
  static SizedBox get w8 => const SizedBox(width: sm);
  static SizedBox get w12 => const SizedBox(width: md);
  static SizedBox get w16 => const SizedBox(width: lg);
  static SizedBox get w24 => const SizedBox(width: xxl);
}

import 'package:flutter/material.dart';

/// Border radius scale. Keep radii small and consistent.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double pill = 100;

  static final BorderRadius smAll = BorderRadius.circular(sm);
  static final BorderRadius mdAll = BorderRadius.circular(md);
  static final BorderRadius lgAll = BorderRadius.circular(lg);
  static final BorderRadius pillAll = BorderRadius.circular(pill);
}

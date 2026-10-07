import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Light / dark theme switch. Values come from `AppTheme`.
class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.light.obs;

  ThemeMode get themeMode => mode.value;
  bool get isDark => mode.value == ThemeMode.dark;

  void setMode(ThemeMode value) {
    mode.value = value;
    Get.changeThemeMode(value);
  }

  void toggleLightDark() =>
      setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple global theme controller. Uses ValueNotifiers so widgets can listen
/// and update without introducing heavy DI. Stores primary color and border
/// color so the app can change them at runtime.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  // primary color for the app (used for AppBar, accents)
  static final ValueNotifier<Color> primaryColor = ValueNotifier<Color>(
    Colors.pink,
  );

  // border color for small boards and other decorative borders
  static final ValueNotifier<Color> borderColor = ValueNotifier<Color>(
    Colors.pinkAccent.shade100,
  );

  /// The color choices offered on the Settings screen - the single source of
  /// truth for "the app's available colors", also used anywhere else (e.g.
  /// decorative backgrounds) that needs to stay in sync with them.
  static final List<({Color primary, Color border, String nameKey})>
  colorPresets = [
    (primary: Colors.pink, border: Colors.pinkAccent.shade100, nameKey: 'pink'),
    (primary: Colors.blue, border: Colors.blueAccent.shade100, nameKey: 'blue'),
    (
      primary: Colors.lightGreen,
      border: Colors.lightGreenAccent.shade100,
      nameKey: 'green',
    ),
    (
      primary: Colors.deepOrange,
      border: Colors.deepOrangeAccent.shade100,
      nameKey: 'orange',
    ),
    (
      primary: Colors.purple,
      border: Colors.purpleAccent.shade100,
      nameKey: 'purple',
    ),
    (primary: Colors.cyan, border: Colors.cyanAccent.shade100, nameKey: 'cyan'),
    (primary: Colors.brown, border: Colors.brown.shade200, nameKey: 'brown'),
    (primary: Colors.grey, border: Colors.grey.shade300, nameKey: 'grey'),
  ];

  // SharedPreferences keys
  static const String _kIsDark = 'theme_is_dark';
  static const String _kPrimary = 'theme_primary';
  static const String _kBorder = 'theme_border';

  static void toggle() {
    isDark.value = !isDark.value;
    _saveIsDark();
  }

  static void setPrimary(Color c) {
    primaryColor.value = c;
    _saveColors();
  }

  static void setBorder(Color c) {
    borderColor.value = c;
    _saveColors();
  }

  /// Initialize controller from persisted settings.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final isDarkPref = prefs.getBool(_kIsDark);
    if (isDarkPref != null) isDark.value = isDarkPref;

    final primaryInt = prefs.getInt(_kPrimary);
    if (primaryInt != null) primaryColor.value = Color(primaryInt);

    final borderInt = prefs.getInt(_kBorder);
    if (borderInt != null) borderColor.value = Color(borderInt);
  }

  static Future<void> _saveIsDark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, isDark.value);
  }

  static Future<void> _saveColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrimary, primaryColor.value.toARGB32());
    await prefs.setInt(_kBorder, borderColor.value.toARGB32());
  }

}

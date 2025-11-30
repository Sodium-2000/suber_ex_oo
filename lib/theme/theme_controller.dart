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

  // Preset color pairs (primary, border) to cycle through
  static final List<Map<String, Color>> _presets = [
    {'primary': Colors.pink, 'border': Colors.pinkAccent.shade100},
    {'primary': Colors.blue, 'border': Colors.blueAccent.shade100},
    {'primary': Colors.lightGreen, 'border': Colors.lightGreenAccent.shade100},
    {'primary': Colors.orange, 'border': Colors.orangeAccent.shade100},
    {'primary': Colors.purple, 'border': Colors.purpleAccent.shade100},
    {'primary': Colors.cyan, 'border': Colors.cyanAccent.shade100},
    {'primary': Colors.brown, 'border': Colors.brown.shade200},
    {'primary': Colors.grey, 'border': Colors.grey.shade300},
  ];

  static int _presetIndex = 0;

  // SharedPreferences keys
  static const String _kIsDark = 'theme_is_dark';
  static const String _kPrimary = 'theme_primary';
  static const String _kBorder = 'theme_border';
  static const String _kPresetIndex = 'theme_preset_index';

  /// Cycle to the next preset in the list and apply it.
  static void cyclePreset() {
    _presetIndex = (_presetIndex + 1) % _presets.length;
    final p = _presets[_presetIndex];
    primaryColor.value = p['primary']!;
    borderColor.value = p['border']!;
    _savePresetIndex();
    _saveColors();
  }

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
    _presetIndex = prefs.getInt(_kPresetIndex) ?? 0;

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
    await prefs.setInt(_kPrimary, primaryColor.value.value);
    await prefs.setInt(_kBorder, borderColor.value.value);
  }

  static Future<void> _savePresetIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPresetIndex, _presetIndex);
  }
}

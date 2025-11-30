import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Very small language controller for quick i18n (quick/simple approach).
/// This uses a ValueNotifier so UI can listen and rebuild when language changes.
class LanguageController {
  LanguageController._();

  /// Supported language code values: 'en', 'ar'
  static final ValueNotifier<String> lang = ValueNotifier<String>('en');

  static void toggle() => lang.value = (lang.value == 'en') ? 'ar' : 'en';

  static void set(String l) => lang.value = l;

  static const String _kLang = 'app_language';

  /// Initialize language from persisted setting.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLang);
    if (saved != null && saved.isNotEmpty) {
      lang.value = saved;
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, lang.value);
  }

  static void toggleAndSave() {
    lang.value = (lang.value == 'en') ? 'ar' : 'en';
    _save();
  }

  static void setAndSave(String l) {
    lang.value = l;
    _save();
  }
}

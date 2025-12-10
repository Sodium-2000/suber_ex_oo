import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing game UI settings
class GameSettingsService {
  static final GameSettingsService _instance = GameSettingsService._internal();
  factory GameSettingsService() => _instance;
  GameSettingsService._internal();

  static const String _dimmingEnabledKey = 'dimming_enabled';

  SharedPreferences? _prefs;

  // Use ValueNotifier to notify listeners when settings change
  final ValueNotifier<bool> dimmingEnabled = ValueNotifier<bool>(true);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    dimmingEnabled.value = _prefs?.getBool(_dimmingEnabledKey) ?? true;
  }

  bool get isDimmingEnabled => dimmingEnabled.value;

  Future<void> setDimmingEnabled(bool enabled) async {
    dimmingEnabled.value = enabled;
    await _prefs?.setBool(_dimmingEnabledKey, enabled);
  }
}

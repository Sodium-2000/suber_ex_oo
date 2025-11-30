import 'package:super_xo/controllers/language_controller.dart';

/// Minimal translations map for quick/simple localization.
/// Keys are string identifiers used across the app.
const Map<String, Map<String, String>> _translations = {
  'en': {
    'restart_title': 'Restart game?',
    'restart_message': 'This will clear the board and reset the game.',
    'cancel': 'Cancel',
    'restart': 'Restart',
    'game_over_title': 'Game Over',
    'game_over_draw': 'The game is a draw!',
    'game_over_winner': '{winner} wins the ultimate game🏆',
    'play_again': 'Play again',
    'close': 'Close',
    'language_english': 'English',
    'language_arabic': 'العربية',
    'toggle_language_tool': 'Toggle Language',
    'change_color_tool': 'Change Color',
    'change_theme_tool': 'Change Theme dark-light',
    'restart_game_tool': 'Restart Game',
    'undo_tool': 'Undo',
  },
  'ar': {
    'restart_title': 'إعادة بدء اللعبة؟',
    'restart_message': 'سيؤدي ذلك إلى مسح اللوحة وإعادة ضبط اللعبة',
    'cancel': 'إلغاء',
    'restart': 'إعادة بدء اللعبة',
    'game_over_title': '!!انتهت اللعبة',
    'game_over_draw': 'اللعبة انتهت بالتعادل!',
    'game_over_winner': '🏆 فاز في اللعبة {winner} ',
    'play_again': 'العب مرة أخرى',
    'close': 'إغلاق',
    'language_english': 'English',
    'language_arabic': 'العربية',
    'toggle_language_tool': 'تغيير اللغة',
    'change_color_tool': 'تغيير اللون',
    'change_theme_tool': 'تغيير المظهر داكن-فاتح',
    'restart_game_tool': 'إعادة اللعبة',
    'undo_tool': 'تراجع',
  },
};

/// Quick lookup. Uses the current value of [LanguageController.lang].
String tr(String key) {
  final code = LanguageController.lang.value;
  return _translations[code]?[key] ?? _translations['en']?[key] ?? key;
}

/// Helper that does a simple placeholder substitution for {winner}.
String trWithWinner(String key, String winner) {
  final template = tr(key);
  return template.replaceAll('{winner}', winner);
}

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundEffect { move, opponentMove, win, loss, draw }

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isMuted = false;

  // Sound file paths - easily changeable
  final Map<SoundEffect, String> _soundPaths = {
    SoundEffect.move: 'sounds/move.mp3',
    SoundEffect.opponentMove:
        'sounds/move.mp3', // Can use opponent_move.mp3 for different sound
    SoundEffect.win: 'sounds/win.mp3',
    SoundEffect.loss: 'sounds/loss.mp3',
    SoundEffect.draw: 'sounds/draw.mp3',
  };

  // Initialize and load mute preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('sound_muted') ?? false;
  }

  // Play a sound effect
  Future<void> play(SoundEffect effect) async {
    if (_isMuted) return;

    final path = _soundPaths[effect];
    if (path == null) return;

    try {
      // Create a new player for each sound to allow concurrent playback
      final player = AudioPlayer();
      await player.play(AssetSource(path));

      // Auto-dispose when sound completes
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // Toggle mute/unmute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', _isMuted);
  }

  // Set mute state
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', muted);
  }

  // Get current mute state
  bool get isMuted => _isMuted;
}

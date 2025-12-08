# Sound Files Setup

This folder contains sound effects for the game. Place your audio files here to enable sound.

## Required Files

1. **move.mp3** - Played when a player makes a move (X or O placed)
2. **win.mp3** - Played when you win the game (online mode only, local mode uses this for any winner)
3. **loss.mp3** - Played when you lose the game (online mode only)
4. **draw.mp3** - Played when the game ends in a draw

## Supported Formats

The game supports multiple audio formats:
- MP3 (recommended)
- WAV
- OGG
- Other formats supported by the `audioplayers` package

## Changing Sound Files

To use different sound files or formats:

1. **Replace the files** in this folder with your own audio files
2. **Update file names** in `lib/services/sound_service.dart` if using different names or formats:
   ```dart
   final Map<SoundEffect, String> _soundPaths = {
     SoundEffect.move: '../assets/sounds/move.mp3',    // Change these paths
     SoundEffect.win: 'sounds/win.mp3',
     SoundEffect.loss: 'sounds/loss.mp3',
     SoundEffect.draw: 'sounds/draw.mp3',
   };
   ```

## Removing Sounds

To completely disable sounds:
1. Enable "Mute Sounds" in the Settings screen, or
2. Leave this folder empty (the game will continue to work without errors)

## Finding Free Sound Effects

You can find free game sound effects at:
- [Freesound.org](https://freesound.org/)
- [ZapSplat](https://www.zapsplat.com/)
- [Mixkit](https://mixkit.co/free-sound-effects/game/)

## Technical Notes

- Sounds are managed by `SoundService` (singleton pattern)
- Mute preference is saved in SharedPreferences
- Missing sound files won't cause crashes - they're handled gracefully


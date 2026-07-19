import 'package:flutter/material.dart';
import 'package:super_xo/localization/app_localizations.dart';
import 'package:super_xo/screens/matchmaking_screen.dart';
import 'package:super_xo/screens/online_lobby_screen.dart';

/// Lets the player choose between quick random matchmaking and the existing
/// private room (create/join with a code) flow.
class OnlineModeSelectScreen extends StatelessWidget {
  const OnlineModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('play_online')), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OnlineModeButton(
                  icon: Icons.bolt,
                  label: tr('quick_match'),
                  description: tr('quick_match_description'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchmakingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _OnlineModeButton(
                  icon: Icons.vpn_key,
                  label: tr('private_game'),
                  description: tr('private_game_description'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnlineLobbyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;

  const _OnlineModeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

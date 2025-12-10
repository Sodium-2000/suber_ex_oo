import 'package:flutter/material.dart';
import 'package:super_xo/theme/theme_controller.dart';
import 'package:super_xo/controllers/language_controller.dart';
import 'package:super_xo/localization/app_localizations.dart';
import 'package:super_xo/services/sound_service.dart';
import 'package:super_xo/services/game_settings_service.dart';

/// Unified settings screen for theme, language, and color customization
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildColorSection(BuildContext context) {
    return _SettingsSection(
      title: tr('color_theme_section'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            tr('color_theme_description'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ValueListenableBuilder<Color>(
          valueListenable: ThemeController.primaryColor,
          builder: (context, currentColor, _) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _ColorOption(
                    color: Colors.pink,
                    borderColor: Colors.pinkAccent.shade100,
                    isSelected: currentColor == Colors.pink,
                    label: tr('pink'),
                  ),
                  _ColorOption(
                    color: Colors.blue,
                    borderColor: Colors.blueAccent.shade100,
                    isSelected: currentColor == Colors.blue,
                    label: tr('blue'),
                  ),
                  _ColorOption(
                    color: Colors.lightGreen,
                    borderColor: Colors.lightGreenAccent.shade100,
                    isSelected: currentColor == Colors.lightGreen,
                    label: tr('green'),
                  ),
                  _ColorOption(
                    color: Colors.orange,
                    borderColor: Colors.orangeAccent.shade100,
                    isSelected: currentColor == Colors.orange,
                    label: tr('orange'),
                  ),
                  _ColorOption(
                    color: Colors.purple,
                    borderColor: Colors.purpleAccent.shade100,
                    isSelected: currentColor == Colors.purple,
                    label: tr('purple'),
                  ),
                  _ColorOption(
                    color: Colors.cyan,
                    borderColor: Colors.cyanAccent.shade100,
                    isSelected: currentColor == Colors.cyan,
                    label: tr('cyan'),
                  ),
                  _ColorOption(
                    color: Colors.brown,
                    borderColor: Colors.brown.shade200,
                    isSelected: currentColor == Colors.brown,
                    label: tr('brown'),
                  ),
                  _ColorOption(
                    color: Colors.grey,
                    borderColor: Colors.grey.shade300,
                    isSelected: currentColor == Colors.grey,
                    label: tr('grey'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings_title')), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme mode section
            _SettingsSection(
              title: tr('theme_section'),
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: ThemeController.isDark,
                  builder: (context, isDark, _) {
                    return SwitchListTile(
                      title: Text(tr('dark_mode')),
                      subtitle: Text(tr('dark_mode_description')),
                      value: isDark,
                      onChanged: (_) => ThemeController.toggle(),
                      activeColor: Theme.of(context).primaryColor,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Language section
            _SettingsSection(
              title: tr('language_section'),
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: LanguageController.lang,
                  builder: (context, currentLang, _) {
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(tr('language_english')),
                          value: 'en',
                          groupValue: currentLang,
                          onChanged: (value) {
                            if (value != null) {
                              LanguageController.setAndSave(value);
                            }
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        RadioListTile<String>(
                          title: Text(tr('language_arabic')),
                          value: 'ar',
                          groupValue: currentLang,
                          onChanged: (value) {
                            if (value != null) {
                              LanguageController.setAndSave(value);
                            }
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sound section
            _SoundSection(),

            const SizedBox(height: 24),

            // Gameplay section
            _GameplaySection(),

            const SizedBox(height: 24),

            // Color theme section
            _buildColorSection(context),

            const SizedBox(height: 24),

            // Version section
            _SettingsSection(
              title: tr('about_section'),
              children: [
                ListTile(
                  title: Text(tr('version')),
                  subtitle: const Text('1.0.1'),
                  leading: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SoundSection extends StatefulWidget {
  const _SoundSection();

  @override
  State<_SoundSection> createState() => _SoundSectionState();
}

class _SoundSectionState extends State<_SoundSection> {
  final _soundService = SoundService();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadSoundState();
  }

  Future<void> _loadSoundState() async {
    await _soundService.initialize();
    if (mounted) {
      setState(() {
        _isMuted = _soundService.isMuted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          tr('sound_setting'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        trailing: Switch(
          value: !_isMuted,
          onChanged: (value) async {
            await _soundService.setMuted(!value);
            setState(() {
              _isMuted = !value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _GameplaySection extends StatefulWidget {
  const _GameplaySection();

  @override
  State<_GameplaySection> createState() => _GameplaySectionState();
}

class _GameplaySectionState extends State<_GameplaySection> {
  final _gameSettings = GameSettingsService();

  @override
  void initState() {
    super.initState();
    _gameSettings.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ValueListenableBuilder<bool>(
        valueListenable: _gameSettings.dimmingEnabled,
        builder: (context, isDimmingEnabled, _) {
          return ListTile(
            title: Text(
              tr('board_dimming_setting'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: Switch(
              value: isDimmingEnabled,
              onChanged: (value) async {
                await _gameSettings.setDimmingEnabled(value);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final bool isSelected;
  final String label;

  const _ColorOption({
    required this.color,
    required this.borderColor,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ThemeController.setPrimary(color);
        ThemeController.setBorder(borderColor);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

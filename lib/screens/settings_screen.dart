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
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   child: Text(
        //     tr('color_theme_description'),
        //     style: Theme.of(context).textTheme.bodyMedium,
        //   ),
        // ),
        ValueListenableBuilder<Color>(
          valueListenable: ThemeController.primaryColor,
          builder: (context, currentColor, _) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: ThemeController.colorPresets.map((preset) {
                  return _ColorOption(
                    color: preset.primary,
                    borderColor: preset.border,
                    isSelected: currentColor == preset.primary,
                    label: tr(preset.nameKey),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // The rest of this screen only rebuilds when something it directly
    // listens to changes. Without this, section titles (built with bare
    // tr() calls) never re-evaluate on a language change, since this
    // screen isn't otherwise notified - only widgets with their own
    // ValueListenableBuilder on LanguageController.lang are.
    return ValueListenableBuilder<String>(
      valueListenable: LanguageController.lang,
      builder: (context, _, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                      activeThumbColor: Theme.of(context).primaryColor,
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
                    return RadioGroup<String>(
                      groupValue: currentLang,
                      onChanged: (value) {
                        if (value != null) {
                          LanguageController.setAndSave(value);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(tr('language_english')),
                            value: 'en',
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          RadioListTile<String>(
                            title: Text(tr('language_arabic')),
                            value: 'ar',
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
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
          activeThumbColor: Theme.of(context).primaryColor,
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
              activeThumbColor: Theme.of(context).primaryColor,
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
                        color: color.withValues(alpha: 0.5),
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
          // Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:super_xo/screens/start_menu_screen.dart';
import 'package:super_xo/theme/theme_controller.dart';
import 'package:super_xo/theme/app_theme.dart';
import 'package:super_xo/controllers/language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // load persisted settings
  await ThemeController.init();
  await LanguageController.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageController.lang,
      builder: (context, language, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeController.isDark,
          builder: (context, isDark, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: ThemeController.primaryColor,
              builder: (context, primary, _) {
                return ValueListenableBuilder<Color>(
                  valueListenable: ThemeController.borderColor,
                  builder: (context, border, _) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: isDark
                          ? AppTheme.dark(
                              primaryColor: primary,
                              borderColor: border,
                            )
                          : AppTheme.light(
                              primaryColor: primary,
                              borderColor: border,
                            ),
                      home: const StartMenuScreen(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

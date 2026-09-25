import 'package:flutter/material.dart';
import 'data/assets.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    AppSettings.instance.load(),
    preloadAvatar(),
  ]);
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key});

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
    // Colors and strings are read from global getters rather than an
    // InheritedWidget, so `const` subtrees would never notice the change.
    // Marking every element dirty repaints them while keeping their state
    // (scroll position, open quests, carousel page...).
    void markDirty(Element e) {
      e.markNeedsBuild();
      e.visitChildren(markDirty);
    }

    (context as Element).visitChildren(markDirty);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppSettings.instance.isDark;
    return MaterialApp(
      title: 'Daniel Augusto — Mobile Software Engineer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Default text (tooltips, nav labels...) uses a bundled font, so the
        // web build never has to download Roboto.
        fontFamily: 'SpaceMono',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

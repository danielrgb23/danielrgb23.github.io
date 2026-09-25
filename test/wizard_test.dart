import 'package:daniel_portfolio/main.dart';
import 'package:daniel_portfolio/state/app_settings.dart';
import 'package:daniel_portfolio/widgets/pixel_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    AppSettings.instance
      ..isDark = true
      ..lang = AppLang.pt;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PortfolioApp());
  }

  // Sprite-space point -> global position (scale 4, origin at x = -6).
  Offset spritePoint(WidgetTester tester, double x, double y) =>
      tester.getTopLeft(find.byType(PixelWizard)) + Offset((x + 6) * 4, y * 4);

  testWidgets('stealing the coffee switches to light theme + other language',
      (tester) async {
    await pumpApp(tester);
    // Let the wizard get to the sipping part of his loop (cup in hand).
    await tester.pump(const Duration(milliseconds: 6000));

    await tester.tapAt(spritePoint(tester, 2, 15));
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(AppSettings.instance.isDark, isFalse);
    expect(AppSettings.instance.lang, AppLang.en);
    // He says his line in the *new* language.
    expect(find.textContaining('not my coffee'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8)); // speech box goes away
  });

  testWidgets('stealing the staff makes him conjure a new one and speak',
      (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tapAt(spritePoint(tester, 20, 20));
    // The line starts at 62% of the 7 s reaction, then gets typed out.
    for (var i = 0; i < 75; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('ferramentas'), findsOneWidget);
    // Theme and language stay untouched for the staff.
    expect(AppSettings.instance.isDark, isTrue);
    expect(AppSettings.instance.lang, AppLang.pt);

    await tester.pump(const Duration(seconds: 8)); // speech box goes away
  });
}

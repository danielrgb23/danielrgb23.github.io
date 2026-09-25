import 'package:daniel_portfolio/main.dart';
import 'package:daniel_portfolio/state/app_settings.dart';
import 'package:daniel_portfolio/state/game_state.dart';
import 'package:daniel_portfolio/widgets/pixel_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance
      ..isDark = true
      ..lang = AppLang.pt;
    GameState.coins.value = 0;
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
    // The line starts at 72% of the 7 s reaction, then gets typed out.
    for (var i = 0; i < 95; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('ferramentas'), findsOneWidget);
    // Theme and language stay untouched for the staff.
    expect(AppSettings.instance.isDark, isTrue);
    expect(AppSettings.instance.lang, AppLang.pt);

    await tester.pump(const Duration(seconds: 8)); // speech box goes away
  });

  testWidgets('dragging the coffee away in any direction steals it',
      (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 6000)); // cup in hand

    final g = await tester.startGesture(spritePoint(tester, 2, 15));
    await g.moveBy(const Offset(40, 90)); // down and to the right
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(40, 90));
    await tester.pump(const Duration(milliseconds: 50));
    // Still holding: nothing has been triggered yet.
    expect(AppSettings.instance.isDark, isTrue);
    await g.up();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(AppSettings.instance.isDark, isFalse);
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('a short drag only wiggles the staff, it springs back',
      (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 500));

    final g = await tester.startGesture(spritePoint(tester, 20, 20));
    await g.moveBy(const Offset(8, 0)); // ~2 sprite pixels
    await tester.pump(const Duration(milliseconds: 50));
    await g.up();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // No spell, no speech.
    expect(find.textContaining('ferramentas'), findsNothing);
    expect(AppSettings.instance.isDark, isTrue);
  });

  testWidgets('losing the coffee also strikes the coins, which fall',
      (tester) async {
    await pumpApp(tester);
    GameState.coins.value = 5;
    await tester.pump(const Duration(milliseconds: 6000)); // cup in hand

    await tester.tapAt(spritePoint(tester, 2, 15));
    // Spell is cast at 42% of the 7 s reaction (~2.9 s): bolt in flight.
    for (var i = 0; i < 31; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('coin-strike')), findsOneWidget);
    expect(GameState.coins.value, 5, reason: 'not hit yet');

    // The bolt lands and the coins are knocked off the counter.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(GameState.coins.value, 0);
    expect(find.byKey(const ValueKey('coin-strike')), findsOneWidget);

    // Everything cleans itself up.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('coin-strike')), findsNothing);
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('no coins, no strike', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 6000));
    await tester.tapAt(spritePoint(tester, 2, 15));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('coin-strike')), findsNothing);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 8));
  });
}

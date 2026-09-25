import 'package:daniel_portfolio/main.dart';
import 'package:daniel_portfolio/state/app_settings.dart';
import 'package:daniel_portfolio/state/game_state.dart';
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

  testWidgets('clicking the avatar earns a coin (spins) and updates the HUD',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('x00'), findsOneWidget);

    await tester.tap(find.byType(Image));
    await tester.pump(); // the ticker starts on its first frame
    await tester.pump(const Duration(milliseconds: 400)); // mid-spin
    expect(GameState.coins.value, 1);
    expect(find.text('+1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200)); // landed
    expect(find.text('+1'), findsNothing);
    expect(find.text('x01'), findsOneWidget);

    // Tapping again while it is still spinning restarts it and scores again.
    await tester.tap(find.byType(Image));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(Image));
    await tester.pump(const Duration(milliseconds: 100));
    expect(GameState.coins.value, 3);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('10th coin unlocks the collector achievement', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(milliseconds: 300));
    GameState.coins.value = GameState.collectorGoal - 1;

    await tester.tap(find.byType(Image));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Colecionador'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}

import 'package:daniel_portfolio/main.dart';
import 'package:daniel_portfolio/state/app_settings.dart';
import 'package:daniel_portfolio/widgets/book_switch.dart';
import 'package:daniel_portfolio/widgets/lamp_switch.dart';
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

  testWidgets('lamp toggles theme, book toggles language', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MISSÕES'), findsWidgets);

    await tester.tap(find.byType(LampSwitch));
    // Step frame by frame: the tap is async (chain pull, then toggle).
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(AppSettings.instance.isDark, isFalse);

    await tester.tap(find.byType(BookSwitch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    expect(AppSettings.instance.lang, AppLang.en);
    expect(find.text('QUESTS'), findsWidgets);
    expect(find.text('MISSÕES'), findsNothing);

    await tester.pump(const Duration(seconds: 5)); // let toasts expire
  });
}

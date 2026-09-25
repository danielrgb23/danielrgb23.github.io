import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { pt, en }

/// Global, persisted user preferences (theme + language).
///
/// Colors and strings are read through [AppColors] / [S], which look at this
/// singleton, so a change here needs the widget tree to rebuild (see
/// `PortfolioApp`).
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  static const _kDark = 'isDark';
  static const _kLang = 'lang';

  bool isDark = true;
  AppLang lang = ui.PlatformDispatcher.instance.locale.languageCode == 'pt'
      ? AppLang.pt
      : AppLang.en;

  bool get isEn => lang == AppLang.en;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDark = prefs.getBool(_kDark) ?? isDark;
      final saved = prefs.getString(_kLang);
      if (saved != null) {
        lang = AppLang.values.firstWhere(
          (l) => l.name == saved,
          orElse: () => lang,
        );
      }
    } catch (_) {
      // Storage unavailable (private mode, etc.): keep defaults.
    }
  }

  /// Changes several settings at once with a single rebuild.
  void apply({bool? dark, AppLang? lang}) {
    final nextDark = dark ?? isDark;
    final nextLang = lang ?? this.lang;
    if (nextDark == isDark && nextLang == this.lang) return;
    isDark = nextDark;
    this.lang = nextLang;
    notifyListeners();
    _save();
  }

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
    _save();
  }

  void toggleLang() {
    lang = isEn ? AppLang.pt : AppLang.en;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDark, isDark);
      await prefs.setString(_kLang, lang.name);
    } catch (_) {}
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations extends ChangeNotifier {
  static const _langKey = 'app_language';
  static const _supportedLocales = ['en', 'ru', 'tk'];

  String _locale = 'en';
  Map<String, String> _strings = {};

  String get locale => _locale;

  static AppLocalizations? _instance;
  static AppLocalizations get instance {
    _instance ??= AppLocalizations._();
    return _instance!;
  }

  AppLocalizations._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_langKey) ?? 'en';
    if (!_supportedLocales.contains(_locale)) _locale = 'en';
    await _load(_locale);
  }

  Future<void> setLocale(String locale) async {
    if (!_supportedLocales.contains(locale)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale);
    await _load(locale);
    notifyListeners();
  }

  Future<void> _load(String locale) async {
    final raw = await rootBundle.loadString('assets/l10n/$locale.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    _strings = map.map((k, v) => MapEntry(k, v.toString()));
  }

  String t(String key) => _strings[key] ?? key;

  static List<String> get supportedLocales => _supportedLocales;
}

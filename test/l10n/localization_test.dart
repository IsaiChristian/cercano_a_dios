import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/l10n/app_localizations_en.dart';
import 'package:cercano_a_dios/l10n/app_localizations_es.dart';

void main() {
  test(
    'English remains the source locale and Spanish translates core copy',
    () {
      final en = AppLocalizationsEn();
      final es = AppLocalizationsEs();
      expect(en.beginMoment, 'Begin a moment');
      expect(es.beginMoment, 'Comenzar un momento');
      expect(es.daysStreak(3), 'Racha de 3 días');
      expect(es.promptTextP01, contains('Señor'));
    },
  );

  test('Flutter declares only locales with generated translations', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';

void main() {
  test('English remains the source locale and Spanish translates core copy', () {
    const en = AppLocalizations(Locale('en'));
    const es = AppLocalizations(Locale('es'));
    expect(en.t('beginMoment'), 'Begin a moment');
    expect(es.t('beginMoment'), 'Comenzar un momento');
    expect(es.t('daysStreak', {'count': 3}), 'Racha de 3 días');
    expect(es.t('promptTextP01'), contains('Señor'));
  });

  test('unsupported locales fall back to English', () {
    const fr = AppLocalizations(Locale('fr'));
    expect(fr.t('settings'), 'Settings');
  });
}

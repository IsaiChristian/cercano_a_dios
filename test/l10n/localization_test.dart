import 'package:flutter_test/flutter_test.dart';

import 'package:cercano_a_dios/l10n/app_localizations_en.dart';
import 'package:cercano_a_dios/l10n/app_localizations_es.dart';

void main() {
  group('Privacy Copy Assertions', () {
    test(
      'English privacy copy mentions Appwrite handles account but prayers remain local',
      () {
        final en = AppLocalizationsEn();
        expect(
          en.privacyDescription,
          contains('Appwrite securely handles your account and session.'),
        );
        expect(en.privacyDescription, contains('are never uploaded'));
      },
    );

    test(
      'Spanish privacy copy mentions Appwrite handles account but prayers remain local',
      () {
        final es = AppLocalizationsEs();
        expect(
          es.privacyDescription,
          contains('Appwrite maneja tu cuenta y sesión de forma segura.'),
        );
        expect(es.privacyDescription, contains('nunca se suben'));
      },
    );
  });
}

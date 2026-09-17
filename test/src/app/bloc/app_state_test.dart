import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

void main() {
  test('copyWith updates only supplied state values', () {
    final original = AppState(
      locale: const Locale('es'),
      sessions: const [],
      reminders: const [],
      loading: true,
      error: 'old',
      audioBytes: 10,
      onboardingComplete: true,
    );

    final updated = original.copyWith(
      locale: const Locale('fr'),
      audioBytes: 42,
    );

    expect(updated.locale, const Locale('fr'));
    expect(updated.sessions, isEmpty);
    expect(updated.reminders, isEmpty);
    expect(updated.loading, isTrue);
    expect(updated.error, 'old');
    expect(updated.audioBytes, 42);
    expect(updated.onboardingComplete, isTrue);
  });

  group('AppState locale resolution', () {
    test('resolveLocale maps supported and regional locales properly', () {
      expect(AppState.resolveLocale(const Locale('es')), const Locale('es'));
      expect(
        AppState.resolveLocale(const Locale('es', 'ES')),
        const Locale('es'),
      );
      expect(
        AppState.resolveLocale(const Locale('es', 'MX')),
        const Locale('es'),
      );
      expect(AppState.resolveLocale(const Locale('en')), const Locale('en'));
      expect(
        AppState.resolveLocale(const Locale('en', 'US')),
        const Locale('en'),
      );
      expect(
        AppState.resolveLocale(const Locale('en', 'GB')),
        const Locale('en'),
      );
      expect(AppState.resolveLocale(const Locale('fr')), const Locale('en'));
      expect(
        AppState.resolveLocale(const Locale('de', 'DE')),
        const Locale('en'),
      );
      expect(AppState.resolveLocale(null), const Locale('en'));
    });

    test(
      'resolveInitialLocale prioritizes valid persisted code over device locale',
      () {
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: 'es',
            deviceLocale: const Locale('en'),
          ),
          const Locale('es'),
        );
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: 'en',
            deviceLocale: const Locale('es'),
          ),
          const Locale('en'),
        );
      },
    );

    test(
      'resolveInitialLocale falls back to device locale when persisted code is absent or invalid',
      () {
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: null,
            deviceLocale: const Locale('es'),
          ),
          const Locale('es'),
        );
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: '   ',
            deviceLocale: const Locale('es'),
          ),
          const Locale('es'),
        );
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: 'fr',
            deviceLocale: const Locale('es'),
          ),
          const Locale('es'),
        );
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: 'invalid',
            deviceLocale: const Locale('en'),
          ),
          const Locale('en'),
        );
      },
    );

    test(
      'resolveInitialLocale falls back to default English when device locale is unsupported or null',
      () {
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: null,
            deviceLocale: const Locale('fr'),
          ),
          const Locale('en'),
        );
        expect(
          AppState.resolveInitialLocale(
            persistedLanguageCode: null,
            deviceLocale: null,
          ),
          const Locale('en'),
        );
      },
    );
  });
}

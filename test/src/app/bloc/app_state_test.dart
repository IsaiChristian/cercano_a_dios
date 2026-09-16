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
}

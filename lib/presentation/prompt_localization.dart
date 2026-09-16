import 'package:flutter/widgets.dart';

import '../../domain/entities/prayer.dart';
import '../../l10n/app_localizations.dart';

PrayerPrompt localizedPrompt(BuildContext context, PrayerPrompt prompt) {
  final localizations = AppLocalizations.of(context)!;
  return PrayerPrompt(
    prompt.id,
    _promptTitles(localizations)[_promptIndex(prompt.id)],
    _promptTexts(localizations)[_promptIndex(prompt.id)],
    _promptCategory(localizations, prompt.category),
  );
}

int _promptIndex(String id) {
  final number = int.tryParse(id.substring(1)) ?? 1;
  return (number - 1).clamp(0, 19);
}

List<String> _promptTitles(AppLocalizations localizations) => [
  localizations.promptTitleP01,
  localizations.promptTitleP02,
  localizations.promptTitleP03,
  localizations.promptTitleP04,
  localizations.promptTitleP05,
  localizations.promptTitleP06,
  localizations.promptTitleP07,
  localizations.promptTitleP08,
  localizations.promptTitleP09,
  localizations.promptTitleP10,
  localizations.promptTitleP11,
  localizations.promptTitleP12,
  localizations.promptTitleP13,
  localizations.promptTitleP14,
  localizations.promptTitleP15,
  localizations.promptTitleP16,
  localizations.promptTitleP17,
  localizations.promptTitleP18,
  localizations.promptTitleP19,
  localizations.promptTitleP20,
];

List<String> _promptTexts(AppLocalizations localizations) => [
  localizations.promptTextP01,
  localizations.promptTextP02,
  localizations.promptTextP03,
  localizations.promptTextP04,
  localizations.promptTextP05,
  localizations.promptTextP06,
  localizations.promptTextP07,
  localizations.promptTextP08,
  localizations.promptTextP09,
  localizations.promptTextP10,
  localizations.promptTextP11,
  localizations.promptTextP12,
  localizations.promptTextP13,
  localizations.promptTextP14,
  localizations.promptTextP15,
  localizations.promptTextP16,
  localizations.promptTextP17,
  localizations.promptTextP18,
  localizations.promptTextP19,
  localizations.promptTextP20,
];

String _promptCategory(AppLocalizations localizations, String category) =>
    switch (category) {
      'Morning' => localizations.promptCategoryMorning,
      'Gratitude' => localizations.promptCategoryGratitude,
      'Peace' => localizations.promptCategoryPeace,
      'Family' => localizations.promptCategoryFamily,
      'Hope' => localizations.promptCategoryHope,
      'Service' => localizations.promptCategoryService,
      'Faith' => localizations.promptCategoryFaith,
      'Evening' => localizations.promptCategoryEvening,
      _ => category,
    };

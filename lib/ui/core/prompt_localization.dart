import 'package:flutter/widgets.dart';

import '../../domain/entities/prayer.dart';
import '../../l10n/app_localizations.dart';

PrayerPrompt localizedPrompt(BuildContext context, PrayerPrompt prompt) {
  final localizations = AppLocalizations.of(context)!;
  final suffix = prompt.id.substring(1).toUpperCase();
  return PrayerPrompt(
    prompt.id,
    localizations.t('promptTitleP$suffix'),
    localizations.t('promptTextP$suffix'),
    localizations.t('promptCategory${prompt.category}'),
  );
}

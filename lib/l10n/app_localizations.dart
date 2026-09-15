import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Cercano a Dios'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cercano\na Dios'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Make a little space for prayer.\nGive thanks. Speak from the heart.\nReturn tomorrow.'**
  String get welcomeBody;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'A little closer, every day'**
  String get onboardingTagline;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Make room\nfor God.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet moment. A grateful heart. A new beginning.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'A private Catholic prayer companion. Your voice and your journey stay on this device.'**
  String get onboardingPrivacy;

  /// No description provided for @beginJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin my journey'**
  String get beginJourney;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Your milestones'**
  String get milestones;

  /// No description provided for @beginMoment.
  ///
  /// In en, this message translates to:
  /// **'Begin a moment'**
  String get beginMoment;

  /// No description provided for @yourRhythm.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get yourRhythm;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(int count);

  /// No description provided for @daysStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String daysStreak(int count);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @todayComplete.
  ///
  /// In en, this message translates to:
  /// **'You made time for prayer today.'**
  String get todayComplete;

  /// No description provided for @todayIncomplete.
  ///
  /// In en, this message translates to:
  /// **'One small moment is enough to begin.'**
  String get todayIncomplete;

  /// No description provided for @weekProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of 7 days this week'**
  String weekProgress(int count);

  /// No description provided for @gentleInvitation.
  ///
  /// In en, this message translates to:
  /// **'A gentle invitation'**
  String get gentleInvitation;

  /// No description provided for @makePrayerPart.
  ///
  /// In en, this message translates to:
  /// **'Make prayer part of your day.'**
  String get makePrayerPart;

  /// No description provided for @setFirstAlarm.
  ///
  /// In en, this message translates to:
  /// **'Set your first alarm'**
  String get setFirstAlarm;

  /// No description provided for @manageAlarms.
  ///
  /// In en, this message translates to:
  /// **'Manage your alarms'**
  String get manageAlarms;

  /// No description provided for @moreWays.
  ///
  /// In en, this message translates to:
  /// **'More ways to pray'**
  String get moreWays;

  /// No description provided for @prayerMoment.
  ///
  /// In en, this message translates to:
  /// **'Your prayer moment'**
  String get prayerMoment;

  /// No description provided for @beStill.
  ///
  /// In en, this message translates to:
  /// **'Be still for a moment'**
  String get beStill;

  /// No description provided for @usePrayerBeginning.
  ///
  /// In en, this message translates to:
  /// **'Use this prayer as a beginning, then speak in your own words.'**
  String get usePrayerBeginning;

  /// No description provided for @voiceStaysDevice.
  ///
  /// In en, this message translates to:
  /// **'Your voice stays on this device. You can listen again or delete it at any time.'**
  String get voiceStaysDevice;

  /// No description provided for @speakPrayer.
  ///
  /// In en, this message translates to:
  /// **'Speak my prayer'**
  String get speakPrayer;

  /// No description provided for @silentMoment.
  ///
  /// In en, this message translates to:
  /// **'Complete a silent moment'**
  String get silentMoment;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording · {time}'**
  String recording(String time);

  /// No description provided for @finishRecording.
  ///
  /// In en, this message translates to:
  /// **'Finish recording'**
  String get finishRecording;

  /// No description provided for @recordingLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to two minutes. Tap Finish whenever you are ready.'**
  String get recordingLimit;

  /// No description provided for @yourRecording.
  ///
  /// In en, this message translates to:
  /// **'Your recording · {seconds}s'**
  String yourRecording(int seconds);

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get stopPlayback;

  /// No description provided for @saveComplete.
  ///
  /// In en, this message translates to:
  /// **'Save and complete'**
  String get saveComplete;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @completeWithoutAudio.
  ///
  /// In en, this message translates to:
  /// **'Complete without audio'**
  String get completeWithoutAudio;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get leaveWithoutSaving;

  /// No description provided for @momentWellSpent.
  ///
  /// In en, this message translates to:
  /// **'A moment well spent.'**
  String get momentWellSpent;

  /// No description provided for @prayerSaved.
  ///
  /// In en, this message translates to:
  /// **'Your prayer has been saved.\n{count} day streak.'**
  String prayerSaved(int count);

  /// No description provided for @newMilestone.
  ///
  /// In en, this message translates to:
  /// **'A new milestone on your journey. Find your new badge in Your progress.'**
  String get newMilestone;

  /// No description provided for @returnToday.
  ///
  /// In en, this message translates to:
  /// **'Return to today'**
  String get returnToday;

  /// No description provided for @recordingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingPrivacy;

  /// No description provided for @recordingStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Recording storage is full. Free some space in Settings or reflect silently.'**
  String get recordingStorageFull;

  /// No description provided for @recordingStartError.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. You can still reflect silently.'**
  String get recordingStartError;

  /// No description provided for @recordingReviewError.
  ///
  /// In en, this message translates to:
  /// **'Recording was interrupted. Try playback, record again, or complete without audio.'**
  String get recordingReviewError;

  /// No description provided for @recordingPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Could not play this recording. Please record again or complete without audio.'**
  String get recordingPlaybackError;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save this moment. Please try again.'**
  String get saveError;

  /// No description provided for @alarmTime.
  ///
  /// In en, this message translates to:
  /// **'A time for prayer'**
  String get alarmTime;

  /// No description provided for @alarmBody.
  ///
  /// In en, this message translates to:
  /// **'Pause and give thanks with Cercano a Dios.'**
  String get alarmBody;

  /// No description provided for @makeSpace.
  ///
  /// In en, this message translates to:
  /// **'Make a little space'**
  String get makeSpace;

  /// No description provided for @prayerTime.
  ///
  /// In en, this message translates to:
  /// **'A time for prayer.'**
  String get prayerTime;

  /// No description provided for @soundReminderMode.
  ///
  /// In en, this message translates to:
  /// **'Sound reminder mode'**
  String get soundReminderMode;

  /// No description provided for @soundReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'This iPhone supports notification reminders, not persistent ringing alarms. Sound follows your notification and Focus settings. Continue with a reminder?'**
  String get soundReminderDescription;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nextAlarm.
  ///
  /// In en, this message translates to:
  /// **'Next: {date} at {time}'**
  String nextAlarm(String date, String time);

  /// No description provided for @setupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Setup incomplete — tap Edit to retry'**
  String get setupIncomplete;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Device permission needed'**
  String get permissionNeeded;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'Add a prayer time'**
  String get addPrayerTime;

  /// No description provided for @upToFive.
  ///
  /// In en, this message translates to:
  /// **'Up to five prayer times.'**
  String get upToFive;

  /// No description provided for @testAlarm.
  ///
  /// In en, this message translates to:
  /// **'Test in 10 seconds'**
  String get testAlarm;

  /// No description provided for @stopAlarmNote.
  ///
  /// In en, this message translates to:
  /// **'Stop always silences the alarm. You never need to record a prayer to dismiss it.'**
  String get stopAlarmNote;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open device settings'**
  String get openSettings;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Moments to remember.'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private record of the time you made for God.'**
  String get journalSubtitle;

  /// No description provided for @firstMomentHint.
  ///
  /// In en, this message translates to:
  /// **'Your first moment will appear here. Begin a prayer from Today.'**
  String get firstMomentHint;

  /// No description provided for @spokenPrayer.
  ///
  /// In en, this message translates to:
  /// **'Spoken prayer'**
  String get spokenPrayer;

  /// No description provided for @silentReflection.
  ///
  /// In en, this message translates to:
  /// **'Silent reflection'**
  String get silentReflection;

  /// No description provided for @deleteRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recording?'**
  String get deleteRecordingTitle;

  /// No description provided for @deleteRecordingDescription.
  ///
  /// In en, this message translates to:
  /// **'Your completed moment and streak will stay.'**
  String get deleteRecordingDescription;

  /// No description provided for @deleteMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this moment?'**
  String get deleteMomentTitle;

  /// No description provided for @deleteMomentDescription.
  ///
  /// In en, this message translates to:
  /// **'Its recording will be removed and your progress will be recalculated.'**
  String get deleteMomentDescription;

  /// No description provided for @loadEarlier.
  ///
  /// In en, this message translates to:
  /// **'Load earlier moments'**
  String get loadEarlier;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep showing up.'**
  String get progressTitle;

  /// No description provided for @smallMoments.
  ///
  /// In en, this message translates to:
  /// **'Small moments add up'**
  String get smallMoments;

  /// No description provided for @bestAndMoments.
  ///
  /// In en, this message translates to:
  /// **'Best: {best} days · {total} moments'**
  String bestAndMoments(int best, int total);

  /// No description provided for @milestoneReached.
  ///
  /// In en, this message translates to:
  /// **'A milestone reached'**
  String get milestoneReached;

  /// No description provided for @oneMoment.
  ///
  /// In en, this message translates to:
  /// **'One moment at a time'**
  String get oneMoment;

  /// No description provided for @progressDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These milestones celebrate your practice. They do not measure your faith. A missed day is always an invitation to begin again.'**
  String get progressDisclaimer;

  /// No description provided for @spaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple. Private. Yours.'**
  String get spaceTitle;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'{used} MB of 100 MB'**
  String storageUsage(String used);

  /// No description provided for @storageNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Your recordings are nearing the limit. You can free space without losing your streak.'**
  String get storageNearLimit;

  /// No description provided for @storagePrivate.
  ///
  /// In en, this message translates to:
  /// **'Your voice recordings stay on this device.'**
  String get storagePrivate;

  /// No description provided for @deleteAllRecordings.
  ///
  /// In en, this message translates to:
  /// **'Delete all recordings'**
  String get deleteAllRecordings;

  /// No description provided for @deleteAllRecordingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all recordings?'**
  String get deleteAllRecordingsTitle;

  /// No description provided for @deleteAllRecordingsDescription.
  ///
  /// In en, this message translates to:
  /// **'All audio will be deleted. Completed moments, streaks and badges stay.'**
  String get deleteAllRecordingsDescription;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Microphone and alarm access'**
  String get permissionLabel;

  /// No description provided for @aboutData.
  ///
  /// In en, this message translates to:
  /// **'About your data'**
  String get aboutData;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'No account. No uploads. No ads. Your prayers are stored privately on this device. Uninstalling the app or losing the device can remove your history and recordings.'**
  String get privacyDescription;

  /// No description provided for @timezoneNote.
  ///
  /// In en, this message translates to:
  /// **'Streaks use the local date when a moment is completed. Travel across time zones may skip a day or repeat one. You can always begin again.'**
  String get timezoneNote;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get startFresh;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Cercano a Dios?'**
  String get resetTitle;

  /// No description provided for @resetDescription.
  ///
  /// In en, this message translates to:
  /// **'This deletes your history, audio, alarms, streaks and badges from this device. It cannot be undone.'**
  String get resetDescription;

  /// No description provided for @deleteAppData.
  ///
  /// In en, this message translates to:
  /// **'Delete all app data'**
  String get deleteAppData;

  /// No description provided for @footer.
  ///
  /// In en, this message translates to:
  /// **'Cercano a Dios · 0.1.0\nA little closer, every day.'**
  String get footer;

  /// No description provided for @badgeFirst.
  ///
  /// In en, this message translates to:
  /// **'First moment'**
  String get badgeFirst;

  /// No description provided for @badgeStreak3.
  ///
  /// In en, this message translates to:
  /// **'Three faithful days'**
  String get badgeStreak3;

  /// No description provided for @badgeStreak7.
  ///
  /// In en, this message translates to:
  /// **'A week of prayer'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak30.
  ///
  /// In en, this message translates to:
  /// **'Thirty days together'**
  String get badgeStreak30;

  /// No description provided for @badgeTotal10.
  ///
  /// In en, this message translates to:
  /// **'Ten moments'**
  String get badgeTotal10;

  /// No description provided for @badgeTotal50.
  ///
  /// In en, this message translates to:
  /// **'Fifty moments'**
  String get badgeTotal50;

  /// No description provided for @badgeMilestoneDescription.
  ///
  /// In en, this message translates to:
  /// **'A milestone reached'**
  String get badgeMilestoneDescription;

  /// No description provided for @badgeLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'One moment at a time'**
  String get badgeLockedDescription;

  /// No description provided for @promptTitleP01.
  ///
  /// In en, this message translates to:
  /// **'For this new day'**
  String get promptTitleP01;

  /// No description provided for @promptTextP01.
  ///
  /// In en, this message translates to:
  /// **'Lord, thank you for this new day. Help me receive it with an open heart.'**
  String get promptTextP01;

  /// No description provided for @promptTitleP02.
  ///
  /// In en, this message translates to:
  /// **'A small gift'**
  String get promptTitleP02;

  /// No description provided for @promptTextP02.
  ///
  /// In en, this message translates to:
  /// **'Heavenly Father, today I am grateful for ___. Help me notice your gifts in ordinary things.'**
  String get promptTextP02;

  /// No description provided for @promptTitleP03.
  ///
  /// In en, this message translates to:
  /// **'A peaceful heart'**
  String get promptTitleP03;

  /// No description provided for @promptTextP03.
  ///
  /// In en, this message translates to:
  /// **'Jesus, meet me in my worries. Teach me to trust you one small step at a time.'**
  String get promptTextP03;

  /// No description provided for @promptTitleP04.
  ///
  /// In en, this message translates to:
  /// **'For those I love'**
  String get promptTitleP04;

  /// No description provided for @promptTextP04.
  ///
  /// In en, this message translates to:
  /// **'Lord, bless the people I love. Help me show them patience and kindness today.'**
  String get promptTextP04;

  /// No description provided for @promptTitleP05.
  ///
  /// In en, this message translates to:
  /// **'An evening pause'**
  String get promptTitleP05;

  /// No description provided for @promptTextP05.
  ///
  /// In en, this message translates to:
  /// **'Father, thank you for walking with me today. I place this day in your hands.'**
  String get promptTextP05;

  /// No description provided for @promptTitleP06.
  ///
  /// In en, this message translates to:
  /// **'Begin again'**
  String get promptTitleP06;

  /// No description provided for @promptTextP06.
  ///
  /// In en, this message translates to:
  /// **'Merciful Jesus, help me begin again when I fall short, and lead me toward what is good.'**
  String get promptTextP06;

  /// No description provided for @promptTitleP07.
  ///
  /// In en, this message translates to:
  /// **'A generous spirit'**
  String get promptTitleP07;

  /// No description provided for @promptTextP07.
  ///
  /// In en, this message translates to:
  /// **'Lord, show me someone I can help today. Make me generous with my time and attention.'**
  String get promptTextP07;

  /// No description provided for @promptTitleP08.
  ///
  /// In en, this message translates to:
  /// **'For daily bread'**
  String get promptTitleP08;

  /// No description provided for @promptTextP08.
  ///
  /// In en, this message translates to:
  /// **'Father, thank you for the food and shelter I have. Keep those in need close to my heart.'**
  String get promptTextP08;

  /// No description provided for @promptTitleP09.
  ///
  /// In en, this message translates to:
  /// **'In the quiet'**
  String get promptTitleP09;

  /// No description provided for @promptTextP09.
  ///
  /// In en, this message translates to:
  /// **'Holy Spirit, quiet the noise within me. Help me listen with a willing heart.'**
  String get promptTextP09;

  /// No description provided for @promptTitleP10.
  ///
  /// In en, this message translates to:
  /// **'For my work'**
  String get promptTitleP10;

  /// No description provided for @promptTextP10.
  ///
  /// In en, this message translates to:
  /// **'Jesus, guide the work of my hands. May I serve others with honesty and care.'**
  String get promptTextP10;

  /// No description provided for @promptTitleP11.
  ///
  /// In en, this message translates to:
  /// **'When I am tired'**
  String get promptTitleP11;

  /// No description provided for @promptTextP11.
  ///
  /// In en, this message translates to:
  /// **'Lord, I bring you my tiredness. Help me rest and receive the care I need.'**
  String get promptTextP11;

  /// No description provided for @promptTitleP12.
  ///
  /// In en, this message translates to:
  /// **'A grateful memory'**
  String get promptTitleP12;

  /// No description provided for @promptTextP12.
  ///
  /// In en, this message translates to:
  /// **'Father, thank you for a moment of joy I remember today: ___.'**
  String get promptTextP12;

  /// No description provided for @promptTitleP13.
  ///
  /// In en, this message translates to:
  /// **'The gift of friendship'**
  String get promptTitleP13;

  /// No description provided for @promptTextP13.
  ///
  /// In en, this message translates to:
  /// **'Lord, thank you for those who walk beside me. Help me be a faithful friend.'**
  String get promptTextP13;

  /// No description provided for @promptTitleP14.
  ///
  /// In en, this message translates to:
  /// **'For forgiveness'**
  String get promptTitleP14;

  /// No description provided for @promptTextP14.
  ///
  /// In en, this message translates to:
  /// **'Merciful Father, give me courage to seek forgiveness and grace to forgive others.'**
  String get promptTextP14;

  /// No description provided for @promptTitleP15.
  ///
  /// In en, this message translates to:
  /// **'With Mary'**
  String get promptTitleP15;

  /// No description provided for @promptTextP15.
  ///
  /// In en, this message translates to:
  /// **'Mary, Mother of Jesus, pray for me as I seek to follow your Son today.'**
  String get promptTextP15;

  /// No description provided for @promptTitleP16.
  ///
  /// In en, this message translates to:
  /// **'A patient response'**
  String get promptTitleP16;

  /// No description provided for @promptTextP16.
  ///
  /// In en, this message translates to:
  /// **'Holy Spirit, help me pause before I speak. Let my words carry patience and truth.'**
  String get promptTextP16;

  /// No description provided for @promptTitleP17.
  ///
  /// In en, this message translates to:
  /// **'For the lonely'**
  String get promptTitleP17;

  /// No description provided for @promptTextP17.
  ///
  /// In en, this message translates to:
  /// **'Jesus, draw near to those who feel alone. Show me how to offer companionship.'**
  String get promptTextP17;

  /// No description provided for @promptTitleP18.
  ///
  /// In en, this message translates to:
  /// **'Trust in uncertainty'**
  String get promptTitleP18;

  /// No description provided for @promptTextP18.
  ///
  /// In en, this message translates to:
  /// **'Father, I do not know everything this day will bring. Help me take the next good step.'**
  String get promptTextP18;

  /// No description provided for @promptTitleP19.
  ///
  /// In en, this message translates to:
  /// **'For creation'**
  String get promptTitleP19;

  /// No description provided for @promptTextP19.
  ///
  /// In en, this message translates to:
  /// **'Lord, thank you for the beauty of your creation. Teach me to care for our common home.'**
  String get promptTextP19;

  /// No description provided for @promptTitleP20.
  ///
  /// In en, this message translates to:
  /// **'A simple offering'**
  String get promptTitleP20;

  /// No description provided for @promptTextP20.
  ///
  /// In en, this message translates to:
  /// **'Jesus, I offer you this small moment. Help me grow in faith, hope, and love.'**
  String get promptTextP20;

  /// No description provided for @appOpenError.
  ///
  /// In en, this message translates to:
  /// **'We could not open your prayer journal.'**
  String get appOpenError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @soundReminders.
  ///
  /// In en, this message translates to:
  /// **'Sound reminders on this iPhone'**
  String get soundReminders;

  /// No description provided for @ringingAlarms.
  ///
  /// In en, this message translates to:
  /// **'Ringing alarms with Stop and Snooze'**
  String get ringingAlarms;

  /// No description provided for @deviceAccess.
  ///
  /// In en, this message translates to:
  /// **'Device access: {permission}'**
  String deviceAccess(Object permission);

  /// No description provided for @listenDuration.
  ///
  /// In en, this message translates to:
  /// **'Listen · {seconds}s'**
  String listenDuration(Object seconds);

  /// No description provided for @deleteAudioKeepMoment.
  ///
  /// In en, this message translates to:
  /// **'Delete audio, keep moment'**
  String get deleteAudioKeepMoment;

  /// No description provided for @deleteMoment.
  ///
  /// In en, this message translates to:
  /// **'Delete moment'**
  String get deleteMoment;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'not completed'**
  String get notCompleted;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String durationSeconds(Object seconds);

  /// No description provided for @promptCategoryMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get promptCategoryMorning;

  /// No description provided for @promptCategoryGratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get promptCategoryGratitude;

  /// No description provided for @promptCategoryPeace.
  ///
  /// In en, this message translates to:
  /// **'Peace'**
  String get promptCategoryPeace;

  /// No description provided for @promptCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get promptCategoryFamily;

  /// No description provided for @promptCategoryHope.
  ///
  /// In en, this message translates to:
  /// **'Hope'**
  String get promptCategoryHope;

  /// No description provided for @promptCategoryService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get promptCategoryService;

  /// No description provided for @promptCategoryFaith.
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get promptCategoryFaith;

  /// No description provided for @microphoneLevel.
  ///
  /// In en, this message translates to:
  /// **'Microphone sound level'**
  String get microphoneLevel;

  /// No description provided for @promptCategoryEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get promptCategoryEvening;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

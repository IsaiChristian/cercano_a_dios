// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cercano a Dios';

  @override
  String get welcomeTitle => 'Cercano\na Dios';

  @override
  String get welcomeBody =>
      'Make a little space for prayer.\nGive thanks. Speak from the heart.\nReturn tomorrow.';

  @override
  String get onboardingTagline => 'A little closer, every day';

  @override
  String get onboardingTitle => 'Make room\nfor God.';

  @override
  String get onboardingSubtitle =>
      'A quiet moment. A grateful heart. A new beginning.';

  @override
  String get onboardingPrivacy =>
      'A private Catholic prayer companion. Your voice and your journey stay on this device.';

  @override
  String get beginJourney => 'Begin my journey';

  @override
  String get today => 'Today';

  @override
  String get alarms => 'Alarms';

  @override
  String get journal => 'Journal';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get milestones => 'Your milestones';

  @override
  String get beginMoment => 'Begin a moment';

  @override
  String get yourRhythm => 'Your rhythm';

  @override
  String dayStreak(int count) {
    return '$count day streak';
  }

  @override
  String daysStreak(int count) {
    return '$count day streak';
  }

  @override
  String get view => 'View';

  @override
  String get todayComplete => 'You made time for prayer today.';

  @override
  String get todayIncomplete => 'One small moment is enough to begin.';

  @override
  String weekProgress(int count) {
    return '$count of 7 days this week';
  }

  @override
  String get gentleInvitation => 'A gentle invitation';

  @override
  String get makePrayerPart => 'Make prayer part of your day.';

  @override
  String get setFirstAlarm => 'Set your first alarm';

  @override
  String get manageAlarms => 'Manage your alarms';

  @override
  String get moreWays => 'More ways to pray';

  @override
  String get prayerMoment => 'Your prayer moment';

  @override
  String get beStill => 'Be still for a moment';

  @override
  String get usePrayerBeginning =>
      'Use this prayer as a beginning, then speak in your own words.';

  @override
  String get voiceStaysDevice =>
      'Your voice stays on this device. You can listen again or delete it at any time.';

  @override
  String get speakPrayer => 'Speak my prayer';

  @override
  String get silentMoment => 'Complete a silent moment';

  @override
  String recording(String time) {
    return 'Recording · $time';
  }

  @override
  String get finishRecording => 'Finish recording';

  @override
  String get recordingLimit =>
      'Up to two minutes. Tap Finish whenever you are ready.';

  @override
  String yourRecording(int seconds) {
    return 'Your recording · ${seconds}s';
  }

  @override
  String get listen => 'Listen';

  @override
  String get stopPlayback => 'Stop playback';

  @override
  String get saveComplete => 'Save and complete';

  @override
  String get recordAgain => 'Record again';

  @override
  String get completeWithoutAudio => 'Complete without audio';

  @override
  String get leaveWithoutSaving => 'Leave without saving';

  @override
  String get momentWellSpent => 'A moment well spent.';

  @override
  String prayerSaved(int count) {
    return 'Your prayer has been saved.\n$count day streak.';
  }

  @override
  String get newMilestone =>
      'A new milestone on your journey. Find your new badge in Your progress.';

  @override
  String get returnToday => 'Return to today';

  @override
  String get recordingPrivacy => 'Recording';

  @override
  String get recordingStorageFull =>
      'Recording storage is full. Free some space in Settings or reflect silently.';

  @override
  String get recordingStartError =>
      'Could not start recording. You can still reflect silently.';

  @override
  String get recordingReviewError =>
      'Recording was interrupted. Try playback, record again, or complete without audio.';

  @override
  String get recordingPlaybackError =>
      'Could not play this recording. Please record again or complete without audio.';

  @override
  String get saveError => 'Could not save this moment. Please try again.';

  @override
  String get alarmTime => 'A time for prayer';

  @override
  String get alarmBody => 'Pause and give thanks with Cercano a Dios.';

  @override
  String get makeSpace => 'Make a little space';

  @override
  String get prayerTime => 'A time for prayer.';

  @override
  String get soundReminderMode => 'Sound reminder mode';

  @override
  String get soundReminderDescription =>
      'This iPhone supports notification reminders, not persistent ringing alarms. Sound follows your notification and Focus settings. Continue with a reminder?';

  @override
  String get continueAction => 'Continue';

  @override
  String get repeatOn => 'Repeat on';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String nextAlarm(String date, String time) {
    return 'Next: $date at $time';
  }

  @override
  String get setupIncomplete => 'Setup incomplete — tap Edit to retry';

  @override
  String get paused => 'Paused';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get permissionNeeded => 'Device permission needed';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get addPrayerTime => 'Add a prayer time';

  @override
  String get upToFive => 'Up to five prayer times.';

  @override
  String get testAlarm => 'Test in 10 seconds';

  @override
  String get stopAlarmNote =>
      'Stop always silences the alarm. You never need to record a prayer to dismiss it.';

  @override
  String get openSettings => 'Open device settings';

  @override
  String get journalTitle => 'Moments to remember.';

  @override
  String get journalSubtitle =>
      'A private record of the time you made for God.';

  @override
  String get firstMomentHint =>
      'Your first moment will appear here. Begin a prayer from Today.';

  @override
  String get spokenPrayer => 'Spoken prayer';

  @override
  String get silentReflection => 'Silent reflection';

  @override
  String get deleteRecordingTitle => 'Delete recording?';

  @override
  String get deleteRecordingDescription =>
      'Your completed moment and streak will stay.';

  @override
  String get deleteMomentTitle => 'Delete this moment?';

  @override
  String get deleteMomentDescription =>
      'Its recording will be removed and your progress will be recalculated.';

  @override
  String get loadEarlier => 'Load earlier moments';

  @override
  String get progressTitle => 'Keep showing up.';

  @override
  String get smallMoments => 'Small moments add up';

  @override
  String bestAndMoments(int best, int total) {
    return 'Best: $best days · $total moments';
  }

  @override
  String get milestoneReached => 'A milestone reached';

  @override
  String get oneMoment => 'One moment at a time';

  @override
  String get progressDisclaimer =>
      'These milestones celebrate your practice. They do not measure your faith. A missed day is always an invitation to begin again.';

  @override
  String get spaceTitle => 'Simple. Private. Yours.';

  @override
  String storageUsage(String used) {
    return '$used MB of 100 MB';
  }

  @override
  String get storageNearLimit =>
      'Your recordings are nearing the limit. You can free space without losing your streak.';

  @override
  String get storagePrivate => 'Your voice recordings stay on this device.';

  @override
  String get deleteAllRecordings => 'Delete all recordings';

  @override
  String get deleteAllRecordingsTitle => 'Delete all recordings?';

  @override
  String get deleteAllRecordingsDescription =>
      'All audio will be deleted. Completed moments, streaks and badges stay.';

  @override
  String get permissions => 'Permissions';

  @override
  String get permissionLabel => 'Microphone and alarm access';

  @override
  String get aboutData => 'About your data';

  @override
  String get privacyDescription =>
      'No account. No uploads. No ads. Your prayers are stored privately on this device. Uninstalling the app or losing the device can remove your history and recordings.';

  @override
  String get timezoneNote =>
      'Streaks use the local date when a moment is completed. Travel across time zones may skip a day or repeat one. You can always begin again.';

  @override
  String get startFresh => 'Start fresh';

  @override
  String get resetTitle => 'Reset Cercano a Dios?';

  @override
  String get resetDescription =>
      'This deletes your history, audio, alarms, streaks and badges from this device. It cannot be undone.';

  @override
  String get deleteAppData => 'Delete all app data';

  @override
  String get footer => 'Cercano a Dios · 0.1.0\nA little closer, every day.';

  @override
  String get badgeFirst => 'First moment';

  @override
  String get badgeStreak3 => 'Three faithful days';

  @override
  String get badgeStreak7 => 'A week of prayer';

  @override
  String get badgeStreak30 => 'Thirty days together';

  @override
  String get badgeTotal10 => 'Ten moments';

  @override
  String get badgeTotal50 => 'Fifty moments';

  @override
  String get badgeMilestoneDescription => 'A milestone reached';

  @override
  String get badgeLockedDescription => 'One moment at a time';

  @override
  String get promptTitleP01 => 'For this new day';

  @override
  String get promptTextP01 =>
      'Lord, thank you for this new day. Help me receive it with an open heart.';

  @override
  String get promptTitleP02 => 'A small gift';

  @override
  String get promptTextP02 =>
      'Heavenly Father, today I am grateful for ___. Help me notice your gifts in ordinary things.';

  @override
  String get promptTitleP03 => 'A peaceful heart';

  @override
  String get promptTextP03 =>
      'Jesus, meet me in my worries. Teach me to trust you one small step at a time.';

  @override
  String get promptTitleP04 => 'For those I love';

  @override
  String get promptTextP04 =>
      'Lord, bless the people I love. Help me show them patience and kindness today.';

  @override
  String get promptTitleP05 => 'An evening pause';

  @override
  String get promptTextP05 =>
      'Father, thank you for walking with me today. I place this day in your hands.';

  @override
  String get promptTitleP06 => 'Begin again';

  @override
  String get promptTextP06 =>
      'Merciful Jesus, help me begin again when I fall short, and lead me toward what is good.';

  @override
  String get promptTitleP07 => 'A generous spirit';

  @override
  String get promptTextP07 =>
      'Lord, show me someone I can help today. Make me generous with my time and attention.';

  @override
  String get promptTitleP08 => 'For daily bread';

  @override
  String get promptTextP08 =>
      'Father, thank you for the food and shelter I have. Keep those in need close to my heart.';

  @override
  String get promptTitleP09 => 'In the quiet';

  @override
  String get promptTextP09 =>
      'Holy Spirit, quiet the noise within me. Help me listen with a willing heart.';

  @override
  String get promptTitleP10 => 'For my work';

  @override
  String get promptTextP10 =>
      'Jesus, guide the work of my hands. May I serve others with honesty and care.';

  @override
  String get promptTitleP11 => 'When I am tired';

  @override
  String get promptTextP11 =>
      'Lord, I bring you my tiredness. Help me rest and receive the care I need.';

  @override
  String get promptTitleP12 => 'A grateful memory';

  @override
  String get promptTextP12 =>
      'Father, thank you for a moment of joy I remember today: ___.';

  @override
  String get promptTitleP13 => 'The gift of friendship';

  @override
  String get promptTextP13 =>
      'Lord, thank you for those who walk beside me. Help me be a faithful friend.';

  @override
  String get promptTitleP14 => 'For forgiveness';

  @override
  String get promptTextP14 =>
      'Merciful Father, give me courage to seek forgiveness and grace to forgive others.';

  @override
  String get promptTitleP15 => 'With Mary';

  @override
  String get promptTextP15 =>
      'Mary, Mother of Jesus, pray for me as I seek to follow your Son today.';

  @override
  String get promptTitleP16 => 'A patient response';

  @override
  String get promptTextP16 =>
      'Holy Spirit, help me pause before I speak. Let my words carry patience and truth.';

  @override
  String get promptTitleP17 => 'For the lonely';

  @override
  String get promptTextP17 =>
      'Jesus, draw near to those who feel alone. Show me how to offer companionship.';

  @override
  String get promptTitleP18 => 'Trust in uncertainty';

  @override
  String get promptTextP18 =>
      'Father, I do not know everything this day will bring. Help me take the next good step.';

  @override
  String get promptTitleP19 => 'For creation';

  @override
  String get promptTextP19 =>
      'Lord, thank you for the beauty of your creation. Teach me to care for our common home.';

  @override
  String get promptTitleP20 => 'A simple offering';

  @override
  String get promptTextP20 =>
      'Jesus, I offer you this small moment. Help me grow in faith, hope, and love.';

  @override
  String get appOpenError => 'We could not open your prayer journal.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get soundReminders => 'Sound reminders on this iPhone';

  @override
  String get ringingAlarms => 'Ringing alarms with Stop and Snooze';

  @override
  String deviceAccess(Object permission) {
    return 'Device access: $permission';
  }

  @override
  String listenDuration(Object seconds) {
    return 'Listen · ${seconds}s';
  }

  @override
  String get deleteAudioKeepMoment => 'Delete audio, keep moment';

  @override
  String get deleteMoment => 'Delete moment';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get completed => 'completed';

  @override
  String get notCompleted => 'not completed';

  @override
  String durationSeconds(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String get promptCategoryMorning => 'Morning';

  @override
  String get promptCategoryGratitude => 'Gratitude';

  @override
  String get promptCategoryPeace => 'Peace';

  @override
  String get promptCategoryFamily => 'Family';

  @override
  String get promptCategoryHope => 'Hope';

  @override
  String get promptCategoryService => 'Service';

  @override
  String get promptCategoryFaith => 'Faith';

  @override
  String get microphoneLevel => 'Microphone sound level';

  @override
  String get promptCategoryEvening => 'Evening';
}

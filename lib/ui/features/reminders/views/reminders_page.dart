import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/prayer.dart';
import '../../../../domain/use_cases/next_reminder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';
import '../bloc/reminders_bloc.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage>
    with WidgetsBindingObserver {
  AppBloc get app => context.read<AppBloc>();
  RemindersBloc get bloc => context.read<RemindersBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(bloc.loadStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(bloc.loadStatus());
  }

  Future<void> edit([Reminder? reminder]) async {
    if (bloc.state.capability == 'loading') return;
    final localizations = AppLocalizations.of(context)!;
    if (bloc.state.capability == 'reminder' &&
        !await confirm(
          context,
          localizations.t('soundReminderMode'),
          localizations.t('soundReminderDescription'),
        )) {
      return;
    }
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: reminder?.hour ?? 7,
        minute: reminder?.minute ?? 0,
      ),
    );
    if (time == null || !mounted) return;

    final selected = {...reminder?.weekdays ?? [1, 2, 3, 4, 5, 6, 7]};
    final days = await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(localizations.t('repeatOn')),
          content: Wrap(
            spacing: 8,
            children: List.generate(
              7,
              (i) => FilterChip(
                label: Text(
                  [
                    localizations.t('monday'),
                    localizations.t('tuesday'),
                    localizations.t('wednesday'),
                    localizations.t('thursday'),
                    localizations.t('friday'),
                    localizations.t('saturday'),
                    localizations.t('sunday'),
                  ][i],
                ),
                selected: selected.contains(i + 1),
                onSelected: (value) => setDialog(() {
                  if (value) {
                    selected.add(i + 1);
                  } else {
                    selected.remove(i + 1);
                  }
                }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.t('cancel')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, selected.toList()..sort()),
              child: Text(localizations.t('save')),
            ),
          ],
        ),
      ),
    );
    if (days == null || !mounted) return;

    await bloc.saveReminder(
      Reminder(
        id: reminder?.id ??
            (DateTime.now().millisecondsSinceEpoch % 100000000),
        hour: time.hour,
        minute: time.minute,
        weekdays: days,
      ),
    );
    if (mounted) await bloc.loadStatus();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        builder: (context, state) => BlocBuilder<RemindersBloc, RemindersState>(
          builder: (context, reminderState) {
          final localizations = AppLocalizations.of(context)!;
          return PageBody(
            children: [
              SectionLabel(localizations.t('makeSpace')),
              Text(
                localizations.t('prayerTime'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                reminderState.capability == 'reminder'
                    ? localizations.t('soundReminders')
                    : localizations.t('ringingAlarms'),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.t('deviceAccess', {
                  'permission': reminderState.permission,
                }),
                style: const TextStyle(fontSize: 13),
              ),
              if (reminderState.permission != 'ready')
                TextButton(
                  onPressed: bloc.openSettings,
                  child: Text(localizations.t('openSettings')),
                ),
              const SizedBox(height: 24),
              ...state.reminders.map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuietCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                timeLabel(reminder.hour, reminder.minute),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                            Switch(
                              value: reminder.enabled,
                              onChanged: reminderState.busy
                                  ? null
                                  : (value) => bloc.saveReminder(
                                        reminder.copyWith(enabled: value),
                                      ),
                            ),
                          ],
                        ),
                        Text(
                          reminder.weekdays
                              .map(
                                (day) => [
                                  localizations.t('monday'),
                                  localizations.t('tuesday'),
                                  localizations.t('wednesday'),
                                  localizations.t('thursday'),
                                  localizations.t('friday'),
                                  localizations.t('saturday'),
                                  localizations.t('sunday'),
                                ][day - 1],
                              )
                              .join(' · '),
                        ),
                        if (nextReminder(reminder, DateTime.now())
                            case final next?)
                          Text(
                            localizations.t('nextAlarm', {
                              'date': calendarDate(next),
                              'time': timeLabel(
                                reminder.hour,
                                reminder.minute,
                              ),
                            }),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          reminder.status == 'pending'
                              ? localizations.t('setupIncomplete')
                              : reminder.status == 'paused'
                                  ? localizations.t('paused')
                                  : reminderState.permission == 'ready'
                                      ? localizations.t('scheduled')
                                      : localizations.t('permissionNeeded'),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: reminderState.busy
                                  ? null
                                  : () => edit(reminder),
                              child: Text(localizations.t('edit')),
                            ),
                            TextButton(
                              onPressed: reminderState.busy
                                  ? null
                                  : () => bloc.deleteReminder(reminder.id),
                              child: Text(localizations.t('delete')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: reminderState.busy || state.reminders.length >= 5
                    ? null
                    : () => edit(),
                icon: const Icon(Icons.add),
                label: Text(localizations.t('addPrayerTime')),
              ),
              if (state.reminders.length >= 5)
                Text(localizations.t('upToFive')),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: reminderState.busy ? null : bloc.testAlarm,
                child: Text(localizations.t('testAlarm')),
              ),
              const SizedBox(height: 16),
              Text(localizations.t('stopAlarmNote')),
            ],
          );
          },
        ),
      );
}

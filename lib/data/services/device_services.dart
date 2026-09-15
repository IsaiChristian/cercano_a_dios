import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/prayer.dart';

/// Adapter for platform capabilities used by the application.
///
/// Keeping the MethodChannel behind a data-layer service prevents views and
/// domain code from depending on platform details.
class DeviceServices {
  final MethodChannel channel;
  final interruptions = StreamController<void>.broadcast();

  DeviceServices({this.channel = const MethodChannel('cercano/device')});

  Future<String> directory() async =>
      (await channel.invokeMethod<String>('directory'))!;

  Future<String> alarmCapability() async =>
      await channel.invokeMethod<String>('alarmCapability') ?? 'reminder';

  Future<String> alarmStatus() async =>
      await channel.invokeMethod<String>('alarmStatus') ?? 'permission';

  Future<void> schedule(Reminder reminder) =>
      channel.invokeMethod('schedule', reminder.toPlatform());

  Future<void> cancel(int id) => channel.invokeMethod('cancel', {'id': id});

  Future<void> cancelSnooze(int id) =>
      channel.invokeMethod('cancelSnooze', {'id': id});

  Future<void> cancelAll() => channel.invokeMethod('cancelAll');

  Future<void> stopAlarm() => channel.invokeMethod('stopAlarm');

  Future<void> testAlarm() => channel.invokeMethod('testAlarm');

  Future<void> settings() => channel.invokeMethod('settings');

  Future<void> record(String path) =>
      channel.invokeMethod('record', {'path': path});

  Future<void> finishRecording() => channel.invokeMethod('finishRecording');

  Future<double> amplitude() async =>
      await channel.invokeMethod<double>('amplitude') ?? 0;

  Future<void> play(String path) => channel.invokeMethod('play', {'path': path});

  Future<void> stopPlayback() => channel.invokeMethod('stopPlayback');
}

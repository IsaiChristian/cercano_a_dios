import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cercano_a_dios/data/repositories/local_prayer_repository.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/use_cases/calculate_progress.dart';

void main() {
 late Directory root;
 late Database db;
 late LocalPrayerRepository repository;
 setUpAll(sqfliteFfiInit);
 setUp(() async {
   root = await Directory.systemTemp.createTemp('prayer-test');
   db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
     options: OpenDatabaseOptions(version:1,onCreate:LocalPrayerRepository.createSchema));
   repository = LocalPrayerRepository(db,root.path);
 });
 tearDown(() async { await db.close(); await root.delete(recursive:true); });
 PrayerSession session({String? audio}) => PrayerSession(id:'one',promptId:'p01',promptText:'Thank you, Lord.',
   localDate:'2026-09-15',completedAt:DateTime.utc(2026,9,15),durationSeconds:10,
   spoken:audio != null,offsetMinutes:-360,audioPath:audio);
 Future<List<PrayerSession>> read() async => (await repository.sessions()).fold((f) => throw StateError(f.message),(v)=>v);
 test('retrying completion writes one record', () async {
   expect((await repository.complete(session())).isRight(),true);
   await repository.complete(session());
   expect((await read()).length,1);
 });
 test('audio deletion keeps a moment and streak, session deletion removes both', () async {
   final file = await File('${root.path}/one.m4a').writeAsBytes([1,2,3]);
   await repository.complete(session(audio:'one.m4a'));
   await repository.deleteAudio('one');
   expect(await file.exists(),false);
   expect((await read()).single.audioPath,isNull);
   expect(calculateProgress(await read(),DateTime(2026,9,15)).currentStreak,1);
   await repository.deleteSession('one'); expect(await read(),isEmpty);
 });
 test('missing audio is not committed as a successful recording', () async {
   expect((await repository.complete(session(audio:'missing.m4a'))).isLeft(),true);
   expect(await read(),isEmpty);
 });
 test('startup removes orphaned recordings but preserves saved ones', () async {
   await File('${root.path}/one.m4a').writeAsBytes([1]);
   await File('${root.path}/orphan.m4a').writeAsBytes([2]);
   await repository.complete(session(audio:'one.m4a'));
   await repository.reconcileFiles();
   expect(await File('${root.path}/one.m4a').exists(),true);
   expect(await File('${root.path}/orphan.m4a').exists(),false);
 });
 test('reset deletes recordings, reminders, and history', () async {
   await File('${root.path}/one.m4a').writeAsBytes([1]);
   await repository.complete(session(audio:'one.m4a'));
   await repository.saveReminder(const Reminder(id:1,hour:7,minute:30,weekdays:[1,3,5]));
   await repository.reset();
   expect(await read(),isEmpty);
   expect((await repository.reminders()).getOrElse(()=>[]),isEmpty);
   expect(await File('${root.path}/one.m4a').exists(),false);
 });
}

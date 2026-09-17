import 'dart:io';

import 'package:cercano_a_dios/data/services/local_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late LocalProfileService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_service_test_');
    service = LocalProfileService(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalProfileService', () {
    test(
      'resolves profile root under profiles directory and creates it',
      () async {
        const userId = 'user-123';
        final root = await service.resolveProfileRoot(userId);

        expect(await Directory(root).exists(), isTrue);
        expect(p.isWithin(p.join(tempDir.path, 'profiles'), root), isTrue);
        expect(
          root,
          equals(
            p.join(
              tempDir.path,
              'profiles',
              LocalProfileService.encodeUserId(userId),
            ),
          ),
        );
      },
    );

    test('reopens exact same directory for same user ID', () async {
      const userId = 'user-abc';
      final root1 = await service.resolveProfileRoot(userId);

      // Write a file in that profile root
      final marker = File(p.join(root1, 'welcomed'));
      await marker.writeAsString('1');

      final root2 = await service.resolveProfileRoot(userId);
      expect(root2, equals(root1));
      expect(await File(p.join(root2, 'welcomed')).exists(), isTrue);
    });

    test('isolates different user IDs into separate directories', () async {
      final rootA = await service.resolveProfileRoot('user-alpha');
      final rootB = await service.resolveProfileRoot('user-beta');

      expect(rootA, isNot(equals(rootB)));

      // Files in profile A are not present in profile B
      await File(p.join(rootA, 'file_a.txt')).writeAsString('hello A');
      expect(await File(p.join(rootB, 'file_a.txt')).exists(), isFalse);
    });

    test(
      'profileExists reports false before creation and true after',
      () async {
        const userId = 'user-exists-check';
        expect(await service.profileExists(userId), isFalse);

        await service.resolveProfileRoot(userId);
        expect(await service.profileExists(userId), isTrue);
      },
    );

    test(
      'safely encodes path traversal characters without escaping profiles directory',
      () async {
        const dangerousId = '../../../etc/passwd';
        final root = await service.resolveProfileRoot(dangerousId);

        expect(await Directory(root).exists(), isTrue);
        expect(p.isWithin(p.join(tempDir.path, 'profiles'), root), isTrue);
        expect(p.basename(root), isNot(contains('/')));
        expect(p.basename(root), isNot(contains('..')));
      },
    );

    test('throws ArgumentError on empty or whitespace user ID', () async {
      expect(
        () => service.resolveProfileRoot(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.resolveProfileRoot('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('error messages do not leak user IDs or paths', () {
      try {
        LocalProfileService.encodeUserId('');
        fail('Should throw');
      } catch (e) {
        expect(e.toString(), isNot(contains(tempDir.path)));
      }
    });
  });
}

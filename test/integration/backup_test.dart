// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

import 'integration_test_case.dart';

void main() => BackupTestCase().run();

class BackupTestCase extends IntegrationTestCase {
  @override
  String get name => 'backup';

  Future<void> runSut() => runPodmanBackup(
        backupMode: BackupMode.backupOnly,
        backupDir: backupDir,
        cacheDir: cacheDir,
      );

  @override
  FutureOr<void> build() {
    test('Can backup a single, unattached volume', () async {
      // arrange
      const volume1 = 'test-volume-1';
      const volume2 = 'test-volume-2';

      await createVolume(volume1);
      await createVolume(volume2, backedUp: false);

      // act
      await runSut();

      // assert
      expect(
        cacheDir.list(),
        emitsInAnyOrder(<dynamic>[
          isA<File>().having(
            (m) => m.path,
            'path',
            matches(volumePattern(volume1)),
          ),
          emitsDone,
        ]),
      );
    });

    test('can backup a single, attached volume', () async {
      // arrange
      const volume = 'test-volume-s1-1';

      await createVolume(volume);
      await startService('test-service-1.service');

      // act
      await runSut();

      // assert
      expect(
        cacheDir.list(),
        emitsInAnyOrder(<dynamic>[
          isA<File>().having(
            (m) => m.path,
            'path',
            matches(volumePattern(volume)),
          ),
          emitsDone,
        ]),
      );

      expectServiceLog(const [
        'STARTED test-service-1',
        'STOPPED test-service-1',
        'STARTED test-service-1',
      ]);
    });

    test('can backup a multiple, cross-attached volumes', () async {
      // arrange
      const volume1 = 'test-volume-s2-1';
      const volume2 = 'test-volume-s2-2';
      const volume3 = 'test-volume-s2-3';
      const volume4 = 'test-volume-s2-4';
      const volume5 = 'test-volume-s2-5';
      const backedUpVolumes = [volume1, volume2, volume3, volume4];

      for (final volume in backedUpVolumes) {
        await createVolume(volume);
      }
      await createVolume(volume5, backedUp: false);
      await startService('test-service-2.service');
      await startService('test-service-3.service');
      await startService('test-service-4.service');
      await startService('test-service-5.service');

      // act
      await runSut();

      // assert
      expect(
        cacheDir.list(),
        emitsInAnyOrder(<dynamic>[
          for (final volume in backedUpVolumes)
            isA<File>().having(
              (m) => m.path,
              'path',
              matches(volumePattern(volume)),
            ),
          emitsDone,
        ]),
      );

      expectServiceLog(const [
        'STARTED test-service-2',
        'STARTED test-service-3',
        'STARTED test-service-4',
        'STARTED test-service-5',
        'STOPPED test-service-2',
        'STOPPED test-service-4',
        'STOPPED test-service-3',
        'STARTED test-service-2',
        'STARTED test-service-4',
        'STARTED test-service-3',
      ]);
    });
  }
}

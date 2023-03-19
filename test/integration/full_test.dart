import 'dart:io';

import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

import 'integration_test_case.dart';

void main() => FullTest().run();

class FullTest extends IntegrationTestCase {
  @override
  String get name => 'full';

  Future<void> runSut() => runPodmanBackup(
        backupMode: BackupMode.full,
        backupDir: backupDir,
        cacheDir: cacheDir,
      );

  @override
  void build() {
    test('can run full, simple, single volume backup', () async {
      // arrange
      const volume1 = 'test-volume-1';
      await createVolume(volume1);

      // act
      await runSut();

      // assert
      expect(cacheDir.list(), emitsDone);

      expect(
        backupDir.list(),
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
  }
}

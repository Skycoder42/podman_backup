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
        maxKeep: 1,
      );

  @override
  void build() {
    test('can run full, simple, single volume backup with cleanup', () async {
      // arrange
      const volume1 = 'test-volume-1';
      await createVolume(volume1);

      final timestamp = createTimestampSuffix(
        DateTime.now().add(const Duration(days: -10)),
      );
      await File.fromUri(
        backupDir.uri.resolve('$volume1-$timestamp.tar.xz'),
      ).create();

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(0));
      expect(backupDir.list().length, completion(1));
      await verifyVolume(backupDir, volume1);
    });
  }
}

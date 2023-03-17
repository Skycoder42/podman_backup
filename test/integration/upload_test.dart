import 'dart:io';

import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

import 'integration_test_case.dart';

void main() => UploadTestCase().run();

class UploadTestCase extends IntegrationTestCase {
  @override
  String get name => 'upload';

  Future<void> runSut() => runPodmanBackup(
        backupMode: BackupMode.uploadOnly,
        backupDir: backupDir,
        cacheDir: cacheDir,
      );

  @override
  void build() {
    test('Can upload a single backup', () async {
      // arrange
      const backupFileName = 'backup.tar.xz';
      final backupFile = await _createBackupFile(backupFileName);

      // act
      await runSut();

      // assert
      final backedUpFile = _getBackedUpFile(backupFileName);
      expect(backedUpFile.existsSync(), isTrue);
      expect(backedUpFile.readAsStringSync(), backupFileName);

      expect(backupFile.existsSync(), isFalse);
      expect(cacheDir.list(), emitsDone);
    });
  }

  Future<File> _createBackupFile(String backupFile) =>
      File.fromUri(cacheDir.uri.resolve(backupFile)).writeAsString(backupFile);

  File _getBackedUpFile(String backupFile) =>
      File.fromUri(backupDir.uri.resolve(backupFile));
}

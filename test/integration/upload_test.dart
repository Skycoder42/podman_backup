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
      final backupFile = await _createBackupFile('backup.tar.xz');

      // act
      await runSut();

      // assert
      expect(backupFile.existsSync(), isFalse);
      final backedUpFile = _getBackedUpFile(backupFile);
      expect(backedUpFile.existsSync(), isTrue);
      expect(backedUpFile.readAsStringSync(), 'backup.tar.xz');
    });
  }

  Future<File> _createBackupFile(String backupFile) =>
      File.fromUri(cacheDir.uri.resolve(backupFile)).writeAsString(backupFile);

  File _getBackedUpFile(File backupFile) =>
      File.fromUri(cacheDir.uri.resolve(backupFile.uri.pathSegments.last));
}

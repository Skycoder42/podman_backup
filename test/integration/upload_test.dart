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

    test('Can upload a multiple backed up files and replaces target files',
        () async {
      // arrange
      const backupFileNames = [
        'backup-1.tar.xz',
        'backup-2.tar.xz',
        'backup-3.tar.xz',
        'backup-4.tar.xz',
      ];
      final backupFiles = await Future.wait(
        backupFileNames.map(_createBackupFile),
      );
      await _getBackedUpFile(backupFileNames.last).writeAsString('old content');
      final otherFile =
          await _getBackedUpFile('other').writeAsString('other content');

      // act
      await runSut();

      // assert
      for (final backupFileName in backupFileNames) {
        final backedUpFile = _getBackedUpFile(backupFileName);
        expect(backedUpFile.existsSync(), isTrue);
        expect(backedUpFile.readAsStringSync(), backupFileName);
      }
      expect(otherFile.existsSync(), isTrue);
      expect(otherFile.readAsStringSync(), 'other content');

      for (final backupFile in backupFiles) {
        expect(backupFile.existsSync(), isFalse);
      }
      expect(cacheDir.list(), emitsDone);
    });
  }

  Future<File> _createBackupFile(String backupFile) =>
      File.fromUri(cacheDir.uri.resolve(backupFile)).writeAsString(backupFile);

  File _getBackedUpFile(String backupFile) =>
      File.fromUri(backupDir.uri.resolve(backupFile));
}

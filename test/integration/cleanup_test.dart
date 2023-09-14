import 'dart:io';

import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

import 'integration_test_case.dart';

void main() => CleanupTestCase().run();

class CleanupTestCase extends IntegrationTestCase {
  @override
  String get name => 'cleanup';

  @override
  void build() {
    test('runs cleanup for single volume', () async {
      // arrange
      const testVolume = 'test-volume';
      final now = DateTime.now();

      final backup1 = await _createUploadedBackup(
        testVolume,
        now.add(const Duration(days: 1)),
      );
      final backup2 = await _createUploadedBackup(
        testVolume,
        now.add(const Duration(days: 2)),
      );
      final backup3 = await _createUploadedBackup(
        testVolume,
        now.add(const Duration(days: 3)),
      );
      final backup4 = await _createUploadedBackup(
        testVolume,
        now.add(const Duration(days: 4)),
      );
      final backup5 = await _createUploadedBackup(
        testVolume,
        now.add(const Duration(days: 5)),
      );

      // act
      await _runSut(maxKeep: 3);

      // assert
      expect(backupDir.list().length, completion(3));
      expect(backup1.existsSync(), isFalse);
      expect(backup2.existsSync(), isFalse);
      expect(backup3.existsSync(), isTrue);
      expect(backup4.existsSync(), isTrue);
      expect(backup5.existsSync(), isTrue);
    });

    test('can cleanup multiple volumes', () async {
      // arrange
      const testVolume1 = 'test-volume-1';
      const testVolume2 = 'test-volume-2';
      final now = DateTime.now();

      final backup11 = await _createUploadedBackup(
        testVolume1,
        now.add(const Duration(days: 3)),
        30,
      );
      final backup12 = await _createUploadedBackup(
        testVolume1,
        now.add(const Duration(days: 4)),
        30,
      );
      final backup13 = await _createUploadedBackup(
        testVolume1,
        now.add(const Duration(days: 5)),
        30,
      );
      final backup21 = await _createUploadedBackup(
        testVolume2,
        now.add(const Duration(days: 1)),
        30,
      );
      final backup22 = await _createUploadedBackup(
        testVolume2,
        now.add(const Duration(days: 2)),
        30,
      );

      // act
      await _runSut(maxKeep: 2, maxTotalSizeMegaBytes: 100);

      // assert
      expect(backupDir.list().length, completion(3));
      expect(backup11.existsSync(), isFalse);
      expect(backup12.existsSync(), isTrue);
      expect(backup13.existsSync(), isTrue);
      expect(backup21.existsSync(), isFalse);
      expect(backup22.existsSync(), isTrue);
    });
  }

  Future<void> _runSut({
    int minKeep = 1,
    int? maxKeep,
    Duration? maxAge,
    int? maxTotalSizeMegaBytes,
  }) =>
      runPodmanBackup(
        backupMode: BackupMode.cleanupOnly,
        backupDir: backupDir,
        cacheDir: cacheDir,
        minKeep: minKeep,
        maxKeep: maxKeep,
        maxAge: maxAge,
        maxTotalSizeMegaBytes: maxTotalSizeMegaBytes,
      );

  Future<File> _createUploadedBackup(
    String volume,
    DateTime dateTime, [
    int megaBytes = 0,
  ]) =>
      File.fromUri(
        backupDir.uri.resolve(
          '$volume-${createTimestampSuffix(dateTime)}.tar.xz',
        ),
      ).writeAsBytes(List.filled(megaBytes * 1024 * 1024, 0));
}

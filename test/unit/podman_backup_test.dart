import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/backup/backup_controller.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:podman_backup/src/podman_backup.dart';
import 'package:podman_backup/src/upload/upload_controller.dart';
import 'package:test/test.dart';

class MockBackupController extends Mock implements BackupController {}

class MockUploadController extends Mock implements UploadController {}

void main() {
  setUpAll(() {
    registerFallbackValue(Directory.current);
  });

  group('$PodmanBackup', () {
    final mockBackupController = MockBackupController();
    final mockUploadController = MockUploadController();

    late Directory testDir;
    late PodmanBackup sut;

    setUp(() async {
      reset(mockBackupController);
      reset(mockUploadController);

      when(
        () => mockBackupController.backup(
          backupLabel: any(named: 'backupLabel'),
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenReturnAsync(null);
      when(
        () => mockUploadController.upload(
          remoteHost: any(named: 'remoteHost'),
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenReturnAsync(null);

      testDir = await Directory.systemTemp.createTemp();
      sut = PodmanBackup(
        mockBackupController,
        mockUploadController,
      );
    });

    tearDown(() async {
      await testDir.delete(recursive: true);

      verifyNoMoreInteractions(mockBackupController);
      verifyNoMoreInteractions(mockUploadController);
    });

    group('run', () {
      test('runs backup only', () async {
        final cacheDir = Directory.fromUri(testDir.uri.resolve('test/backup'));

        await sut.run(
          Options(
            remoteHostRaw: '',
            remoteHostRawWasParsed: true,
            backupCache: cacheDir,
            backupMode: BackupMode.backupOnly,
          ),
        );

        verify(
          () => mockBackupController.backup(
            backupLabel: Options.defaultBackupLabel,
            cacheDir: cacheDir,
          ),
        );

        expect(cacheDir.existsSync(), isTrue);
      });

      test('runs upload only', () async {
        const testRemoteHost = 'test-host:/target';
        final cacheDir =
            await Directory.fromUri(testDir.uri.resolve('test/upload'))
                .create(recursive: true);

        await sut.run(
          Options(
            remoteHostRaw: testRemoteHost,
            remoteHostRawWasParsed: true,
            backupCache: cacheDir,
            backupMode: BackupMode.uploadOnly,
          ),
        );

        verify(
          () => mockUploadController.upload(
            remoteHost: testRemoteHost,
            cacheDir: cacheDir,
          ),
        );

        expect(cacheDir.existsSync(), isTrue);
      });

      test('runs full backup', () async {
        const testRemoteHost = 'test-host:/target';
        const testLabel = 'test-label';

        final cacheDir = Directory.fromUri(testDir.uri.resolve('test/backup'));

        await sut.run(
          Options(
            remoteHostRaw: testRemoteHost,
            remoteHostRawWasParsed: true,
            backupLabel: testLabel,
            backupCache: cacheDir,
          ),
        );

        verifyInOrder([
          () => mockBackupController.backup(
                backupLabel: testLabel,
                cacheDir: cacheDir,
              ),
          () => mockUploadController.upload(
                remoteHost: testRemoteHost,
                cacheDir: cacheDir,
              ),
        ]);

        expect(cacheDir.existsSync(), isTrue);
      });
    });
  });
}
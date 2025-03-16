import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/systemctl_adapter.dart';
import 'package:podman_backup/src/backup/backup_controller.dart';
import 'package:podman_backup/src/cleanup/cleanup_controller.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:podman_backup/src/podman_backup.dart';
import 'package:podman_backup/src/upload/upload_controller.dart';
import 'package:test/test.dart';

class MockBackupController extends Mock implements BackupController {}

class MockUploadController extends Mock implements UploadController {}

class MockCleanupController extends Mock implements CleanupController {}

class MockSystemctlAdapter extends Mock implements SystemctlAdapter {}

void main() {
  setUpAll(() {
    registerFallbackValue(Directory.current);
  });

  group('$PodmanBackup', () {
    final mockBackupController = MockBackupController();
    final mockUploadController = MockUploadController();
    final mockCleanupController = MockCleanupController();
    final mockSystemctlAdapter = MockSystemctlAdapter();

    late Directory testDir;
    late PodmanBackup sut;

    setUp(() async {
      reset(mockBackupController);
      reset(mockUploadController);
      reset(mockCleanupController);
      reset(mockSystemctlAdapter);

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
      when(
        () => mockCleanupController.cleanupOldBackups(
          any(),
          minKeep: any(named: 'minKeep'),
          maxKeep: any(named: 'maxKeep'),
          maxAge: any(named: 'maxAge'),
          maxBytesTotal: any(named: 'maxBytesTotal'),
        ),
      ).thenReturnAsync(null);

      testDir = await Directory.systemTemp.createTemp();
      sut = PodmanBackup(
        mockSystemctlAdapter,
        mockBackupController,
        mockUploadController,
        mockCleanupController,
      );
    });

    tearDown(() async {
      await testDir.delete(recursive: true);

      verifyNoMoreInteractions(mockSystemctlAdapter);
      verifyNoMoreInteractions(mockUploadController);
      verifyNoMoreInteractions(mockUploadController);
      verifyNoMoreInteractions(mockCleanupController);
    });

    group('run', () {
      test('runs backup only', () async {
        final cacheDir = Directory.fromUri(testDir.uri.resolve('test/backup'));

        await sut.run(
          Options(
            remoteHostRaw: '',
            remoteHostRawWasParsed: true,
            backupLabel: Options.defaultBackupLabel,
            backupCache: cacheDir,
            backupMode: BackupMode.backupOnly,
            user: true,
            minKeep: 1,
            maxKeep: null,
            maxAgeRaw: null,
            maxTotalSizeRaw: null,
            logLevel: Level.ALL,
          ),
        );

        verifyInOrder([
          () => mockSystemctlAdapter.runAsUser = true,
          () => mockBackupController.backup(
            backupLabel: Options.defaultBackupLabel,
            cacheDir: cacheDir,
          ),
        ]);

        expect(cacheDir.existsSync(), isTrue);
      });

      test('runs upload only', () async {
        const testRemoteHost = 'test-host:/target';
        final cacheDir = await Directory.fromUri(
          testDir.uri.resolve('test/upload'),
        ).create(recursive: true);

        await sut.run(
          Options(
            remoteHostRaw: testRemoteHost,
            remoteHostRawWasParsed: true,
            backupLabel: Options.defaultBackupLabel,
            backupCache: cacheDir,
            backupMode: BackupMode.uploadOnly,
            user: true,
            minKeep: 1,
            maxKeep: null,
            maxAgeRaw: null,
            maxTotalSizeRaw: null,
            logLevel: Level.ALL,
          ),
        );

        verifyInOrder([
          () => mockSystemctlAdapter.runAsUser = true,
          () => mockUploadController.upload(
            remoteHost: testRemoteHost,
            cacheDir: cacheDir,
          ),
        ]);

        expect(cacheDir.existsSync(), isTrue);
      });

      test('runs cleanup only', () async {
        const testRemoteHost = 'test-host:/target';
        final cacheDir = await Directory.fromUri(
          testDir.uri.resolve('test/upload'),
        ).create(recursive: true);

        await sut.run(
          Options(
            remoteHostRaw: testRemoteHost,
            remoteHostRawWasParsed: true,
            backupLabel: Options.defaultBackupLabel,
            backupCache: cacheDir,
            backupMode: BackupMode.cleanupOnly,
            user: true,
            minKeep: 3,
            maxKeep: 5,
            maxAgeRaw: 30,
            maxTotalSizeRaw: 1024,
            logLevel: Level.ALL,
          ),
        );

        verifyInOrder([
          () => mockSystemctlAdapter.runAsUser = true,
          () => mockCleanupController.cleanupOldBackups(
            testRemoteHost,
            minKeep: 3,
            maxKeep: 5,
            maxAge: const Duration(days: 30),
            maxBytesTotal: 1024 * 1024 * 1024,
          ),
        ]);
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
            backupMode: BackupMode.full,
            user: false,
            minKeep: 1,
            maxKeep: null,
            maxAgeRaw: null,
            maxTotalSizeRaw: null,
            logLevel: Level.ALL,
          ),
        );

        verifyInOrder([
          () => mockSystemctlAdapter.runAsUser = false,
          () => mockBackupController.backup(
            backupLabel: testLabel,
            cacheDir: cacheDir,
          ),
          () => mockUploadController.upload(
            remoteHost: testRemoteHost,
            cacheDir: cacheDir,
          ),
          () => mockCleanupController.cleanupOldBackups(testRemoteHost),
          () => mockCleanupController,
        ]);

        expect(cacheDir.existsSync(), isTrue);
      });
    });
  });
}

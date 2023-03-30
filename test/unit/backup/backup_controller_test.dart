// ignore_for_file: unnecessary_lambdas

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/compress_adapter.dart';
import 'package:podman_backup/src/adapters/date_time_adapter.dart';
import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/adapters/systemctl_adapter.dart';
import 'package:podman_backup/src/backup/backup_controller.dart';
import 'package:podman_backup/src/backup/backup_strategy.dart';
import 'package:podman_backup/src/backup/backup_strategy_builder.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

class MockBackupStrategyBuilder extends Mock implements BackupStrategyBuilder {}

class MockBackupStrategy extends Mock implements BackupStrategy {}

class MockSystemctlAdapter extends Mock implements SystemctlAdapter {}

class MockPodmanAdapter extends Mock implements PodmanAdapter {}

class MockCompressAdapter extends Mock implements CompressAdapter {}

class MockDateTimeAdapter extends Mock implements DateTimeAdapter {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Stream<List<int>>.empty());
  });

  group('$BackupController', () {
    const testBackupLabel = 'test-backup-label';

    final mockBackupStrategyBuilder = MockBackupStrategyBuilder();
    final mockBackupStrategy = MockBackupStrategy();
    final mockSystemctlAdapter = MockSystemctlAdapter();
    final mockPodmanAdapter = MockPodmanAdapter();
    final mockCompressAdapter = MockCompressAdapter();
    final mockDateTimeAdapter = MockDateTimeAdapter();

    late DateTime utcNow;
    late Directory testCacheDir;

    late BackupController sut;

    setUp(() async {
      reset(mockBackupStrategyBuilder);
      reset(mockBackupStrategy);
      reset(mockSystemctlAdapter);
      reset(mockPodmanAdapter);
      reset(mockCompressAdapter);
      reset(mockDateTimeAdapter);

      utcNow = DateTime.now().toUtc();
      testCacheDir = await Directory.systemTemp.createTemp();

      when(
        () => mockBackupStrategyBuilder.buildStrategy(
          backupLabel: any(named: 'backupLabel'),
        ),
      ).thenReturnAsync(mockBackupStrategy);
      when(() => mockDateTimeAdapter.utcNow).thenReturn(utcNow);
      when(() => mockCompressAdapter.bind(any()))
          .thenAnswer((i) => i.positionalArguments.first as Stream<List<int>>);
      when(() => mockSystemctlAdapter.start(any())).thenReturnAsync(null);
      when(() => mockSystemctlAdapter.stop(any())).thenReturnAsync(null);

      sut = BackupController(
        mockBackupStrategyBuilder,
        mockSystemctlAdapter,
        mockPodmanAdapter,
        mockCompressAdapter,
        mockDateTimeAdapter,
      );
    });

    tearDown(() async {
      await testCacheDir.delete(recursive: true);

      verifyNoMoreInteractions(mockBackupStrategyBuilder);
      verifyNoMoreInteractions(mockBackupStrategy);
      verifyNoMoreInteractions(mockSystemctlAdapter);
      verifyNoMoreInteractions(mockPodmanAdapter);
      verifyNoMoreInteractions(mockCompressAdapter);
      verifyNoMoreInteractions(mockDateTimeAdapter);
    });

    void setupStrategy(List<Tuple2<List<String>, List<String>>> entries) {
      var index = -1;
      when(() => mockBackupStrategy.next())
          .thenAnswer((i) => ++index < entries.length);
      when(() => mockBackupStrategy.volumes)
          .thenAnswer((i) => entries[index].item1);
      when(() => mockBackupStrategy.services)
          .thenAnswer((i) => entries[index].item2);
    }

    File backupFile(String volume) {
      final dateSegments = [
        utcNow.year.toString(),
        utcNow.month.toString().padLeft(2, '0'),
        utcNow.day.toString().padLeft(2, '0'),
        utcNow.hour.toString().padLeft(2, '0'),
        utcNow.minute.toString().padLeft(2, '0'),
        utcNow.second.toString().padLeft(2, '0'),
      ];
      return File.fromUri(
        testCacheDir.uri.resolve(
          '$volume-${dateSegments.join('_')}.tar.xz',
        ),
      );
    }

    group('backup', () {
      test('does nothing if no volumes are found', () async {
        setupStrategy(const []);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(0));
      });

      test('runs backup for single, unattached volume', () async {
        const testVolume = 'test-volume';
        final testExportBytes = List.filled(10, 10);
        final testExportStream = Stream.value(testExportBytes);
        when(() => mockPodmanAdapter.volumeExport(any()))
            .thenStream(testExportStream);
        setupStrategy(const [
          Tuple2([testVolume], []),
        ]);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume),
          () => mockCompressAdapter.bind(testExportStream),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(1));
        final volumeBackup = backupFile(testVolume);
        expect(volumeBackup, _fseExists);
        expect(
          volumeBackup.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes)),
        );
      });

      test('runs backup for single, attached volume', () async {
        const testVolume = 'test-volume';
        const testService = 'test-service';
        final testExportBytes = List.filled(10, 10);
        final testExportStream = Stream.value(testExportBytes);
        when(() => mockPodmanAdapter.volumeExport(any()))
            .thenStream(testExportStream);
        setupStrategy(const [
          Tuple2([testVolume], [testService]),
        ]);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService),
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume),
          () => mockCompressAdapter.bind(testExportStream),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService),
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(1));
        final volumeBackup = backupFile(testVolume);
        expect(volumeBackup, _fseExists);
        expect(
          volumeBackup.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes)),
        );
      });

      test('runs backup for multiple, unattached volumes', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';
        const testVolume3 = 'test-volume-3';
        final testExportBytes1 = List.filled(10, 10);
        final testExportBytes2 = List.filled(20, 20);
        final testExportBytes3 = List.filled(30, 30);
        final testExportStream1 = Stream.value(testExportBytes1);
        final testExportStream2 = Stream.value(testExportBytes2);
        final testExportStream3 = Stream.value(testExportBytes3);

        when(() => mockPodmanAdapter.volumeExport(testVolume1))
            .thenStream(testExportStream1);
        when(() => mockPodmanAdapter.volumeExport(testVolume2))
            .thenStream(testExportStream2);
        when(() => mockPodmanAdapter.volumeExport(testVolume3))
            .thenStream(testExportStream3);
        setupStrategy(const [
          Tuple2([testVolume1, testVolume2], []),
          Tuple2([testVolume3], []),
        ]);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume1),
          () => mockCompressAdapter.bind(testExportStream1),
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume2),
          () => mockCompressAdapter.bind(testExportStream2),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume3),
          () => mockCompressAdapter.bind(testExportStream3),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(3));
        final volumeBackup1 = backupFile(testVolume1);
        final volumeBackup2 = backupFile(testVolume2);
        final volumeBackup3 = backupFile(testVolume3);
        expect(volumeBackup1, _fseExists);
        expect(
          volumeBackup1.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes1)),
        );
        expect(volumeBackup2, _fseExists);
        expect(
          volumeBackup2.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes2)),
        );
        expect(volumeBackup3, _fseExists);
        expect(
          volumeBackup3.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes3)),
        );
      });

      test('runs backup for single volume with multiple attached services',
          () async {
        const testVolume = 'test-volume';
        const testService1 = 'test-service1';
        const testService2 = 'test-service2';
        const testService3 = 'test-service3';
        final testExportBytes = List.filled(10, 10);
        final testExportStream = Stream.value(testExportBytes);
        when(() => mockPodmanAdapter.volumeExport(any()))
            .thenStream(testExportStream);
        setupStrategy(const [
          Tuple2([testVolume], [testService1, testService2, testService3]),
        ]);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService1),
          () => mockSystemctlAdapter.stop(testService2),
          () => mockSystemctlAdapter.stop(testService3),
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume),
          () => mockCompressAdapter.bind(testExportStream),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService1),
          () => mockSystemctlAdapter.start(testService2),
          () => mockSystemctlAdapter.start(testService3),
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(1));
        final volumeBackup = backupFile(testVolume);
        expect(volumeBackup, _fseExists);
        expect(
          volumeBackup.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes)),
        );
      });

      test('runs backup for multiple volumes with different services',
          () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';
        const testVolume3 = 'test-volume-3';
        const testService1 = 'test-service1';
        const testService2 = 'test-service2';
        const testService3 = 'test-service3';
        final testExportBytes1 = List.filled(10, 10);
        final testExportBytes2 = List.filled(20, 20);
        final testExportBytes3 = List.filled(30, 30);
        final testExportStream1 = Stream.value(testExportBytes1);
        final testExportStream2 = Stream.value(testExportBytes2);
        final testExportStream3 = Stream.value(testExportBytes3);

        when(() => mockPodmanAdapter.volumeExport(testVolume1))
            .thenStream(testExportStream1);
        when(() => mockPodmanAdapter.volumeExport(testVolume2))
            .thenStream(testExportStream2);
        when(() => mockPodmanAdapter.volumeExport(testVolume3))
            .thenStream(testExportStream3);
        setupStrategy(const [
          Tuple2([testVolume1, testVolume2], [testService1]),
          Tuple2([testVolume3], [testService2, testService3]),
        ]);

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService1),
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume1),
          () => mockCompressAdapter.bind(testExportStream1),
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume2),
          () => mockCompressAdapter.bind(testExportStream2),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService1),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService2),
          () => mockSystemctlAdapter.stop(testService3),
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume3),
          () => mockCompressAdapter.bind(testExportStream3),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService2),
          () => mockSystemctlAdapter.start(testService3),
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(3));
        final volumeBackup1 = backupFile(testVolume1);
        final volumeBackup2 = backupFile(testVolume2);
        final volumeBackup3 = backupFile(testVolume3);
        expect(volumeBackup1, _fseExists);
        expect(
          volumeBackup1.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes1)),
        );
        expect(volumeBackup2, _fseExists);
        expect(
          volumeBackup2.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes2)),
        );
        expect(volumeBackup3, _fseExists);
        expect(
          volumeBackup3.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes3)),
        );
      });

      test('restarts stopped services if stopping fails', () async {
        const testVolume = 'test-volume';
        const testService = 'test-service';
        when(() => mockSystemctlAdapter.stop(any()))
            .thenThrow(Exception('test error'));
        setupStrategy(const [
          Tuple2([testVolume], [testService]),
        ]);

        await expectLater(
          () => sut.backup(
            backupLabel: testBackupLabel,
            cacheDir: testCacheDir,
          ),
          throwsException,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService),
        ]);

        expect(testCacheDir.list().length, completion(0));
      });

      test('logs warning but continues if service restart fails', () async {
        const testVolume = 'test-volume';
        const testService = 'test-service';
        final testExportBytes = List.filled(10, 10);
        final testExportStream = Stream.value(testExportBytes);
        final testException = Exception('test error');
        when(() => mockPodmanAdapter.volumeExport(any()))
            .thenStream(testExportStream);
        when(() => mockSystemctlAdapter.start(any()))
            .thenAnswer((i) async => throw testException);
        setupStrategy(const [
          Tuple2([testVolume], [testService]),
        ]);

        // verify log message
        Logger.root.level = Level.ALL;
        expect(
          Logger.root.onRecord,
          emitsThrough(
            isA<LogRecord>()
                .having((m) => m.level, 'level', Level.WARNING)
                .having((m) => m.message, 'message', contains(testService))
                .having((m) => m.error, 'error', same(testException)),
          ),
        );

        await sut.backup(
          backupLabel: testBackupLabel,
          cacheDir: testCacheDir,
        );

        verifyInOrder([
          () => mockBackupStrategyBuilder.buildStrategy(
                backupLabel: testBackupLabel,
              ),
          () => mockBackupStrategy.next(),
          () => mockBackupStrategy.volumes,
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.stop(testService),
          () => mockBackupStrategy.volumes,
          () => mockDateTimeAdapter.utcNow,
          () => mockPodmanAdapter.volumeExport(testVolume),
          () => mockCompressAdapter.bind(testExportStream),
          () => mockBackupStrategy.services,
          () => mockBackupStrategy.services,
          () => mockSystemctlAdapter.start(testService),
          () => mockBackupStrategy.next(),
        ]);

        expect(testCacheDir.list().length, completion(1));
        final volumeBackup = backupFile(testVolume);
        expect(volumeBackup, _fseExists);
        expect(
          volumeBackup.readAsBytes(),
          completion(Uint8List.fromList(testExportBytes)),
        );
      });
    });
  });
}

final _fseExists = predicate<FileSystemEntity>(
  (e) => e.existsSync(),
  'Entity exists on file system',
);

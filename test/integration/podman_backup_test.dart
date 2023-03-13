import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import '../../bin/podman_backup.dart' as podman_backup;

void main() {
  final debugOverwriteLabel = Platform.environment['PODMAN_BACKUP_LABEL'];

  late Directory logDir;
  late Directory cacheDir;
  late Directory backupDir;

  late String timestampPrefix;

  setUpAll(() async {
    logDir = await Directory('/tmp/container-log').create(recursive: true);
  });

  setUp(() async {
    cacheDir = await Directory.systemTemp.createTemp();
    backupDir = await Directory.systemTemp.createTemp();

    timestampPrefix = DateTime.now()
        .toUtc()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '_');
  });

  tearDown(() async {
    await backupDir.delete(recursive: true);
    await cacheDir.delete(recursive: true);
  });

  RegExp volumePattern(String volume) =>
      RegExp('.*\\/$volume-$timestampPrefix(_\\d{2}){3}.tar.xz');

  void expectServiceLog(List<String> log) => expect(
        // ignore: discarded_futures
        File.fromUri(logDir.uri.resolve('test-service.log')).readAsLines(),
        completion(log),
      );

  Future<void> runSut(String mode, [List<String>? args]) async =>
      podman_backup.main([
        '--remote',
        'integration_test_local:${backupDir.path}',
        '--backup-mode',
        mode,
        '--backup-cache',
        cacheDir.path,
        if (debugOverwriteLabel != null) ...[
          '--backup-label',
          debugOverwriteLabel
        ],
        ...?args,
      ]);

  group('backup', () {
    test('Can backup a single, unattached volume', () async {
      // arrange
      const volume1 = 'test_volume_1';
      const volume2 = 'test_volume_2';

      await _createVolume(volume1);
      await _createVolume(volume2, backedUp: false);

      // act
      await runSut('backup-only');

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
      const volume = 'test_volume_s1-1';

      await _createVolume(volume);
      await _startService('test-service-1.service');

      // act
      await runSut('backup-only');

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
      const volume1 = 'test_volume_s2-1';
      const volume2 = 'test_volume_s2-2';
      const volume3 = 'test_volume_s2-3';
      const volume4 = 'test_volume_s2-4';
      const volume5 = 'test_volume_s2-5';
      const backedUpVolumes = [volume1, volume2, volume3, volume4];

      for (final volume in backedUpVolumes) {
        await _createVolume(volume);
      }
      await _createVolume(volume5, backedUp: false);
      await _startService('test-service-2.service');
      await _startService('test-service-3.service');
      await _startService('test-service-4.service');
      await _startService('test-service-5.service');

      // act
      await runSut('backup-only');

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
  });
}

Future<void> _createVolume(String name, {bool backedUp = true}) async {
  await _podman([
    'volume',
    'create',
    if (backedUp) ...[
      '--label',
      Platform.environment['PODMAN_BACKUP_LABEL'] ??
          'de.skycoder42.podman_backup'
    ],
    name,
  ]);
  addTearDown(() => _podman(['volume', 'rm', '--force', name]));
}

Future<void> _startService(String service) async {
  await _systemd(['start', service]);
  addTearDown(() => _systemd(['stop', service]));
}

Future<void> _podman(List<String> arguments) => _run('podman', arguments);

Future<void> _systemd(List<String> arguments) =>
    _run('systemctl', ['--user', ...arguments]);

Future<void> _run(String executable, List<String> arguments) async {
  printOnFailure('> Invoking: $executable $arguments');
  final proc = await Process.start(
    executable,
    arguments,
  );
  _streamLogs('>> ', proc.stdout);
  _streamLogs('>! ', proc.stderr);

  final exitCode = await proc.exitCode;
  printOnFailure('>= Exit code: $exitCode');
  expect(exitCode, 0);
}

void _streamLogs(String prefix, Stream<List<int>> stream) => stream
    .transform(systemEncoding.decoder)
    .transform(const LineSplitter())
    .map((line) => '$prefix$line')
    .listen(printOnFailure);

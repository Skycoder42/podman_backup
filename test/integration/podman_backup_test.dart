import 'dart:io';

import 'package:test/test.dart';
import '../../bin/podman_backup.dart' as podman_backup;

void main() {
  final debugOverwriteLabel = Platform.environment['PODMAN_BACKUP_LABEL'];

  late Directory cacheDir;
  late Directory backupDir;

  late String timestampPrefix;

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

Future<void> _podman(List<String> arguments) => _run('podman', arguments);

Future<void> _run(String executable, List<String> arguments) async {
  final proc = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  await expectLater(proc.exitCode, completion(0));
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:podman_backup/src/podman_backup.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

abstract class IntegrationTestCase {
  late String _timestampPrefix;

  @protected
  late Directory cacheDir;
  @protected
  late Directory backupDir;

  String get name;

  void build();

  void run() {
    setUpAll(() async {
      Logger.root.level = Level.ALL;
    });

    setUp(() async {
      // ignore: avoid_print
      Logger.root.onRecord.listen(print);

      cacheDir = await Directory.systemTemp.createTemp();
      backupDir = await Directory.systemTemp.createTemp();

      _timestampPrefix = DateTime.now()
          .toUtc()
          .toIso8601String()
          .substring(0, 10)
          .replaceAll('-', '_');
    });

    tearDown(() async {
      await backupDir.delete(recursive: true);
      await cacheDir.delete(recursive: true);

      Logger.root.clearListeners();
    });

    group(name, build);
  }

  @protected
  RegExp volumePattern(String volume) =>
      RegExp('.*\\/$volume-$_timestampPrefix(_\\d{2}){3}.tar.xz');

  @protected
  Future<void> runPodmanBackup({
    required BackupMode backupMode,
    required Directory backupDir,
    required Directory cacheDir,
  }) async {
    final di = ProviderContainer();
    addTearDown(di.dispose);
    await di.read(podmanBackupProvider).run(
          Options(
            remoteHostRaw: 'integration_test_local:${backupDir.path}',
            remoteHostRawWasParsed: true,
            backupMode: backupMode,
            backupCache: cacheDir.path,
          ),
        );
  }

  @protected
  Future<void> createVolume(String name, {bool backedUp = true}) async {
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

  @protected
  Future<void> startService(String service) async {
    await _systemctl(['start', service]);
    addTearDown(() => _run('journalctl', ['--user', '-u', service]));
    addTearDown(() => _systemctl(['stop', service]));
  }

  @protected
  Stream<String> journalctl(String service) =>
      _stream('journalctl', ['--user', '-u', service]);

  Future<void> _podman(List<String> arguments) => _run('podman', arguments);

  Future<void> _systemctl(List<String> arguments) =>
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

  Stream<String> _stream(String executable, List<String> arguments) async* {
    printOnFailure('> Streaming: $executable $arguments');
    final proc = await Process.start(
      executable,
      arguments,
    );
    _streamLogs('>! ', proc.stderr);

    yield* proc.stdout
        .transform(systemEncoding.decoder)
        .transform(const LineSplitter());

    final exitCode = await proc.exitCode;
    printOnFailure('>= Exit code: $exitCode');
    expect(exitCode, 0);
  }

  void _streamLogs(String prefix, Stream<List<int>> stream) => stream
      .transform(systemEncoding.decoder)
      .transform(const LineSplitter())
      .map((line) => '$prefix$line')
      .listen(printOnFailure);
}

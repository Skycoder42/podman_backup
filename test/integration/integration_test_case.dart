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
      Logger.root.onRecord.listen(_printLogRecord);

      cacheDir = await Directory.systemTemp.createTemp();
      backupDir = await Directory.systemTemp.createTemp();

      _timestampPrefix = DateTime.now()
          .toUtc()
          .toIso8601String()
          .substring(0, 10)
          .replaceAll('-', '_');
    });

    tearDown(() async {
      // clear journald logs
      await _run('sudo', ['journalctl', '--user', '--rotate']);
      await Future.delayed(const Duration(seconds: 1));
      await _run('sudo', ['journalctl', '--user', '--vacuum-time=1s']);

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
            backupLabel: Options.defaultBackupLabel,
            backupMode: backupMode,
            backupCache: cacheDir,
            user: true,
            minKeep: 1,
            maxKeep: null,
            maxAge: null,
            maxTotalSize: null,
            logLevel: Level.ALL,
          ),
        );
  }

  @protected
  Future<void> createVolume(
    String name, {
    bool backedUp = true,
    String? hook,
  }) async {
    final label = Platform.environment['PODMAN_BACKUP_LABEL'] ??
        'de.skycoder42.podman_backup';
    await _podman([
      'volume',
      'create',
      if (backedUp) ...[
        '--label',
        if (hook != null) '$label=$hook' else label,
      ],
      name,
    ]);
    addTearDown(() => _podman(['volume', 'rm', '--force', name]));

    final tmpDir = await Directory.systemTemp.createTemp();
    try {
      final tarFile = File.fromUri(tmpDir.uri.resolve('data.tar'));
      await File.fromUri(tmpDir.uri.resolve('data.txt')).writeAsString(name);
      await _run('tar', ['-cf', tarFile.path, '.'], tmpDir);
      await _podman(['volume', 'import', name, tarFile.path]);
    } finally {
      await tmpDir.delete(recursive: true);
    }
  }

  @protected
  Future<void> verifyVolume(
    Directory backupDir,
    String name, {
    bool withInfo = false,
  }) async {
    printOnFailure('Files in $backupDir: ${backupDir.listSync()}');

    final pattern = volumePattern(name);
    final volumeFile = await backupDir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .singleWhere((f) => pattern.hasMatch(f.path));

    final outDir = await Directory.systemTemp.createTemp();
    try {
      await _run('tar', ['-xf', volumeFile.path, '-C', outDir.path]);
      await verifyVolumeContent(outDir, name, withInfo: withInfo);
    } finally {
      await outDir.delete(recursive: true);
    }
  }

  @protected
  Future<void> verifyVolumeContent(
    Directory volumeDir,
    String name, {
    bool withInfo = false,
  }) async {
    printOnFailure(
      'Contents of $volumeDir: ${volumeDir.listSync(recursive: true)}',
    );
    final dataFile = File.fromUri(volumeDir.uri.resolve('data.txt'));
    expect(dataFile.existsSync(), isTrue);
    await expectLater(dataFile.readAsString(), completion(name));

    if (withInfo) {
      final infoFile = File.fromUri(volumeDir.uri.resolve('backup.info'));
      expect(infoFile.existsSync(), isTrue);
      await expectLater(infoFile.readAsString(), completion(name));
    }
  }

  @protected
  Future<void> startService(String service) async {
    await _systemctl(['start', service]);
    logUnitOnFailure(service);
    addTearDown(() => _systemctl(['stop', service]));
  }

  void logUnitOnFailure(String unitName) =>
      // ignore: discarded_futures
      addTearDown(() => _run('journalctl', ['--user', '-u', unitName]));

  @protected
  Stream<String> journalctl(String service) =>
      _stream('journalctl', ['--user', '-u', service]);

  Future<void> _podman(List<String> arguments) => _run('podman', arguments);

  Future<void> _systemctl(List<String> arguments) =>
      _run('systemctl', ['--user', ...arguments]);

  Future<void> _run(
    String executable,
    List<String> arguments, [
    Directory? pwd,
  ]) async {
    printOnFailure('> Invoking: $executable $arguments');
    final proc = await Process.start(
      executable,
      arguments,
      workingDirectory: pwd?.path,
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

  void _printLogRecord(LogRecord logRecord) =>
      // ignore: avoid_print
      print('${logRecord.time.toIso8601String()} $logRecord');
}

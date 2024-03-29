import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/compress_adapter.dart';
import '../adapters/date_time_adapter.dart';
import '../adapters/podman_adapter.dart';
import '../adapters/systemctl_adapter.dart';
import '../models/hook.dart';
import 'backup_strategy.dart';
import 'backup_strategy_builder.dart';

// coverage:ignore-start
final backupControllerProvider = Provider(
  (ref) => BackupController(
    ref.watch(backupStrategyBuilderProvider),
    ref.watch(systemctlAdapterProvider),
    ref.watch(podmanAdapterProvider),
    ref.watch(compressAdapterProvider),
    ref.watch(dateTimeAdapterProvider),
  ),
);
// coverage:ignore-end

class BackupController {
  final BackupStrategyBuilder _backupStrategyBuilder;
  final SystemctlAdapter _systemctlAdapter;
  final PodmanAdapter _podmanAdapter;
  final CompressAdapter _compressAdapter;
  final DateTimeAdapter _dateTimeAdapter;
  final _logger = Logger('$BackupController');

  BackupController(
    this._backupStrategyBuilder,
    this._systemctlAdapter,
    this._podmanAdapter,
    this._compressAdapter,
    this._dateTimeAdapter,
  );

  Future<void> backup({
    required String backupLabel,
    required Directory cacheDir,
  }) async {
    _logger.info('Building strategy');
    final strategy = await _backupStrategyBuilder.buildStrategy(
      backupLabel: backupLabel,
    );

    _logger.info('Executing strategy');
    while (strategy.next()) {
      await _backupStep(strategy, cacheDir);
    }
    _logger.info('Strategy finished');
  }

  Future<void> _backupStep(
    BackupStrategy strategy,
    Directory cacheDir,
  ) async {
    _logger.info(
      'Backing up volumes: ${strategy.volumes.map((t) => t.$1).toList()}',
    );
    try {
      _logger.fine('Stopping services: ${strategy.services}');
      await Future.wait(strategy.services.map(_systemctlAdapter.stop));

      for (final (volume, hook) in strategy.volumes) {
        if (hook != null) {
          _logger.fine('Executing backup hook: $hook');
          await _systemctlAdapter.start(await _getUnitName(hook, volume));
          if (!hook.preHook) {
            _logger.finer('Skipping normal backup because of pre-hook');
            continue;
          }
        }

        await _createVolumeBackup(volume, cacheDir);
      }
    } finally {
      _logger.fine('Restarting services: ${strategy.services}');
      await Future.wait(
        strategy.services.map(
          (service) => _systemctlAdapter.start(service).catchError(
                test: (error) => error is Exception,
                // ignore: avoid_types_on_closure_parameters
                (Object e) => _logger.warning(
                  'Failed to restart $service with error:',
                  e,
                ),
              ),
        ),
      );
    }
  }

  Future<void> _createVolumeBackup(String volume, Directory cacheDir) async {
    final date = _dateTimeAdapter.utcNow
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(RegExp(r'\D'), '_');
    final backupFile = File.fromUri(
      cacheDir.uri.resolve('$volume-$date.tar.xz'),
    );

    _logger.fine('Backing up volume $volume to ${backupFile.path}');
    await _podmanAdapter
        .volumeExport(volume)
        .transform(_compressAdapter)
        .pipe(backupFile.openWrite());
  }

  Future<String> _getUnitName(Hook hook, String volume) {
    if (hook.isTemplate) {
      return _systemctlAdapter.escape(
        template: hook.systemdUnit,
        value: volume,
      );
    } else {
      return Future.value(hook.systemdUnit);
    }
  }
}

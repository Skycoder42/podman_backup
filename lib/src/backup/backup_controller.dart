import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../adapters/compress_adapter.dart';
import '../adapters/date_time_adapter.dart';
import '../adapters/podman_adapter.dart';
import '../adapters/systemd_adapter.dart';
import 'backup_strategy.dart';
import 'backup_strategy_builder.dart';

// coverage:ignore-start
final backupControllerProvider = Provider(
  (ref) => BackupController(
    ref.watch(backupStrategyBuilderProvider),
    ref.watch(systemdAdapterProvider),
    ref.watch(podmanAdapterProvider),
    ref.watch(compressAdapterProvider),
    ref.watch(dateTimeAdapterProvider),
  ),
);
// coverage:ignore-end

class BackupController {
  final BackupStrategyBuilder _backupStrategyBuilder;
  final SystemdAdapter _systemdAdapter;
  final PodmanAdapter _podmanAdapter;
  final CompressAdapter _compressAdapter;
  final DateTimeAdapter _dateTimeAdapter;

  BackupController(
    this._backupStrategyBuilder,
    this._systemdAdapter,
    this._podmanAdapter,
    this._compressAdapter,
    this._dateTimeAdapter,
  );

  Future<void> backup({
    required String backupLabel,
    required Directory cacheDir,
  }) async {
    final strategy = await _backupStrategyBuilder.buildStrategy(
      backupLabel: backupLabel,
    );

    while (strategy.next()) {
      await _backupStep(strategy, cacheDir);
    }
  }

  Future<void> _backupStep(BackupStrategy strategy, Directory cacheDir) async {
    try {
      for (final service in strategy.services) {
        await _systemdAdapter.stop(service);
      }

      for (final volume in strategy.volumes) {
        await _createVolumeBackup(volume, cacheDir);
      }
    } finally {
      for (final service in strategy.services) {
        try {
          await _systemdAdapter.start(service);
        } on Exception catch (e) {
          // ignore: avoid_print
          print('WARNING: Failed to restart $service with error: $e');
        }
      }
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

    await _podmanAdapter
        .volumeExport(volume)
        .transform(_compressAdapter)
        .pipe(backupFile.openWrite());
  }
}

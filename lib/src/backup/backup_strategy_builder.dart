import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/podman_adapter.dart';
import '../models/container.dart';
import '../models/hook.dart';
import '../models/volume.dart';
import 'backup_strategy.dart';

// coverage:ignore-start
final backupStrategyBuilderProvider = Provider(
  (ref) => BackupStrategyBuilder(ref.watch(podmanAdapterProvider)),
);
// coverage:ignore-end

class BackupStrategyBuilder {
  final PodmanAdapter _podmanAdapter;
  final _logger = Logger('$BackupStrategyBuilder');

  BackupStrategyBuilder(this._podmanAdapter);

  Future<BackupStrategy> buildStrategy({required String backupLabel}) async {
    _logger.fine('Loading volumes with label $backupLabel');
    final volumes = await _podmanAdapter.volumeList(
      filters: {'label': backupLabel},
    );
    _logger.finest('Found volumes: $volumes');

    final strategyData = <String, VolumeDetails>{};
    for (final volume in volumes) {
      _logger.fine('Loading attached services for volume $volume');
      final hook = _getHook(volume, backupLabel);
      final attachedServices = await _getContainerUnits(volume);
      strategyData[volume.name] = (hook, attachedServices);
      _logger.finest('Found referencing services: $attachedServices');
    }

    _logger.fine('Building backup strategy');
    return BackupStrategy(strategyData);
  }

  Hook? _getHook(Volume volume, String backupLabel) {
    final labelValue = volume.labels[backupLabel];
    if (labelValue == null || labelValue.isEmpty) {
      return null;
    }
    return Hook.parse(labelValue);
  }

  Future<Set<String>> _getContainerUnits(Volume volume) =>
      _findAttachedContainers(volume)
          .map((c) => c.labels['PODMAN_SYSTEMD_UNIT'])
          .where((c) => c != null)
          .cast<String>()
          .toSet();

  Stream<Container> _findAttachedContainers(Volume volume) async* {
    final containers = await _podmanAdapter.ps(
      filters: {'volume': volume.name},
    );

    yield* Stream.fromIterable(containers).asyncMap(_findPodInfraContainer);
  }

  Future<Container> _findPodInfraContainer(Container container) async {
    if (container.pod.isEmpty || container.isInfra) {
      return container;
    }

    final podContainers = await _podmanAdapter.ps(
      filters: {'pod': container.pod},
    );
    return podContainers.singleWhere((c) => c.isInfra);
  }
}

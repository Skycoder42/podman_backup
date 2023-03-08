import 'package:riverpod/riverpod.dart';

import '../adapters/podman_adapter.dart';
import '../models/volume_configuration.dart';

// coverage:ignore-start
final volumeConfigurationLoaderProvider = Provider(
  (ref) => VolumeConfigurationLoader(
    ref.watch(podmanAdapterProvider),
  ),
);
// coverage:ignore-end

class VolumeConfigurationLoader {
  final PodmanAdapter _podmanAdapter;

  VolumeConfigurationLoader(this._podmanAdapter);

  Stream<VolumeConfiguration> loadVolumeConfigurations(
    String backupLabel,
  ) async* {
    final volumes = await _podmanAdapter.volumeList(
      filters: {
        'label': backupLabel,
      },
    );

    for (final volume in volumes) {
      final attachedContainers = await _podmanAdapter.ps(
        filters: {
          'volume': volume.name,
        },
      );

      yield VolumeConfiguration(
        volume: volume,
        attachedContainers: attachedContainers,
      );
    }
  }
}

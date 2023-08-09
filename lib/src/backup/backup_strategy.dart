import 'package:meta/meta.dart';

import '../models/hook.dart';

typedef VolumeDetails = (Hook? hook, Set<String> services);

typedef VolumeWithLabel = (String volume, Hook? hook);

class BackupStrategy {
  final Map<String, VolumeDetails> _pendingVolumes;

  final _activeVolumes = <VolumeWithLabel>[];
  final _activeServices = <String>{};

  BackupStrategy(this._pendingVolumes);

  bool next() {
    _activeVolumes.clear();
    _activeServices.clear();

    if (_pendingVolumes.isEmpty) {
      return false;
    }

    _processVolume(_pendingVolumes.keys.first);
    return true;
  }

  List<VolumeWithLabel> get volumes => _activeVolumes;

  List<String> get services => _activeServices.toList();

  void _processVolume(String nextVolume) {
    assert(_pendingVolumes.containsKey(nextVolume));

    final (hook, services) = _pendingVolumes.remove(nextVolume)!;
    for (final service in services) {
      if (_activeServices.add(service)) {
        _pendingVolumes.entries
            .where((entry) => entry.value.$2.contains(service))
            .map((entry) => entry.key)
            .toList() // to prevent concurrent modification
            .forEach(_processVolume);
      }
    }
    _activeVolumes.add((nextVolume, hook));
  }

  @visibleForTesting
  Map<String, VolumeDetails> get debugTestInternalVolumes => _pendingVolumes;
}

import '../adapters/podman_adapter.dart';

class BackupStrategy {
  final PodmanAdapter _podmanAdapter;

  final Map<String, Set<String>> _pendingVolumes;

  final _activeVolumes = <String>[];
  final _activeServices = <String>{};

  BackupStrategy(this._podmanAdapter, this._pendingVolumes);

  bool next() {
    _activeVolumes.clear();
    _activeServices.clear();

    if (_pendingVolumes.isEmpty) {
      return false;
    }

    _processVolume(_pendingVolumes.keys.first);
    return true;
  }

  List<String> get volumes => _activeVolumes;

  List<String> get services => _activeServices.toList();

  void _processVolume(String nextVolume) {
    assert(_pendingVolumes.containsKey(nextVolume));

    final attachedServices = _pendingVolumes.remove(nextVolume)!;
    for (final service in attachedServices) {
      if (_activeServices.add(service)) {
        _pendingVolumes.entries
            .where((entry) => entry.value.contains(service))
            .map((entry) => entry.key)
            .forEach(_processVolume);
      }
    }
    _activeVolumes.add(nextVolume);
  }
}

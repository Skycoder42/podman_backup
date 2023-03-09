import '../adapters/podman_adapter.dart';
import '../models/volume.dart';

class BackupStrategy {
  final PodmanAdapter _podmanAdapter;

  final List<Volume> _pendingVolumes;

  BackupStrategy(this._podmanAdapter, this._pendingVolumes);

  Future<bool> next() => throw UnimplementedError();

  List<Volume> get volumes => throw UnimplementedError();

  List<String> get services => throw UnimplementedError();
}

import 'package:injectable/injectable.dart';

import '../models/container.dart';
import '../models/volume.dart';
import 'process_adapter.dart';

@injectable
class PodmanAdapter {
  final ProcessAdapter _processAdapter;

  const PodmanAdapter(this._processAdapter);

  Future<List<Container>> ps({
    bool all = false,
    Map<String, String> filters = const {},
  }) => _streamPodmanList([
    'ps',
    '--format',
    'json',
    if (all) '--all',
    for (final filter in filters.entries) ...[
      '--filter',
      '${filter.key}=${filter.value}',
    ],
  ], Container.fromJsonList);

  Future<List<Volume>> volumeList({Map<String, String> filters = const {}}) =>
      _streamPodmanList([
        'volume',
        'list',
        '--format',
        'json',
        for (final filter in filters.entries) ...[
          '--filter',
          '${filter.key}=${filter.value}',
        ],
      ], Volume.fromJsonList);

  Stream<List<int>> volumeExport(String volume) =>
      _processAdapter.streamRaw('podman', ['volume', 'export', volume]);

  Future<List<T>> _streamPodmanList<T extends Object>(
    List<String> arguments,
    List<T> Function(List<dynamic>) construct,
  ) => _processAdapter
      .streamJson('podman', arguments)
      .then((object) => construct(object! as List<dynamic>));
}

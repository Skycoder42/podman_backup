import 'package:riverpod/riverpod.dart';

import '../models/container.dart';
import '../models/volume.dart';
import 'process_adapter.dart';

// coverage:ignore-start
final podmanAdapterProvider = Provider(
  (ref) => PodmanAdapter(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class PodmanAdapter {
  final ProcessAdapter _processAdapter;

  PodmanAdapter(this._processAdapter);

  Future<List<Volume>> volumeList({List<String> filters = const []}) =>
      _streamPodmanList(
        [
          'volume',
          'list',
          '--format',
          'json',
          for (final filter in filters) ...['--filter', filter],
        ],
        Volume.fromJsonList,
      );

  Future<List<Container>> ps({
    bool all = false,
    List<String> filters = const [],
  }) =>
      _streamPodmanList(
        [
          'ps',
          '--format',
          'json',
          if (all) '--all',
          for (final filter in filters) ...['--filter', filter],
        ],
        Container.fromJsonList,
      );

  Future<List<T>> _streamPodmanList<T extends Object>(
    List<String> arguments,
    List<T> Function(List<dynamic>) construct,
  ) =>
      _processAdapter
          .streamJson('podman', arguments)
          .cast<List<dynamic>>()
          .map(construct)
          .single;
}

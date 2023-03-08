import 'package:riverpod/riverpod.dart';

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

  Future<List<Volume>> volumeList({List<String> filters = const []}) async =>
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

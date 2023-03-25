import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:riverpod/riverpod.dart';

import 'process_adapter.dart';

// coverage:ignore-start
final compressAdapterProvider = Provider(
  (ref) => CompressAdapter(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class CompressAdapter extends StreamTransformerBase<List<int>, List<int>> {
  final ProcessAdapter _processAdapter;

  CompressAdapter(this._processAdapter);

  Stream<List<int>> compress(Stream<List<int>> stream) => bind(stream);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) => _processAdapter.streamRaw(
        'xz',
        [
          '--compress',
          '-9',
          '--threads',
          max(Platform.numberOfProcessors ~/ 2, 1).toString(),
        ],
        stdin: stream,
      );
}

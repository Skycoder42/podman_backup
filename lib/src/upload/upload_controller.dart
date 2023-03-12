import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../adapters/process_adapter.dart';

// coverage:ignore-start
final uploadControllerProvider = Provider(
  (ref) => UploadController(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class UploadController {
  final ProcessAdapter _processAdapter;

  UploadController(this._processAdapter);

  Future<void> upload({
    required String remoteHost,
    required Directory cacheDir,
  }) async {
    await _processAdapter.run('rsync', [
      '--times',
      '--remove-source-files',
      '--human-readable',
      '--fsync',
      cacheDir.path,
      remoteHost,
    ]);
  }
}

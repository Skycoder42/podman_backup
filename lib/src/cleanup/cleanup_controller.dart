import 'package:riverpod/riverpod.dart';

import 'cleanup_filter.dart';
import 'remote_file_proxy.dart';

// coverage:ignore-start
final cleanupControllerProvider = Provider(
  (ref) => CleanupController(
    ref.watch(remoteFileProxyProvider),
    ref.watch(cleanupFilterProvider),
  ),
);
// coverage:ignore-end

class CleanupController {
  final RemoteFileProxy _remoteFileProxy;
  final CleanupFilter _cleanupFilter;

  CleanupController(
    this._remoteFileProxy,
    this._cleanupFilter,
  );

  Future<void> cleanupOldBackups(
    String remoteHost, {
    int minKeep = 1,
    int? maxKeep,
    Duration? maxAge,
    int? maxBytesTotal,
  }) async {
    final remoteFiles = _remoteFileProxy.listRemoteFiles(remoteHost);

    final filesToDelete = await _cleanupFilter.collectDeletableFiles(
      remoteFiles,
      minKeep: minKeep,
      maxKeep: maxKeep,
      maxAge: maxAge,
      maxBytesTotal: maxBytesTotal,
    );

    if (filesToDelete.isNotEmpty) {
      await _remoteFileProxy.deleteFiles(remoteHost, filesToDelete);
    }
  }
}

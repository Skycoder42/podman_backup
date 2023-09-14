import 'package:logging/logging.dart';
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
  final _logger = Logger('$CleanupController');

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
    _logger.info('Building cleanup strategy');
    final remoteFiles = _remoteFileProxy.listRemoteFiles(remoteHost);

    final filesToDelete = await _cleanupFilter.collectDeletableFiles(
      remoteFiles,
      minKeep: minKeep,
      maxKeep: maxKeep,
      maxAge: maxAge,
      maxBytesTotal: maxBytesTotal,
    );

    if (filesToDelete.isNotEmpty) {
      _logger.info(
        'Executing cleanup - deleting ${filesToDelete.length} backups',
      );
      await _remoteFileProxy.deleteFiles(remoteHost, filesToDelete);
      _logger.info('Cleanup finished');
    } else {
      _logger.info('No backups need to be cleaned up!');
    }
  }
}

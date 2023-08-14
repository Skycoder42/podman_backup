import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final cleanupControllerProvider = Provider(
  (ref) => CleanupController(),
);
// coverage:ignore-end

class CleanupController {
  final _logger = Logger('$CleanupController');

  Future<void> cleanupOldBackups({
    int? maxCount,
    Duration? maxAge,
    int? maxBytesTotal,
  }) async {
    if (maxCount == null && maxAge == null && maxBytesTotal == null) {
      _logger.warning('No cleanup filters specified. Skipping cleanup step.');
      return;
    }

    // list all remote files

    // apply count filter

    // apply age filter

    // apply size filter
  }
}

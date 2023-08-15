import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../models/remote_file_info.dart';
import 'map_values_x.dart';

// coverage:ignore-start
final cleanupFilterProvider = Provider(
  (ref) => CleanupFilter(),
);
// coverage:ignore-end

typedef _InfoMap = Map<String, Iterable<RemoteFileInfo>>;

class CleanupFilter {
  final _logger = Logger('$CleanupFilter');

  Set<RemoteFileInfo> filterDeletableFiles(
    Map<String, Iterable<RemoteFileInfo>> filesAllowedToBeDeleted, {
    int? maxKeep,
    Duration? maxAge,
    int? maxBytesTotal,
  }) {
    if (maxKeep == null && maxAge == null && maxBytesTotal == null) {
      _logger.warning('No cleanup filters specified. Skipping cleanup step.');
      return const {};
    }

    var filesToKeep = filesAllowedToBeDeleted;

    // apply count filter
    if (maxKeep != null) {
      filesToKeep = _filterCount(filesToKeep, maxKeep);
    }

    // apply age filter
    if (maxAge != null) {
      filesToKeep = _filterAge(filesToKeep, maxAge);
    }

    // apply size filter
    var allFilesToKeep = filesToKeep.values.expand((infos) => infos);
    if (maxBytesTotal != null) {
      allFilesToKeep = _filterSize(allFilesToKeep, maxBytesTotal);
    }

    // calculate deletion diff
    final filesToDelete = filesAllowedToBeDeleted.values
        .expand((infos) => infos)
        .toSet()
        .difference(allFilesToKeep.toSet());
    return filesToDelete;
  }

  _InfoMap _filterCount(_InfoMap infoMap, int maxKeep) =>
      infoMap.forValues((value) => value.take(maxKeep));

  _InfoMap _filterAge(_InfoMap infoMap, Duration maxAge) {
    final minDate = DateTime.now().subtract(maxAge);
    return infoMap.forValues(
      (value) => value.where((info) => info.backupDate.isAfter(minDate)),
    );
  }

  Iterable<RemoteFileInfo> _filterSize(
    Iterable<RemoteFileInfo> infos,
    int maxBytesTotal,
  ) {
    var sizeSum = 0;
    return infos
        .sortedByCompare(
          (info) => info.sizeInBytes,
          (a, b) => a - b,
        )
        .takeWhile((info) => (sizeSum += info.sizeInBytes) <= maxBytesTotal);
  }
}

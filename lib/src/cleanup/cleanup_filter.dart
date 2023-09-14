import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/transformers.dart';

import '../adapters/date_time_adapter.dart';
import '../models/remote_file_info.dart';
import 'map_extensions.dart';

// coverage:ignore-start
final cleanupFilterProvider = Provider(
  (ref) => CleanupFilter(
    ref.watch(dateTimeAdapterProvider),
  ),
);
// coverage:ignore-end

typedef _InfoMap = Map<String, Iterable<RemoteFileInfo>>;

class CleanupFilter {
  final DateTimeAdapter _dateTime;
  final _logger = Logger('$CleanupFilter');

  CleanupFilter(this._dateTime);

  Future<Set<RemoteFileInfo>> collectDeletableFiles(
    Stream<RemoteFileInfo> remoteFiles, {
    required int minKeep,
    int? maxKeep,
    Duration? maxAge,
    int? maxBytesTotal,
  }) async {
    if (minKeep < 1) {
      throw ArgumentError.value(
        minKeep,
        'minKeep',
        'Must keep at least one backup',
      );
    }

    if (maxKeep == null && maxAge == null && maxBytesTotal == null) {
      _logger.warning('No cleanup filters specified. Skipping cleanup step.');
      return const {};
    }

    _logger.fine('Securing $minKeep backups for every volume');
    final (filesAllowedToBeDeleted, bytesToKeep) = await _collectDeletableFiles(
      remoteFiles,
      minKeep,
    );
    var filesToKeep = filesAllowedToBeDeleted;

    // apply count filter
    if (maxKeep != null) {
      _logger.fine('Filter out old backups if there are more than $maxKeep');
      filesToKeep = _filterCount(filesToKeep, minKeep, maxKeep);
    }

    // apply age filter
    if (maxAge != null) {
      _logger.fine('Filter out backups older than ${maxAge.inDays} days');
      filesToKeep = _filterAge(filesToKeep, maxAge);
    }

    // apply size filter
    var allFilesToKeep = filesToKeep.values.expand((infos) => infos);
    if (maxBytesTotal != null) {
      _logger.fine(
        'Filter out old backups to limit backups size to '
        '${maxBytesTotal / (1024 * 1024)} MB',
      );
      allFilesToKeep = _filterSize(allFilesToKeep, bytesToKeep, maxBytesTotal);
    }

    // calculate deletion diff
    final filesToDelete = filesAllowedToBeDeleted.values
        .expand((infos) => infos)
        .toSet()
        .difference(allFilesToKeep.toSet());
    _logger.fine('Found ${filesToDelete.length} backups to be deleted');
    for (final file in filesToDelete) {
      _logger.finest('- ${file.fileName}');
    }
    return filesToDelete;
  }

  Future<(_InfoMap, int)> _collectDeletableFiles(
    Stream<RemoteFileInfo> files,
    int minKeep,
  ) async {
    var bytesToKeep = 0;

    final infoMap = await files
        .groupBy((info) => info.volume)
        .collect()
        .mapValue(
          (infos) => infos
              .sortedBy((info) => info.backupDate)
              .reversed
              .extract(minKeep, (i) => bytesToKeep += i.sizeInBytes)
              // .toList is required to not iterate this multiple times
              .toList(),
        )
        .toMap();

    return (infoMap, bytesToKeep);
  }

  _InfoMap _filterCount(_InfoMap infoMap, int minKeep, int maxKeep) {
    if (maxKeep < minKeep) {
      throw ArgumentError.value(
        maxKeep,
        'maxKeep',
        'Must be greater or equal than minKeep ($minKeep)',
      );
    }

    return infoMap.forValues((value) => value.take(maxKeep - minKeep));
  }

  _InfoMap _filterAge(_InfoMap infoMap, Duration maxAge) {
    final minDate = _dateTime.utcNow.subtract(maxAge);
    return infoMap.forValues(
      (value) => value.where((info) => !info.backupDate.isBefore(minDate)),
    );
  }

  Iterable<RemoteFileInfo> _filterSize(
    Iterable<RemoteFileInfo> infos,
    int bytesToKeep,
    int maxBytesTotal,
  ) {
    var sizeSum = bytesToKeep;
    return infos
        .sortedBy((info) => info.backupDate)
        .reversed
        .takeWhile((info) => (sizeSum += info.sizeInBytes) <= maxBytesTotal);
  }
}

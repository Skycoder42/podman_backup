import 'package:riverpod/riverpod.dart';

import '../models/volume.dart';

// coverage:ignore-start
final backupStrategyProvider = Provider(
  (ref) => BackupStrategy(),
);
// coverage:ignore-end

class BackupStrategy {
  bool get isFinished => throw UnimplementedError();

  List<Volume> get volumes => throw UnimplementedError();

  List<String> get services => throw UnimplementedError();

  bool next() => throw UnimplementedError();
}

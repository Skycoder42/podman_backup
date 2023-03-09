import '../models/volume.dart';

class BackupStrategy {
  bool get isFinished => throw UnimplementedError();

  List<Volume> get volumes => throw UnimplementedError();

  List<String> get services => throw UnimplementedError();

  Future<void> next() => throw UnimplementedError();
}

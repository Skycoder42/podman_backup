import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/backup/backup_strategy_builder.dart';
import 'package:test/test.dart';

class MockPodmanAdapter extends Mock implements PodmanAdapter {}

void main() {
  group('$BackupStrategyBuilder', () {
    final mockPodmanAdapter = MockPodmanAdapter();

    late BackupStrategyBuilder sut;

    setUp(() {
      reset(mockPodmanAdapter);

      sut = BackupStrategyBuilder(mockPodmanAdapter);
    });

    group('buildStrategy', () {
      test('collects all volumes by label', () {
        sut.runtimeType;
        fail('TODO');
      });
    });
  });
}

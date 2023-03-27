import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/backup/backup_strategy_builder.dart';
import 'package:podman_backup/src/models/container.dart';
import 'package:podman_backup/src/models/volume.dart';
import 'package:test/test.dart';

class MockPodmanAdapter extends Mock implements PodmanAdapter {}

void main() {
  group('$BackupStrategyBuilder', () {
    const testLabel = 'test-label';

    final mockPodmanAdapter = MockPodmanAdapter();

    late BackupStrategyBuilder sut;

    setUp(() {
      reset(mockPodmanAdapter);

      sut = BackupStrategyBuilder(mockPodmanAdapter);
    });

    group('buildStrategy', () {
      test('collects all volumes by label', () async {
        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(const []);

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, isEmpty);
        verify(
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
        );
      });

      test('checks for attached services for each volume', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';

        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(
          const [
            Volume(name: testVolume1, labels: {}),
            Volume(name: testVolume2, labels: {})
          ],
        );
        when(() => mockPodmanAdapter.ps(filters: any(named: 'filters')))
            .thenReturnAsync(const []);

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, hasLength(2));
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume1, isEmpty),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume2, isEmpty),
        );

        verifyInOrder([
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume1}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume2}),
        ]);
      });

      test('creates backup strategy from volumes and services', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';
        const testVolume3 = 'test-volume-3';
        const testContainer1 = 'test-container-1';
        const testContainer2 = 'test-container-2';
        const testContainer3 = 'test-container-3';
        const testContainer4 = 'test-container-4';
        const testContainer5 = 'test-container-5';

        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(
          const [
            Volume(name: testVolume1, labels: {}),
            Volume(name: testVolume2, labels: {}),
            Volume(name: testVolume3, labels: {})
          ],
        );
        when(
          () => mockPodmanAdapter.ps(
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((i) async {
          final filters = i.namedArguments[#filters] as Map<String, String>;
          final volumeFilter = filters['volume'];
          switch (volumeFilter) {
            case testVolume1:
              return [
                _createContainer(testContainer1),
                _createContainer(testContainer2, withLabel: false),
              ];
            case testVolume2:
              return [
                _createContainer(testContainer2),
                _createContainer(testContainer3, withLabel: false),
                _createContainer(testContainer4),
              ];
            case testVolume3:
              return [
                _createContainer(testContainer1),
                _createContainer(testContainer3),
                _createContainer(testContainer5),
              ];
            default:
              throw ArgumentError('Invalid filters: $filters');
          }
        });

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, hasLength(3));
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume1, _services([testContainer1])),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume2,
            _services([testContainer2, testContainer4]),
          ),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume3,
            _services([testContainer1, testContainer3, testContainer5]),
          ),
        );

        verifyInOrder([
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume1}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume2}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume3}),
        ]);
      });
    });
  });
}

Container _createContainer(String containerName, {bool withLabel = true}) =>
    Container(
      id: containerName,
      exited: false,
      isInfra: false,
      names: [containerName],
      labels: {
        if (withLabel) 'PODMAN_SYSTEMD_UNIT': '$containerName.service',
      },
      pod: '',
      podName: '',
    );

Set<String> _services(List<String> containers) =>
    containers.map((c) => '$c.service').toSet();

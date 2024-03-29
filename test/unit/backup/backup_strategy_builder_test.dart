import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/backup/backup_strategy_builder.dart';
import 'package:podman_backup/src/models/container.dart';
import 'package:podman_backup/src/models/hook.dart';
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
        verifyNoMoreInteractions(mockPodmanAdapter);
      });

      test('checks for attached services for each volume', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';

        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(
          const [
            Volume(name: testVolume1, labels: {}),
            Volume(name: testVolume2, labels: {}),
          ],
        );
        when(() => mockPodmanAdapter.ps(filters: any(named: 'filters')))
            .thenReturnAsync(const []);

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, hasLength(2));
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume1, isRecord(null, <String>{})),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume2, isRecord(null, <String>{})),
        );

        verifyInOrder([
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume1}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume2}),
        ]);
        verifyNoMoreInteractions(mockPodmanAdapter);
      });

      test('adds hook configuration if the label has a value', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';

        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(
          const [
            Volume(name: testVolume1, labels: {testLabel: ''}),
            Volume(
              name: testVolume2,
              labels: {testLabel: 'test-1.service'},
            ),
          ],
        );
        when(() => mockPodmanAdapter.ps(filters: any(named: 'filters')))
            .thenReturnAsync(const []);

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, hasLength(2));
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(testVolume1, isRecord(null, <String>{})),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume2,
            isRecord(const Hook(unit: 'test-1', type: 'service'), <String>{}),
          ),
        );

        verifyInOrder([
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume1}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume2}),
        ]);
        verifyNoMoreInteractions(mockPodmanAdapter);
      });

      test('creates backup strategy from volumes and services', () async {
        const testVolume1 = 'test-volume-1';
        const testVolume2 = 'test-volume-2';
        const testVolume3 = 'test-volume-3';
        const testVolume4 = 'test-volume-4';
        const testContainer1 = 'test-container-1';
        const testContainer2 = 'test-container-2';
        const testContainer3 = 'test-container-3';
        const testContainer4 = 'test-container-4';
        const testContainer5 = 'test-container-5';
        const testContainer6a = 'test-container-6a';
        const testContainer6b = 'test-container-6b';
        const testContainer6i = 'test-container-6i';
        const testContainer7i = 'test-container-7i';

        when(() => mockPodmanAdapter.volumeList(filters: any(named: 'filters')))
            .thenReturnAsync(
          const [
            Volume(name: testVolume1, labels: {}),
            Volume(name: testVolume2, labels: {}),
            Volume(
              name: testVolume3,
              labels: {testLabel: '!test-service3@.service'},
            ),
            Volume(name: testVolume4, labels: {}),
          ],
        );
        when(
          () => mockPodmanAdapter.ps(
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((i) async {
          final filters = i.namedArguments[#filters] as Map<String, String>;
          final volumeFilter = filters['volume'];
          final podFilter = filters['pod'];
          switch (volumeFilter ?? podFilter) {
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
            case testVolume4:
              return [
                _createContainer(testContainer6b, pod: testContainer6i),
                _createContainer(
                  testContainer7i,
                  pod: testContainer7i,
                  isInfra: true,
                ),
              ];
            case testContainer6i:
              return [
                _createContainer(testContainer6a, pod: testContainer6i),
                _createContainer(testContainer6b, pod: testContainer6i),
                _createContainer(
                  testContainer6i,
                  pod: testContainer6i,
                  isInfra: true,
                ),
              ];
            default:
              throw ArgumentError('Invalid filters: $filters');
          }
        });

        final strategy = await sut.buildStrategy(backupLabel: testLabel);

        expect(strategy.debugTestInternalVolumes, hasLength(4));
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume1,
            isRecord(null, _services([testContainer1])),
          ),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume2,
            isRecord(null, _services([testContainer2, testContainer4])),
          ),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume3,
            isRecord(
              const Hook(
                unit: 'test-service3',
                type: 'service',
                isTemplate: true,
                preHook: true,
              ),
              _services([testContainer1, testContainer3, testContainer5]),
            ),
          ),
        );
        expect(
          strategy.debugTestInternalVolumes,
          containsPair(
            testVolume4,
            isRecord(null, _services([testContainer6i, testContainer7i])),
          ),
        );

        verifyInOrder([
          () => mockPodmanAdapter.volumeList(filters: {'label': testLabel}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume1}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume2}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume3}),
          () => mockPodmanAdapter.ps(filters: {'volume': testVolume4}),
          () => mockPodmanAdapter.ps(filters: {'pod': testContainer6i}),
        ]);
        verifyNoMoreInteractions(mockPodmanAdapter);
      });
    });
  });
}

Container _createContainer(
  String containerName, {
  bool withLabel = true,
  bool isInfra = false,
  String pod = '',
}) =>
    Container(
      id: containerName,
      exited: false,
      isInfra: isInfra,
      names: [containerName],
      labels: {
        if (withLabel) 'PODMAN_SYSTEMD_UNIT': '$containerName.service',
      },
      pod: pod,
      podName: pod.isNotEmpty ? '$pod-name' : '',
    );

Set<String> _services(List<String> containers) =>
    containers.map((c) => '$c.service').toSet();

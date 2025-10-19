import 'dart:convert';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/models/container.dart';
import 'package:podman_backup/src/models/volume.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

void main() {
  group('$PodmanAdapter', () {
    final mockProcessAdapter = MockProcessAdapter();

    late PodmanAdapter sut;

    setUp(() {
      reset(mockProcessAdapter);

      sut = PodmanAdapter(mockProcessAdapter);
    });

    group('ps', () {
      testData<(bool, Map<String, String>, List<String>)>(
        'invokes podman ps with correct arguments',
        const [
          (false, {}, []),
          (true, {}, ['--all']),
          (false, {'a': 'b'}, ['--filter', 'a=b']),
          (
            true,
            {'a': '1', 'x': 'y'},
            ['--all', '--filter', 'a=1', '--filter', 'x=y'],
          ),
        ],
        (fixture) async {
          when(
            () => mockProcessAdapter.streamJson(any(), any()),
          ).thenReturnAsync(const <dynamic>[]);

          await sut.ps(all: fixture.$1, filters: fixture.$2);

          verify(
            () => mockProcessAdapter.streamJson('podman', [
              'ps',
              '--format',
              'json',
              ...fixture.$3,
            ]),
          );
        },
      );

      test('parses returned json as container list', () {
        const expected = [
          Container(
            id: 'test-id-1',
            exited: false,
            isInfra: false,
            names: ['test-name-1', 'test-name-2'],
            labels: {'label1': '', 'label2': 'value2'},
            pod: 'test-pod',
            podName: 'test-pod-name',
          ),
          Container(
            id: 'test-id-2',
            exited: true,
            isInfra: true,
            names: [],
            labels: {},
            pod: 'test-pod',
            podName: 'test-pod-name',
          ),
        ];

        when(
          () => mockProcessAdapter.streamJson(any(), any()),
        ).thenReturnAsync(json.decode(json.encode(expected)));

        expect(sut.ps(), completion(expected));
      });
    });

    group('volumeList', () {
      testData<(Map<String, String>, List<String>)>(
        'invokes podman ps with correct arguments',
        const [
          ({}, []),
          ({'a': 'b'}, ['--filter', 'a=b']),
          ({'a': '1', 'x': 'y'}, ['--filter', 'a=1', '--filter', 'x=y']),
        ],
        (fixture) async {
          when(
            () => mockProcessAdapter.streamJson(any(), any()),
          ).thenReturnAsync(const <dynamic>[]);

          await sut.volumeList(filters: fixture.$1);

          verify(
            () => mockProcessAdapter.streamJson('podman', [
              'volume',
              'list',
              '--format',
              'json',
              ...fixture.$2,
            ]),
          );
        },
      );

      test('parses returned json as volume list', () {
        const expected = [
          Volume(name: 'test-volume-1', labels: {}),
          Volume(
            name: 'test-volume-2',
            labels: {'label1': '', 'label2': 'value2'},
          ),
        ];

        when(
          () => mockProcessAdapter.streamJson(any(), any()),
        ).thenReturnAsync(json.decode(json.encode(expected)));

        expect(sut.volumeList(), completion(expected));
      });
    });

    test('volumeExport invokes podman and returns the raw data', () async {
      const testVolume = 'test-volume';
      final outData = List.generate(200, (index) => index ~/ 2);

      when(
        () => mockProcessAdapter.streamRaw(any(), any()),
      ).thenStream(Stream.value(outData));

      await expectLater(
        sut.volumeExport(testVolume),
        emitsInAnyOrder(<dynamic>[outData, emitsDone]),
      );

      verify(
        () => mockProcessAdapter.streamRaw('podman', [
          'volume',
          'export',
          testVolume,
        ]),
      );
    });
  });
}

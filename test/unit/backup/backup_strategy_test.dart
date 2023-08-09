// ignore_for_file: prefer_const_constructors

import 'package:dart_test_tools/test.dart';
import 'package:podman_backup/src/backup/backup_strategy.dart';
import 'package:podman_backup/src/models/hook.dart';
import 'package:test/test.dart';

void main() {
  group('$BackupStrategy', () {
    const testHook1 = Hook(unit: 'service-1', type: 'service');
    const testHook2 = Hook(
      unit: 'service-2',
      type: 'container',
      isTemplate: true,
      preHook: true,
    );

    testData<
        (
          Map<String, VolumeDetails>,
          List<(List<String>, List<VolumeWithLabel>)>
        )>(
      'creates correct strategy for pending volumes',
      [
        ({}, []),
        (
          {
            'volume1': (null, {}),
          },
          [
            ([], [('volume1', null)]),
          ]
        ),
        (
          {
            'volume1': (null, {}),
            'volume2': (testHook1, {}),
            'volume3': (testHook2, {}),
          },
          [
            ([], [('volume1', null)]),
            ([], [('volume2', testHook1)]),
            ([], [('volume3', testHook2)]),
          ]
        ),
        (
          {
            'volume1': (null, {'service-A', 'service-B'}),
          },
          [
            (['service-A', 'service-B'], [('volume1', null)]),
          ]
        ),
        (
          {
            'volume1': (testHook1, {'service-A', 'service-B'}),
            'volume2': (testHook2, {'service-C', 'service-D'}),
          },
          [
            (['service-A', 'service-B'], [('volume1', testHook1)]),
            (['service-C', 'service-D'], [('volume2', testHook2)]),
          ]
        ),
        (
          {
            'volume1': (null, {'service-A', 'service-B'}),
            'volume2': (null, {'service-B', 'service-C'}),
          },
          [
            (
              ['service-A', 'service-B', 'service-C'],
              [('volume1', null), ('volume2', null)],
            ),
          ]
        ),
        (
          {
            'volume1': (null, {'service-A', 'service-B'}),
            'volume2': (null, {'service-C', 'service-D'}),
            'volume3': (testHook1, {'service-E', 'service-B'}),
          },
          [
            (
              ['service-A', 'service-B', 'service-E'],
              [('volume1', null), ('volume3', testHook1)],
            ),
            (
              ['service-C', 'service-D'],
              [('volume2', null)],
            ),
          ]
        ),
        (
          {
            'volume1': (null, {'service-A', 'service-B'}),
            'volume2': (null, {'service-C', 'service-D'}),
            'volume3': (null, {'service-E', 'service-B'}),
            'volume4': (null, {'service-F', 'service-G'}),
            'volume5': (null, {'service-H', 'service-A'}),
            'volume6': (null, {'service-G', 'service-I'}),
          },
          [
            (
              ['service-A', 'service-B', 'service-E', 'service-H'],
              [('volume1', null), ('volume3', null), ('volume5', null)],
            ),
            (
              ['service-C', 'service-D'],
              [('volume2', null)],
            ),
            (
              ['service-F', 'service-G', 'service-I'],
              [('volume4', null), ('volume6', null)],
            ),
          ]
        ),
      ],
      (fixture) {
        final sut = BackupStrategy(fixture.$1);

        expect(sut.services, isEmpty);
        expect(sut.volumes, isEmpty);

        for (final (services, volumes) in fixture.$2) {
          expect(sut.next(), isTrue);
          expect(sut.services, unorderedEquals(services));
          expect(sut.volumes, unorderedEquals(volumes));
        }

        expect(sut.next(), isFalse);
        expect(sut.services, isEmpty);
        expect(sut.volumes, isEmpty);
      },
    );
  });
}

// ignore_for_file: prefer_const_constructors

import 'package:dart_test_tools/test.dart';
import 'package:podman_backup/src/backup/backup_strategy.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('$BackupStrategy', () {
    testData<
        Tuple2<Map<String, Set<String>>,
            List<Tuple2<List<String>, List<String>>>>>(
      'creates correct strategy for pending volumes',
      [
        Tuple2({}, []),
        Tuple2({
          'volume1': {},
        }, [
          Tuple2([], ['volume1']),
        ]),
        Tuple2({
          'volume1': {},
          'volume2': {},
          'volume3': {},
        }, [
          Tuple2([], ['volume1']),
          Tuple2([], ['volume2']),
          Tuple2([], ['volume3']),
        ]),
        Tuple2({
          'volume1': {'service-A', 'service-B'},
        }, [
          Tuple2(['service-A', 'service-B'], ['volume1']),
        ]),
        Tuple2({
          'volume1': {'service-A', 'service-B'},
          'volume2': {'service-C', 'service-D'},
        }, [
          Tuple2(['service-A', 'service-B'], ['volume1']),
          Tuple2(['service-C', 'service-D'], ['volume2']),
        ]),
        Tuple2({
          'volume1': {'service-A', 'service-B'},
          'volume2': {'service-B', 'service-C'},
        }, [
          Tuple2(
            ['service-A', 'service-B', 'service-C'],
            ['volume1', 'volume2'],
          ),
        ]),
        Tuple2({
          'volume1': {'service-A', 'service-B'},
          'volume2': {'service-C', 'service-D'},
          'volume3': {'service-E', 'service-B'},
        }, [
          Tuple2(
            ['service-A', 'service-B', 'service-E'],
            ['volume1', 'volume3'],
          ),
          Tuple2(
            ['service-C', 'service-D'],
            ['volume2'],
          ),
        ]),
        Tuple2({
          'volume1': {'service-A', 'service-B'},
          'volume2': {'service-C', 'service-D'},
          'volume3': {'service-E', 'service-B'},
          'volume4': {'service-F', 'service-G'},
          'volume5': {'service-H', 'service-A'},
          'volume6': {'service-G', 'service-I'},
        }, [
          Tuple2(
            ['service-A', 'service-B', 'service-E', 'service-H'],
            ['volume1', 'volume3', 'volume5'],
          ),
          Tuple2(
            ['service-C', 'service-D'],
            ['volume2'],
          ),
          Tuple2(
            ['service-F', 'service-G', 'service-I'],
            ['volume4', 'volume6'],
          ),
        ]),
      ],
      (fixture) {
        final sut = BackupStrategy(fixture.item1);

        expect(sut.services, isEmpty);
        expect(sut.volumes, isEmpty);

        for (final set in fixture.item2) {
          expect(sut.next(), isTrue);
          expect(sut.services, unorderedEquals(set.item1));
          expect(sut.volumes, unorderedEquals(set.item2));
        }

        expect(sut.next(), isFalse);
        expect(sut.services, isEmpty);
        expect(sut.volumes, isEmpty);
      },
    );
  });
}

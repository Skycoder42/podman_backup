import 'package:podman_backup/src/cleanup/map_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('MapValuesX', () {
    test('map maps values', () {
      const data = {
        'a': [1, 2, 3],
        'b': [2, 4, 6],
        'c': [10],
      };

      final result = data.forValues((value) => value.map((e) => 2 * e));

      expect(result, const {
        'a': [2, 4, 6],
        'b': [4, 8, 12],
        'c': [20],
      });
    });
  });

  group('MapEntryStreamX', () {
    test('mapValue maps values', () {
      const data = {
        'a': 1,
        'b': 2,
        'c': 4,
      };

      final result = Stream.fromIterable(data.entries).mapValue((v) => v * 2);

      expect(
        result,
        emitsInOrder([
          isA<MapEntry<String, int>>()
              .having((m) => m.key, 'key', 'a')
              .having((m) => m.value, 'value', 2),
          isA<MapEntry<String, int>>()
              .having((m) => m.key, 'key', 'b')
              .having((m) => m.value, 'value', 4),
          isA<MapEntry<String, int>>()
              .having((m) => m.key, 'key', 'c')
              .having((m) => m.value, 'value', 8),
          emitsDone,
        ]),
      );
    });

    test('toMap converts stream to map', () async {
      const data = {
        'a': 1,
        'b': 2,
        'c': 4,
      };

      expect(
        Stream.fromIterable(data.entries).toMap(),
        completion(data),
      );
    });
  });
}

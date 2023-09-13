// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/cleanup/map_extensions.dart';
import 'package:rxdart/transformers.dart';
import 'package:test/test.dart';

class MockEventSink<T> extends Mock implements EventSink<T> {}

void main() {
  group('$ListCollectionTransformerSink', () {
    // ignore: close_sinks
    final mockEventSink = MockEventSink<List<String>>();

    late ListCollectionTransformerSink<String> sut;

    setUp(() {
      reset(mockEventSink);

      sut = ListCollectionTransformerSink(mockEventSink);
    });

    tearDown(() {
      verifyNoMoreInteractions(mockEventSink);
    });

    test('add collects events for close', () {
      const event1 = 'event-1';
      const event2 = 'event-2';
      const event3 = 'event-3';

      sut.add(event1);
      verifyZeroInteractions(mockEventSink);

      sut
        ..add(event2)
        ..add(event3)
        ..close();

      verifyInOrder([
        () => mockEventSink.add([event1, event2, event3]),
        () => mockEventSink.close(),
      ]);
    });

    test('addError forwards error to sink', () {
      final error = Exception('test');
      final stackTrace = StackTrace.current;

      sut.addError(error, stackTrace);

      verify(() => mockEventSink.addError(error, stackTrace));
    });
  });

  group('$ListCollectionTransformer', () {
    test('transforms stream using the sink', () {
      expect(
        Stream.fromIterable([1, 2, 3])
            .transform(const ListCollectionTransformer()),
        emitsInOrder([
          [1, 2, 3],
          emitsDone,
        ]),
      );
    });
  });

  group('IterableX', () {
    test('extract extracts count elements to the callback', () {
      final extracted = <int>[];

      final result = List.generate(100, (index) => index)
          .extract(15, (element) => extracted.add(element));

      expect(result, List.generate(85, (index) => 15 + index));
      expect(extracted, List.generate(15, (index) => index));
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

  group('GroupedByStream', () {
    test('collect transforms keyed streams to collected map entries', () {
      // stream with 3 groups
      final stream = Stream.fromIterable(List.generate(10, (index) => index))
          .groupBy((value) => value % 3);

      expect(
        stream.collect(),
        emitsInAnyOrder([
          isA<MapEntry>()
              .having((m) => m.key, 'key', 0)
              .having((m) => m.value, 'value', const [0, 3, 6, 9]),
          isA<MapEntry>()
              .having((m) => m.key, 'key', 1)
              .having((m) => m.value, 'value', const [1, 4, 7]),
          isA<MapEntry>()
              .having((m) => m.key, 'key', 2)
              .having((m) => m.value, 'value', const [2, 5, 8]),
          emitsDone,
        ]),
      );
    });
  });

  group('MapValuesX', () {
    test('forValues maps values', () {
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
}

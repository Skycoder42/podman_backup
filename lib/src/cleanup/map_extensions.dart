import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

extension IterableX<T> on Iterable<T> {
  Iterable<T> extract(int count, void Function(T) callback) =>
      whereIndexed((index, element) {
        if (index < count) {
          callback(element);
          return false;
        } else {
          return true;
        }
      });
}

extension MapEntryStreamX<TKey, TValue> on Stream<MapEntry<TKey, TValue>> {
  Stream<MapEntry<TKey, TNewValue>> mapValue<TNewValue>(
    TNewValue Function(TValue) convert,
  ) => map((e) => MapEntry(e.key, convert(e.value)));

  Future<Map<TKey, TValue>> toMap() async => {
    await for (final entry in this) entry.key: entry.value,
  };
}

extension GroupedByStream<T, K> on Stream<GroupedStream<T, K>> {
  Stream<MapEntry<K, Iterable<T>>> collect() => flatMap(
    (group) => group
        .transform(ListCollectionTransformer<T>())
        .map((value) => MapEntry(group.key, value)),
  );
}

extension MapValuesX<TKey, TValue> on Map<TKey, Iterable<TValue>> {
  Map<TKey, Iterable<TNewValue>> forValues<TNewValue>(
    Iterable<TNewValue> Function(Iterable<TValue> value) forValues,
  ) => map((key, value) => MapEntry(key, forValues(value)));
}

@visibleForTesting
class ListCollectionTransformerSink<T> implements EventSink<T> {
  final EventSink<List<T>> _sink;

  final _collection = <T>[];

  ListCollectionTransformerSink(this._sink);

  @override
  void add(T event) => _collection.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  void close() => _sink
    ..add(_collection)
    ..close();
}

class ListCollectionTransformer<T> extends StreamTransformerBase<T, List<T>> {
  const ListCollectionTransformer();

  @override
  Stream<List<T>> bind(Stream<T> stream) =>
      Stream.eventTransformed(stream, ListCollectionTransformerSink.new);
}

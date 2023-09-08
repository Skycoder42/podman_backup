extension MapValuesX<TKey, TValue> on Map<TKey, Iterable<TValue>> {
  Map<TKey, Iterable<TNewValue>> forValues<TNewValue>(
    Iterable<TNewValue> Function(Iterable<TValue> value) forValues,
  ) =>
      map((key, value) => MapEntry(key, forValues(value)));
}

extension MapEntryStreamX<TKey, TValue> on Stream<MapEntry<TKey, TValue>> {
  Stream<MapEntry<TKey, TNewValue>> mapValue<TNewValue>(
    TNewValue Function(TValue) convert,
  ) =>
      map((e) => MapEntry(e.key, convert(e.value)));

  Future<Map<TKey, TValue>> toMap() async => {
        await for (final entry in this) entry.key: entry.value,
      };
}

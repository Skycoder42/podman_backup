extension MapValuesX<TKey, TValue> on Map<TKey, Iterable<TValue>> {
  Map<TKey, Iterable<TNewValue>> forValues<TNewValue>(
    Iterable<TNewValue> Function(Iterable<TValue> value) forValues,
  ) =>
      map((key, value) => MapEntry(key, forValues(value)));
}

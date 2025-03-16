import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final dateTimeAdapterProvider = Provider((ref) => const DateTimeAdapter());
// coverage:ignore-end

class DateTimeAdapter {
  const DateTimeAdapter();

  DateTime get now => DateTime.now();

  DateTime get utcNow => DateTime.now().toUtc();
}

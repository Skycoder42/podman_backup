import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final dateTimeAdapterProvider = Provider(
  (ref) => DateTimeAdapter(),
);
// coverage:ignore-end

class DateTimeAdapter {
  DateTime get now => DateTime.now();

  DateTime get utcNow => DateTime.now().toUtc();
}

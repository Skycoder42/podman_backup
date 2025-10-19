import 'package:injectable/injectable.dart';

@injectable
class DateTimeAdapter {
  const DateTimeAdapter();

  DateTime get now => DateTime.now();

  DateTime get utcNow => DateTime.now().toUtc();
}

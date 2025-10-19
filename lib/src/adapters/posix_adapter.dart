// coverage:ignore-file

import 'package:injectable/injectable.dart';
import 'package:posix/posix.dart' as posix;

@injectable
class PosixAdapter {
  const PosixAdapter();

  bool get isRoot => _ifSupported(() => posix.geteuid() == 0) ?? false;

  T? _ifSupported<T>(T Function() action) =>
      posix.isPosixSupported ? action() : null;
}

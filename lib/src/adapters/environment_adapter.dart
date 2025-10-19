// coverage:ignore-file

import 'dart:io';

import 'package:injectable/injectable.dart';

@injectable
class EnvironmentAdapter {
  const EnvironmentAdapter();

  String? operator [](String name) => Platform.environment[name];
}

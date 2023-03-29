// coverage:ignore-file

import 'dart:io';

import 'package:riverpod/riverpod.dart';

final environmentAdapterProvider = Provider(
  (ref) => const EnvironmentAdapter(),
);

class EnvironmentAdapter {
  const EnvironmentAdapter();

  String? operator [](String name) => Platform.environment[name];
}

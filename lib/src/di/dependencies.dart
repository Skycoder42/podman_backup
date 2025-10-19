import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../cli/options.dart';
import 'dependencies.config.dart';

@InjectableInit(
  initializerName: 'init',
  asExtension: true,
  preferRelativeImports: true,
  throwOnMissingDependencies: true,
  usesNullSafety: true,
  ignoreUnregisteredTypes: [GetIt, Options],
)
GetIt createDiContainer() {
  final instance = GetIt.asNewInstance();
  instance.registerSingleton(instance);
  return instance.init();
}

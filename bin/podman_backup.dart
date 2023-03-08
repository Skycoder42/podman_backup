import 'package:podman_backup/src/adapters/podman_adapter.dart';
import 'package:podman_backup/src/cli/cli_parser.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  final di = ProviderContainer();
  try {
    final cliParser = di.read(cliParserProvider);
    // ignore: unused_local_variable
    final options = cliParser.parse(arguments);

    final podman = di.read(podmanAdapterProvider);

    // ignore: avoid_print
    print(await podman.volumeList());
    // ignore: avoid_print
    print(await podman.ps());
  } finally {
    di.dispose();
  }
}

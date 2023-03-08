import 'dart:io';

import 'package:args/args.dart';
import 'package:riverpod/riverpod.dart';

import 'options.dart';

// coverage:ignore-start
final cliParserProvider = Provider(
  (ref) => CliParser(),
);
// coverage:ignore-end

class CliParser {
  Options parse(List<String> arguments) {
    final argParser = Options.buildArgParser();

    try {
      final argResults = argParser.parse(arguments);
      final options = Options.parseOptions(argResults);

      if (options.help) {
        stdout
          ..writeln('Usage:')
          ..writeln(argParser.usage);
        exit(0);
      }

      if (!options.remoteHostWasParsed) {
        throw ArgParserException('Required option "remote" was not specified.');
      }

      return options;
    } on ArgParserException catch (e) {
      stderr
        ..writeln(e)
        ..writeln()
        ..writeln('Usage:')
        ..writeln(argParser.usage);
      exit(127);
    }
  }
}

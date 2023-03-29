// coverage:ignore-file

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/environment_adapter.dart';
import 'options.dart';

// coverage:ignore-start
final cliParserProvider = Provider(
  (ref) => CliParser(
    ref.watch(environmentAdapterProvider),
  ),
);
// coverage:ignore-end

class CliParser {
  final EnvironmentAdapter _environmentAdapter;
  final _logger = Logger('$CliParser');

  CliParser(this._environmentAdapter);

  Options parse(List<String> arguments) {
    final argParser = Options.buildArgParser(_environmentAdapter);

    try {
      final argResults = argParser.parse(arguments);
      final options = Options.parseOptions(argResults);

      Logger.root.level = options.logLevel;
      _logger.finest('Parsed arguments: $arguments');

      if (options.help) {
        stdout
          ..writeln('Usage:')
          ..writeln(argParser.usage);
        exit(0);
      }

      if (!options.remoteHostRawWasParsed) {
        throw ArgParserException('Required option "remote" was not specified.');
      }

      _logger
        ..config('remoteHost: ${options.getRemoteHost()}')
        ..config('backupMode: ${options.backupMode}')
        ..config('backupLabel: ${options.backupLabel}')
        ..config('backupCache: ${options.backupCache}');

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

// coverage:ignore-file

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

// ignore: no_self_package_imports
import '../../gen/package_metadata.dart' as metadata;
import '../adapters/environment_adapter.dart';
import '../adapters/posix_adapter.dart';
import 'options.dart';

// coverage:ignore-start
final cliParserProvider = Provider(
  (ref) => CliParser(
    ref.watch(environmentAdapterProvider),
    ref.watch(posixAdapterProvider),
  ),
);
// coverage:ignore-end

class CliParser {
  final EnvironmentAdapter _environmentAdapter;
  final PosixAdapter _posixAdapter;
  final _logger = Logger('$CliParser');

  CliParser(this._environmentAdapter, this._posixAdapter);

  Options parse(List<String> arguments) {
    final argParser = Options.buildArgParser(
      _environmentAdapter,
      _posixAdapter,
    );

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

      if (options.version) {
        stdout
          ..write(Platform.script.pathSegments.last)
          ..write(' ')
          ..writeln(metadata.version);
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

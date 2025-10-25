import 'dart:io';
import 'package:nlaabo/config/app_config.dart';

Future<void> main() async {
  final envs = [
    AppEnvironment.development,
    AppEnvironment.staging,
    AppEnvironment.production,
  ];

  for (final env in envs) {
    stdout.writeln('===== ${env.name.toUpperCase()} =====');
    try {
      final result = await AppConfig.initialize(environment: env);
      stdout.writeln('Valid: ${result.isValid}');
      if (result.errors.isNotEmpty) {
        stdout.writeln('Errors: ${result.errors.join(', ')}');
      }
      if (result.warnings.isNotEmpty) {
        stdout.writeln('Warnings: ${result.warnings.join(', ')}');
      }
    } catch (e, st) {
      stdout.writeln('Error generating report for ${env.name}: $e\n$st');
    }
    stdout.writeln('');
  }

  stdout.writeln('Done.');
}
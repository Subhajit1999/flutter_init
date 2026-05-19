import "dart:io";

import "package:flutterinit_cli/src/cli.dart";
import "package:flutterinit_cli/src/version.dart";

Future<void> main(List<String> args) async {
  if (args.contains("--version") || args.contains("-V")) {
    stdout.writeln("flutterinit_cli $cliVersion");
    return;
  }
  final exitCode =
      await Cli(stdout: stdout, stderr: stderr, stdin: stdin).run(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}

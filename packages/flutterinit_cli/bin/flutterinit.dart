import "dart:io";

import "package:flutterinit_cli/src/cli.dart";

Future<void> main(List<String> args) async {
  final exitCode = await Cli(stdout: stdout, stderr: stderr, stdin: stdin).run(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}

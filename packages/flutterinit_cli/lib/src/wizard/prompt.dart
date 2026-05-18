import "dart:io";

class Prompt {
  Prompt({required this.stdout, required this.stderr, required this.stdin, required this.yes});

  final Stdout stdout;
  final Stdout stderr;
  final Stdin stdin;
  final bool yes;

  String askText({
    required String label,
    required String defaultValue,
    bool Function(String value)? validate,
    String? invalidMessage,
  }) {
    if (yes) return defaultValue;

    while (true) {
      stdout.write("$label [$defaultValue]: ");
      final input = stdin.readLineSync();
      final value = (input == null || input.trim().isEmpty) ? defaultValue : input.trim();
      if (validate == null || validate(value)) return value;
      stderr.writeln(invalidMessage ?? "Invalid value.");
    }
  }

  bool askBool({required String label, required bool defaultValue}) {
    if (yes) return defaultValue;

    final d = defaultValue ? "Y/n" : "y/N";
    while (true) {
      stdout.write("$label [$d]: ");
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) return defaultValue;
      final v = input.trim().toLowerCase();
      if (v == "y" || v == "yes") return true;
      if (v == "n" || v == "no") return false;
      stderr.writeln("Enter y or n.");
    }
  }

  String askChoice({
    required String label,
    required List<Choice> choices,
    required String defaultValue,
  }) {
    if (yes) return defaultValue;

    final indexed = {for (var i = 0; i < choices.length; i++) (i + 1): choices[i]};
    stdout.writeln(label);
    for (final entry in indexed.entries) {
      final isDefault = entry.value.value == defaultValue;
      stdout.writeln("  ${entry.key}) ${entry.value.label}${isDefault ? " (default)" : ""}");
    }

    while (true) {
      stdout.write("Select [${choices.indexWhere((c) => c.value == defaultValue) + 1}]: ");
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) return defaultValue;
      final idx = int.tryParse(input.trim());
      if (idx != null && indexed.containsKey(idx)) return indexed[idx]!.value;
      stderr.writeln("Invalid selection.");
    }
  }
}

class Choice {
  Choice({required this.value, required this.label});

  final String value;
  final String label;
}

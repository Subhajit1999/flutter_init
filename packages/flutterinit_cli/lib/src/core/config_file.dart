import "dart:convert";
import "dart:io";

class ConfigFile {
  ConfigFile({
    required this.generatorVersion,
    required this.config,
  });

  final String? generatorVersion;
  final Map<String, dynamic> config;

  static Future<ConfigFile> read(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("Config file must be a JSON object.");
    }
    if (decoded.containsKey("config")) {
      final cfg = decoded["config"];
      if (cfg is! Map<String, dynamic>) {
        throw FormatException("config must be an object.");
      }
      final version = decoded["generatorVersion"];
      return ConfigFile(
        generatorVersion: version is String ? version : null,
        config: cfg,
      );
    }
    return ConfigFile(generatorVersion: null, config: decoded);
  }
}

import "dart:convert";

class ServerConfig {
  ServerConfig({
    required this.generatorVersion,
    required this.defaultConfig,
    required this.options,
    required this.stepOrder,
  });

  final String generatorVersion;
  final Map<String, dynamic> defaultConfig;
  final Map<String, dynamic> options;
  final List<String> stepOrder;

  static ServerConfig fromJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("Server config payload must be an object.");
    }
    final version = decoded["generatorVersion"];
    final defaultConfig = decoded["defaultConfig"];
    final options = decoded["options"];
    final stepOrder = decoded["stepOrder"];
    if (version is! String) throw FormatException("generatorVersion missing.");
    if (defaultConfig is! Map<String, dynamic>) throw FormatException("defaultConfig missing.");
    if (options is! Map<String, dynamic>) throw FormatException("options missing.");
    if (stepOrder is! List) throw FormatException("stepOrder missing.");
    final steps = stepOrder.whereType<String>().toList();
    return ServerConfig(
      generatorVersion: version,
      defaultConfig: defaultConfig,
      options: options,
      stepOrder: steps,
    );
  }
}

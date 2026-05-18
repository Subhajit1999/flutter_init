import "package:http/http.dart" as http;

import "bundled_server_config.dart";
import "endpoints.dart";
import "server_config.dart";

class ServerClient {
  ServerClient({required this.endpoint, this.allowFallback = true});

  final Uri endpoint;
  final bool allowFallback;

  Future<ServerConfig> fetchConfig() async {
    final url = resolveConfigEndpoint(endpoint);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return ServerConfig.fromJson(response.body);
    }
    if (allowFallback) {
      return bundledServerConfig();
    }
    throw Exception(
        "Config fetch failed: ${response.statusCode} ${response.body}");
  }
}

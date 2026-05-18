import "package:http/http.dart" as http;

import "endpoints.dart";
import "server_config.dart";

class ServerClient {
  ServerClient({required this.endpoint});

  final Uri endpoint;

  Future<ServerConfig> fetchConfig() async {
    final url = resolveConfigEndpoint(endpoint);
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception("Config fetch failed: ${response.statusCode} ${response.body}");
    }
    return ServerConfig.fromJson(response.body);
  }
}

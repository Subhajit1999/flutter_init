Uri resolveGenerateEndpoint(Uri endpoint) {
  if (endpoint.path.endsWith("/api/generate")) return endpoint;
  if (endpoint.path.endsWith("/api/generate/")) {
    return endpoint.replace(path: endpoint.path.substring(0, endpoint.path.length - 1));
  }
  if (endpoint.path.endsWith("/")) {
    return endpoint.replace(path: "${endpoint.path}api/generate");
  }
  return endpoint.replace(path: "${endpoint.path}/api/generate");
}

Uri resolveConfigEndpoint(Uri endpoint) {
  final generate = resolveGenerateEndpoint(endpoint);
  final path = generate.path;
  final configPath = path.endsWith("/api/generate") ? path.replaceFirst("/api/generate", "/api/config") : "/api/config";
  return generate.replace(path: configPath);
}

Map<String, dynamic> deepCopyMap(Map<String, dynamic> input) {
  return input.map((key, value) => MapEntry(key, deepCopy(value)));
}

dynamic deepCopy(dynamic value) {
  if (value is Map<String, dynamic>) return deepCopyMap(value);
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, deepCopy(v)));
  }
  if (value is List) return value.map(deepCopy).toList();
  return value;
}

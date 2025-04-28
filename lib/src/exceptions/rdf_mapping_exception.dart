class RdfMappingException implements Exception {
  final String? _message;

  RdfMappingException([String? message]) : _message = message;

  @override
  String toString() =>
      _message != null ? "$runtimeType: $_message" : runtimeType.toString();
}

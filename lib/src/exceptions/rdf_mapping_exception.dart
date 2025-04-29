/// Base exception class for all RDF mapping related errors.
///
/// This exception serves as the root of the exception hierarchy for the RDF mapping system,
/// providing a common type that can be caught to handle any mapping-related errors.
/// More specific exceptions extend this class to provide detailed error information
/// for different failure scenarios.
///
/// The message provides context about the specific error condition that occurred.
class RdfMappingException implements Exception {
  final String? _message;

  /// Creates a new RDF mapping exception with an optional error message.
  ///
  /// @param message Optional text describing the error condition
  RdfMappingException([String? message]) : _message = message;

  @override
  String toString() =>
      _message != null ? "$runtimeType: $_message" : runtimeType.toString();
}

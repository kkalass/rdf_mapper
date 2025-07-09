/// Defines how the RDF mapper should handle incomplete deserialization.
///
/// This enum controls the behavior when `deserializeAll` encounters RDF triples
/// that cannot be processed due to missing deserializers or other issues.
/// The different modes provide varying levels of strictness for completeness validation.
enum CompletenessMode {
  /// Throw an exception if any RDF triples remain unprocessed.
  ///
  /// This mode enforces strict completeness validation, ensuring that all
  /// triples in the input graph are successfully deserialized. If any triples
  /// remain unprocessed, an [IncompleteDeserializationException] is thrown.
  ///
  /// Best for: Production environments where incomplete deserialization
  /// indicates a serious configuration issue.
  strict,

  /// Log a warning message if any RDF triples remain unprocessed.
  ///
  /// This mode logs detailed information about unprocessed triples at the
  /// warning level but continues execution. This helps surface potential
  /// issues during development and debugging.
  ///
  /// Best for: Development and testing environments where you want to be
  /// aware of incomplete mappings without stopping execution.
  warnOnly,

  /// Log an informational message if any RDF triples remain unprocessed.
  ///
  /// This mode logs basic information about unprocessed triples at the
  /// info level but continues execution. Less verbose than `warnOnly`.
  ///
  /// Best for: Production environments where you want to monitor mapping
  /// completeness without flooding logs with warnings.
  infoOnly,

  /// Silently ignore any unprocessed RDF triples.
  ///
  /// This mode provides the most lenient behavior, continuing execution
  /// without any logging or exceptions when triples remain unprocessed.
  ///
  /// Best for: Legacy systems or scenarios where incomplete deserialization
  /// is expected and acceptable.
  lenient;

  /// Whether this mode should throw an exception for incomplete deserialization.
  bool get shouldThrow => this == CompletenessMode.strict;

  /// Whether this mode should log unprocessed triples.
  bool get shouldLog =>
      this == CompletenessMode.warnOnly || this == CompletenessMode.infoOnly;

  /// Whether this mode should log at warning level (vs info level).
  bool get shouldLogWarning => this == CompletenessMode.warnOnly;
}

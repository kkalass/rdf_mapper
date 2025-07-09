import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

/// Exception thrown when RDF graph deserialization is incomplete.
///
/// This exception occurs when `deserializeAll` is called with strict completeness
/// validation and the RDF graph contains triples that could not be processed.
/// Unprocessed triples may indicate:
/// - Missing deserializers for specific RDF types
/// - Malformed or unexpected RDF structures
/// - Incomplete mapping configuration
///
/// The exception provides detailed information about what was left unprocessed,
/// helping developers identify and resolve mapping issues.
class IncompleteDeserializationException extends DeserializationException {
  /// The RDF graph containing unprocessed triples
  final RdfGraph remainingGraph;

  /// Set of subject IRIs that had rdf:type declarations but no deserializers
  final Set<RdfSubject> unmappedSubjects;

  /// Set of type IRIs that were encountered but had no registered deserializers
  final Set<IriTerm> unmappedTypes;

  /// Creates a new incomplete deserialization exception.
  ///
  /// [remainingGraph] The RDF graph containing unprocessed triples
  /// [unmappedSubjects] Subjects that couldn't be deserialized
  /// [unmappedTypes] Type IRIs that had no deserializers
  /// [message] Optional custom error message
  IncompleteDeserializationException({
    required this.remainingGraph,
    required this.unmappedSubjects,
    required this.unmappedTypes,
    String? message,
  }) : super(message ??
            _generateMessage(remainingGraph, unmappedSubjects, unmappedTypes));

  /// Generates a descriptive error message based on the unprocessed data.
  static String _generateMessage(
    RdfGraph remainingGraph,
    Set<RdfSubject> unmappedSubjects,
    Set<IriTerm> unmappedTypes,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Incomplete RDF graph deserialization:');
    buffer.writeln('  - ${remainingGraph.triples.length} unprocessed triples');

    if (unmappedSubjects.isNotEmpty) {
      buffer.writeln(
          '  - ${unmappedSubjects.length} subjects without deserializers:');
      for (final subject in unmappedSubjects.take(5)) {
        buffer.writeln('    • $subject');
      }
      if (unmappedSubjects.length > 5) {
        buffer.writeln('    ... and ${unmappedSubjects.length - 5} more');
      }
    }

    if (unmappedTypes.isNotEmpty) {
      buffer.writeln('  - ${unmappedTypes.length} unmapped type IRIs:');
      for (final type in unmappedTypes.take(5)) {
        buffer.writeln('    • $type');
      }
      if (unmappedTypes.length > 5) {
        buffer.writeln('    ... and ${unmappedTypes.length - 5} more');
      }
    }
    if (remainingGraph.triples.isNotEmpty) {
      buffer.writeln('  - Unprocessed triples (max 10):');
      for (final triple in remainingGraph.triples.take(10)) {
        buffer.writeln('    • $triple');
      }
      if (remainingGraph.triples.length > 10) {
        buffer
            .writeln('    ... and ${remainingGraph.triples.length - 10} more');
      }
    }
    return buffer.toString().trim();
  }

  /// Whether the remaining graph contains any triples
  bool get hasRemainingTriples => remainingGraph.triples.isNotEmpty;

  /// Number of unprocessed triples
  int get remainingTripleCount => remainingGraph.triples.length;
}

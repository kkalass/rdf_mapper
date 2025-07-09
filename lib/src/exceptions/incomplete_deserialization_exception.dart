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
  }) : super(_generateMessage(remainingGraph, unmappedSubjects, unmappedTypes));

  /// Generates a descriptive error message based on the unprocessed data.
  static String _generateMessage(
    RdfGraph remainingGraph,
    Set<RdfSubject> unmappedSubjects,
    Set<IriTerm> unmappedTypes,
  ) {
    final tripleCount = remainingGraph.triples.length;

    return '''
RDF Deserialization Incomplete: ${tripleCount} unprocessed triple${tripleCount == 1 ? '' : 's'} found

Quick Fix (relaxed validation):
  • Use CompletenessMode.lenient to ignore unprocessed triples:
    
    final objects = rdfMapper.decodeObjects<YourType>(rdfString, 
      completenessMode: CompletenessMode.lenient);

Alternative Solutions:

1. Keep unprocessed triples (recommended for data preservation):
   • Use lossless decode methods that return both objects and remaining graph:
     
     final (objects, remaining) = rdfMapper.decodeObjectsLossless<YourType>(rdfString);
     // Process objects, inspect remaining graph for missing mappings
   
2. Register missing deserializers:
   • For unmapped types, register appropriate mappers:
     
     final rdfMapper = RdfMapper.withMappers((registry) {
       registry.registerMapper<YourType>(YourTypeMapper());
       // Add other missing mappers
     });

3. Use different completeness modes:
   • CompletenessMode.warnOnly - Log warnings but continue
   • CompletenessMode.infoOnly - Log info messages but continue
   • CompletenessMode.lenient - Silently ignore unprocessed triples
   
   final objects = rdfMapper.decodeObjects<YourType>(rdfString,
     completenessMode: CompletenessMode.warnOnly);

${_formatUnprocessedTriples(remainingGraph)}${_formatUnmappedInfo(unmappedSubjects, unmappedTypes)}

Why this happens:
Strict completeness validation ensures all RDF triples are processed, preventing
data loss and highlighting missing mappings. This helps maintain data integrity
and catch configuration issues early.
''';
  }

  static String _formatUnprocessedTriples(RdfGraph remainingGraph) {
    if (remainingGraph.triples.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('\nUnprocessed Triples (first 10):');
    for (final triple in remainingGraph.triples.take(10)) {
      buffer.writeln('  • $triple');
    }
    if (remainingGraph.triples.length > 10) {
      buffer.writeln('  ... and ${remainingGraph.triples.length - 10} more');
    }
    return buffer.toString();
  }

  static String _formatUnmappedInfo(
      Set<RdfSubject> unmappedSubjects, Set<IriTerm> unmappedTypes) {
    final buffer = StringBuffer();

    if (unmappedSubjects.isNotEmpty) {
      buffer.writeln('\nSubjects without deserializers (first 5):');
      for (final subject in unmappedSubjects.take(5)) {
        buffer.writeln('  • $subject');
      }
      if (unmappedSubjects.length > 5) {
        buffer.writeln('  ... and ${unmappedSubjects.length - 5} more');
      }
    }

    if (unmappedTypes.isNotEmpty) {
      buffer.writeln('\nUnmapped type IRIs (first 5):');
      for (final type in unmappedTypes.take(5)) {
        buffer.writeln('  • $type');
      }
      if (unmappedTypes.length > 5) {
        buffer.writeln('  ... and ${unmappedTypes.length - 5} more');
      }
    }

    return buffer.toString();
  }

  /// Whether the remaining graph contains any triples
  bool get hasRemainingTriples => remainingGraph.triples.isNotEmpty;

  /// Number of unprocessed triples
  int get remainingTripleCount => remainingGraph.triples.length;

  /// Number of subjects without deserializers
  int get unmappedSubjectCount => unmappedSubjects.length;

  /// Number of unmapped type IRIs
  int get unmappedTypeCount => unmappedTypes.length;
}

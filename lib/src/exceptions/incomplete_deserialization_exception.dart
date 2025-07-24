import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

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
  late final Set<RdfSubject> unmappedSubjects;
  late final Set<IriTerm> unmappedTypes;

  /// Creates a new incomplete deserialization exception.
  ///
  /// [remainingGraph] The RDF graph containing unprocessed triples
  /// [message] Optional custom error message
  IncompleteDeserializationException({
    required this.remainingGraph,
  }) : super(_generateMessage(remainingGraph)) {
    final (unmappedSubjects, unmappedTypes) = getUnmappedInfo(remainingGraph);
    this.unmappedSubjects = unmappedSubjects;
    this.unmappedTypes = unmappedTypes;
  }

  int get unmappedSubjectCount => unmappedSubjects.length;
  int get unmappedTypeCount => unmappedTypes.length;

  /// Generates a descriptive error message based on the unprocessed data.
  static String _generateMessage(
    RdfGraph remainingGraph,
  ) {
    final tripleCount = remainingGraph.triples.length;

    return '''
RDF Deserialization Incomplete: ${tripleCount} unprocessed triple${tripleCount == 1 ? '' : 's'} found

Quick Fix (relaxed validation):
  • Use CompletenessMode.lenient to ignore unprocessed triples:
    
    final objects = rdfMapper.decodeObjects<YourType>(rdfString, 
      completeness: CompletenessMode.lenient);

  • OR add unmapped triples field (preserves all data of the corresponding subject):
    
    @RdfLocalResource()
    class YourType {
      // ... your mapped properties ...
      @RdfUnmappedTriples()
      late final RdfGraph unmappedTriples;  // Captures all unmapped triples
    }

Alternative Solutions:

1. Enhance domain objects with catch-all fields (manual implementation):
   • Add RdfGraph fields to your classes and use getUnmapped()/addUnmapped():
     
     class YourType {
       // ... your mapped properties ...
       late final RdfGraph unmappedTriples;  // Add this field
     }
     
     class YourTypeMapper implements LocalResourceMapper<YourType> {
       @override
       fromRdfResource(subject, DeserializationContext context) {
         var reader = context.reader(subject);
         return YourType()
           // ... map your properties ...
           ..unmappedTriples = reader.getUnmapped();  // Capture unmapped triples
       }
       
       @override
       (subject, Iterable<Triple>) toRdfResource(value, SerializationContext context, {...}) =>
         context.resourceBuilder(subject)
           // ... add your properties ...
           .addUnmapped(value.unmappedTriples)  // Restore unmapped triples
           .build();
     }

2. Keep unprocessed triples externally (for global analysis):
   • Use lossless decode methods that return both objects and remaining graph:
     
     final (objects, remaining) = rdfMapper.decodeObjectsLossless<YourType>(rdfString);
     // Process objects, inspect remaining graph for missing mappings
   
3. Register missing deserializers and check existing are complete:
   • For unmapped types, register appropriate mappers:
     
     final rdfMapper = RdfMapper.withMappers((registry) {
       registry.registerMapper<YourType>(YourTypeMapper());
       // Add other missing mappers
     });

4. Use different completeness modes:
   • CompletenessMode.warnOnly - Log warnings but continue
   • CompletenessMode.infoOnly - Log info messages but continue
   • CompletenessMode.lenient - Silently ignore unprocessed triples
   
   final objects = rdfMapper.decodeObjects<YourType>(rdfString,
     completeness: CompletenessMode.warnOnly);

${_formatUnprocessedTriples(remainingGraph)}${_formatUnmappedInfo(remainingGraph)}

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

  static (Set<RdfSubject>, Set<IriTerm>) getUnmappedInfo(RdfGraph graph) {
    final unmappedSubjects = graph.triples.map((t) => t.subject).toSet();
    final unmappedTypes = graph
        .findTriples(predicate: Rdf.type)
        .map((t) => t.object)
        .whereType<IriTerm>()
        .toSet();
    return (unmappedSubjects, unmappedTypes);
  }

  static String _formatUnmappedInfo(RdfGraph graph) {
    final (unmappedSubjects, unmappedTypes) = getUnmappedInfo(graph);
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
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

/// Exception thrown when RDF data doesn't conform to valid RDF List structure.
///
/// This exception provides detailed analysis of what collection pattern was found
/// instead of the expected RDF List (rdf:first/rdf:rest) structure, along with
/// concrete suggestions for alternative deserialization approaches.
///
/// **Common Scenarios**:
/// - Missing `rdf:first` or `rdf:rest` properties
/// - Multiple values for the same RDF List property
/// - Using different vocabularies or collection patterns
/// - Empty or malformed resource structure
///
/// **Error Analysis**: The exception analyzes the actual RDF triples to determine
/// the collection pattern being used and suggests appropriate reader methods:
/// - `reader.require<T>()` for single values
/// - `reader.getValues<T>().toList()` for multiple values of the same predicate
/// - `reader.collect<T>()` for custom collection handling
class InvalidRdfListStructureException extends DeserializationException {
  /// The RDF subject that was expected to be part of an RDF List.
  final RdfSubject subject;

  /// The actual triples found for the subject.
  final Iterable<Triple> foundTriples;

  /// Analysis of what collection pattern was detected instead.
  final String foundPattern;

  /// Suggested alternative approaches for reading the data.
  final List<String> suggestions;

  /// Creates an invalid RDF List structure exception with detailed analysis.
  ///
  /// [subject] The RDF subject that failed RDF List validation.
  /// [foundTriples] The actual triples found for this subject.
  /// [foundPattern] Description of the detected collection pattern.
  /// [suggestions] List of alternative approaches for reading the data.
  /// [message] Optional override for the error message.
  InvalidRdfListStructureException({
    required this.subject,
    required this.foundTriples,
    required this.foundPattern,
    required this.suggestions,
    String? message,
  }) : super(message ??
            _buildDefaultMessage(subject, foundPattern, suggestions));

  /// Builds the default error message with analysis and suggestions.
  static String _buildDefaultMessage(
    RdfSubject subject,
    String foundPattern,
    List<String> suggestions,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Invalid RDF List structure at node: $subject');
    buffer.writeln();
    buffer.writeln(
        'Expected: Standard RDF List with rdf:first and rdf:rest properties');
    buffer.writeln('Found: $foundPattern');
    buffer.writeln();

    if (suggestions.isNotEmpty) {
      buffer.writeln('Suggested alternatives:');
      for (final suggestion in suggestions) {
        buffer.writeln('• $suggestion');
      }
      buffer.writeln();
    }

    buffer.writeln('RDF List structure should look like:');
    buffer.writeln('  <node> rdf:first <value> ;');
    buffer.writeln('         rdf:rest <nextNode> .');
    buffer.writeln();
    buffer.writeln('For the last element:');
    buffer.writeln('  <lastNode> rdf:first <value> ;');
    buffer.writeln('             rdf:rest rdf:nil .');

    return buffer.toString().trim();
  }
}

/// Exception thrown when a circular reference is detected in an RDF List structure.
///
/// RDF Lists should form linear chains ending with `rdf:nil`. Circular references
/// indicate malformed data that would cause infinite loops during traversal.
///
/// This exception extends [InvalidRdfListStructureException] to maintain the
/// exception hierarchy while providing specific information about cycle detection.
class CircularRdfListException extends InvalidRdfListStructureException {
  /// The node where the circular reference was detected.
  final RdfSubject circularNode;

  /// All nodes that were visited before detecting the cycle.
  final Set<RdfSubject> visitedNodes;

  /// Creates an exception for circular RDF List references.
  ///
  /// [circularNode] The node where the cycle was detected.
  /// [visitedNodes] All nodes visited before detecting the cycle.
  CircularRdfListException({
    required this.circularNode,
    required this.visitedNodes,
  }) : super(
          subject: circularNode,
          foundTriples: [], // Cycles are detected during traversal, not from triples
          foundPattern:
              'Circular reference detected - node $circularNode was already visited in path: ${visitedNodes.join(' → ')} → $circularNode',
          suggestions: [
            'Verify RDF data integrity - lists should not contain cycles',
            'Check that rdf:rest properties form a linear chain ending with rdf:nil',
            'Consider using a different collection structure if cycles are intentional',
            'Use graph traversal methods if the data represents a cyclic graph rather than a list',
          ],
        );
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// Deserializer for RDF list structures to Dart `List<T>` collections.
///
/// This deserializer converts RDF's standard linked list representation (using
/// `rdf:first` and `rdf:rest` properties) back into Dart lists. It is designed
/// to work with the deserialization infrastructure and handle RDF lists within
/// larger object graphs.
///
/// **RDF List Handling**: Processes standard RDF list structures where each node
/// contains `rdf:first` (element value) and `rdf:rest` (next node or `rdf:nil`).
/// Empty lists are represented by `rdf:nil` as the subject.
///
/// **Element Deserialization**: Individual list elements are deserialized using
/// the provided item deserializer or registry-based lookup for the element type.
///
/// **Primary Usage Pattern**: Used through `ResourceReader` convenience methods:
/// ```dart
/// // Within a deserializer's fromRdfResource method:
/// final reader = context.reader(subject);
///
/// // Required RDF list (throws if missing)
/// final chapters = reader.requireRdfList<String>(Schema.chapters);
///
/// // Optional RDF list (returns null if missing)
/// final tags = reader.optionalRdfList<String>(Schema.tags) ?? const [];
///
/// // With custom item deserializer
/// final authors = reader.requireRdfList<Person>(
///   Schema.author,
///   itemDeserializer: PersonDeserializer(),
/// );
/// ```
///
/// **Advanced Usage**: For complex collection types, use with `ResourceReader.requireCollection()`:
/// ```dart
/// // Custom collection type requiring specialized deserializer
/// final immutableList = reader.requireCollection<ImmutableList<String>, String>(
///   Schema.keywords,
///   RdfListDeserializer<String>.new,
/// );
/// ```
///
/// **Integration**: Works with `DeserializationContext` to recursively deserialize
/// complex nested structures and track processed triples for completeness validation.
/// This class is not typically instantiated directly or registered in the registry,
/// but rather used by the collection deserialization infrastructure.
class RdfListDeserializer<T>
    with RdfListDeserializerMixin<T>
    implements UnifiedResourceDeserializer<List<T>> {
  final Deserializer<T>? itemDeserializer;

  /// Creates an RDF list deserializer for `List<T>`.
  ///
  /// [itemDeserializer] Optional deserializer for list elements. If not provided,
  /// element deserialization will be resolved through the registry.
  const RdfListDeserializer({this.itemDeserializer});

  @override
  List<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
    if (subject is! BlankNodeTerm && subject != Rdf.nil) {
      throw ArgumentError(
          """Expected subject to be a BlankNodeTerm or rdf:nil, but found: $subject. 
          It is impossible to serialize a dart List<T> back to an IRI because we loose 
          the information about the original IRI. 
          
          Please implement your own container type that keeps the IRI. 
          You can certainly use the same base class for that to help you 
          with the rdf:List details: BaseRdfListDeserializer and BaseRdfListSerializer.""");
    }
    return readRdfList(subject, context, itemDeserializer).toList();
  }
}

/// Abstract base class for deserializing RDF list structures to Dart collections.
///
/// This class provides common functionality for converting RDF list representations
/// (linked list structures using `rdf:first` and `rdf:rest` properties) back into
/// Dart collection types. Concrete implementations specify the target collection
/// type `C` and element type `T`.
///
/// **RDF List Traversal**: Implements efficient traversal of RDF list structures
/// with cycle detection to prevent infinite loops on malformed data. The traversal
/// follows `rdf:rest` links until reaching `rdf:nil`.
///
/// **Element Processing**: Each list element (accessed via `rdf:first`) is
/// deserialized using the provided item deserializer or registry-based lookup,
/// enabling complex nested objects within collections.
///
/// **Memory Efficiency**: Uses lazy evaluation through generator methods to
/// process large lists without loading all elements into memory simultaneously.
///
/// **Type Parameters**:
/// - `C`: The target collection type (e.g., `List<String>`, `Set<Person>`)
/// - `T`: The element type within the collection (e.g., `String`, `Person`)
///
/// Subclasses must implement `fromRdfResource()` to convert the lazy iterable
/// into the specific collection type required.
abstract mixin class RdfListDeserializerMixin<T> {
  IriTerm? get typeIri => Rdf.List;

  /// Reads an RDF list structure and converts it to a typed Dart iterable.
  ///
  /// This method traverses an RDF list (linked list structure using `rdf:first` and `rdf:rest`)
  /// and deserializes each element to the specified type T. RDF lists are commonly used
  /// to represent ordered collections in RDF graphs.
  ///
  /// **RDF List Structure**: An RDF list consists of nodes where each node has:
  /// - `rdf:first`: Points to the value/element of the current list item
  /// - `rdf:rest`: Points to the next list node, or `rdf:nil` for the last element
  ///
  /// **Lazy Evaluation**: The method returns an iterable that processes list elements
  /// on-demand, making it memory-efficient for large lists.
  ///
  /// **Empty List Handling**: If the subject is `rdf:nil`, returns an empty iterable.
  ///
  /// **Cycle Detection**: Automatically detects and prevents infinite loops caused
  /// by circular references in malformed RDF list structures.
  ///
  /// **Usage by Subclasses**: Concrete deserializers should call this method from
  /// their `fromRdfResource()` implementation and convert the result to the target
  /// collection type:
  /// ```dart
  /// @override
  /// List<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
  ///   return readRdfList(subject, context).toList();
  /// }
  /// ```
  ///
  /// [subject] The RDF subject representing the head of the list (or `rdf:nil` for empty list).
  /// [context] The deserialization context providing access to the RDF graph and deserializers.
  ///
  /// Returns a lazy iterable of deserialized list elements of type T.
  ///
  /// Throws [InvalidRdfListStructureException] if the RDF structure doesn't conform to RDF List pattern.
  /// Throws [CircularRdfListException] if circular references are detected in the list structure.
  /// Throws [DeserializationException] if element deserialization fails.
  Iterable<T> readRdfList(
    RdfSubject subject,
    DeserializationContext context,
    Deserializer<T>? _deserializer,
  ) sync* {
    if (subject == Rdf.nil) {
      return; // rdf:nil represents an empty list
    }

    RdfSubject cur = subject;
    final visitedNodes = <RdfSubject>{};

    while (cur != Rdf.nil) {
      // Cycle detection: check if we've seen this node before
      if (visitedNodes.contains(cur)) {
        throw CircularRdfListException(
          circularNode: cur,
          visitedNodes: visitedNodes,
        );
      }
      visitedNodes.add(cur);

      // Extract and validate RDF List triples in one operation (performance optimization)
      final validatedTriples = _extractAndValidateRdfListTriples(cur, context);

      final first = validatedTriples.first;
      final rest = validatedTriples.rest;

      // Track the specific triples we used
      context.trackTriplesRead(cur, [first, rest]);

      // Deserialize the element
      final object = first.object;
      final deserialized =
          context.deserialize<T>(object, deserializer: _deserializer);
      yield deserialized;

      // Move to next node after successful processing
      cur = rest.object as RdfSubject;
    }
  }

  /// Extracts and validates RDF List triples efficiently in a single operation.
  ///
  /// This method consolidates triple extraction with validation to avoid redundant
  /// operations and provides detailed error analysis when the structure doesn't
  /// conform to RDF List expectations.
  ///
  /// Returns a record with the validated first and rest triples.
  ({Triple first, Triple rest}) _extractAndValidateRdfListTriples(
    RdfSubject currentNode,
    DeserializationContext context,
  ) {
    // Get all triples for current subject (single call, no redundancy)
    final allTriples = context.getTriplesForSubject(currentNode,
        includeBlankNodes: false, trackRead: false);
    final subjectTriples =
        allTriples.where((t) => t.subject == currentNode).toList();

    // Extract RDF List specific triples
    final firstTriples =
        subjectTriples.where((t) => t.predicate == Rdf.first).toList();
    final restTriples =
        subjectTriples.where((t) => t.predicate == Rdf.rest).toList();

    // Check for missing required properties
    if (firstTriples.isEmpty || restTriples.isEmpty) {
      final missingProps = <String>[];
      if (firstTriples.isEmpty) missingProps.add('rdf:first');
      if (restTriples.isEmpty) missingProps.add('rdf:rest');

      // Analyze what we actually found to suggest alternatives
      final predicates = subjectTriples.map((t) => t.predicate).toSet();
      final hasMultipleValues =
          _hasMultipleValuesForSamePredicate(subjectTriples);

      final suggestions = <String>[];
      String foundPattern;

      if (hasMultipleValues) {
        foundPattern =
            'Multiple triples with the same predicate for different values';
        suggestions.add(
            'Use reader.getValues<T>(predicate).toList() for collections with repeated predicates');
        suggestions.add(
            'Note: This returns values in random order without sequence guarantees');
      } else if (predicates.isNotEmpty) {
        final examplePredicate = _formatPredicate(predicates.first);
        foundPattern =
            'Different predicates than expected for RDF Lists: ${predicates.map(_formatPredicate).join(', ')}';
        suggestions
            .add('For single values: reader.require<T>($examplePredicate)');
        suggestions.add(
            'For multiple values: reader.getValues<T>($examplePredicate).toList()');
      } else {
        foundPattern =
            'No triples found for this subject - empty resource or incorrect reference';
        suggestions.add('Verify the subject reference is correct');
        suggestions.add('Check if the resource exists in the RDF graph');
        suggestions.add('Consider if this should be an optional property');
      }

      throw InvalidRdfListStructureException(
        subject: currentNode,
        foundTriples: subjectTriples,
        foundPattern: foundPattern,
        suggestions: suggestions,
      );
    }

    // Check for multiple values (indicates wrong collection type)
    if (firstTriples.length > 1 || restTriples.length > 1) {
      final duplicateProps = <String>[];
      if (firstTriples.length > 1) {
        duplicateProps.add('rdf:first (${firstTriples.length} values)');
      }
      if (restTriples.length > 1) {
        duplicateProps.add('rdf:rest (${restTriples.length} values)');
      }

      final foundPattern =
          'Multiple values for RDF List properties: ${duplicateProps.join(', ')}';
      final suggestions = [
        'Use reader.getValues<T>(predicate).toList() for collections with multiple values',
        'Note: This approach doesn\'t preserve order but handles multiple values correctly',
        'RDF List nodes must have exactly one rdf:first and one rdf:rest property'
      ];

      throw InvalidRdfListStructureException(
        subject: currentNode,
        foundTriples: subjectTriples,
        foundPattern: foundPattern,
        suggestions: suggestions,
      );
    }

    return (first: firstTriples.single, rest: restTriples.single);
  }

  /// Checks if any predicate appears multiple times in the triples.
  bool _hasMultipleValuesForSamePredicate(Iterable<Triple> triples) {
    final predicateCounts = <RdfPredicate, int>{};
    for (final triple in triples) {
      predicateCounts[triple.predicate] =
          (predicateCounts[triple.predicate] ?? 0) + 1;
    }
    return predicateCounts.values.any((count) => count > 1);
  }

  /// Formats a predicate for display in error messages.
  String _formatPredicate(RdfPredicate predicate) {
    if (predicate is IriTerm) {
      final iri = predicate.value;
      // Try to show common namespace prefixes
      if (iri.startsWith('http://www.w3.org/1999/02/22-rdf-syntax-ns#')) {
        return 'rdf:${iri.substring('http://www.w3.org/1999/02/22-rdf-syntax-ns#'.length)}';
      } else if (iri.startsWith('http://www.w3.org/2000/01/rdf-schema#')) {
        return 'rdfs:${iri.substring('http://www.w3.org/2000/01/rdf-schema#'.length)}';
      } else if (iri.startsWith('http://schema.org/')) {
        return 'schema:${iri.substring('http://schema.org/'.length)}';
      }
      return '<$iri>';
    }
    return predicate.toString();
  }
}

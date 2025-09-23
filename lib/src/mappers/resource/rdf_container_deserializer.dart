import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// Deserializer for RDF Sequence (rdf:Seq) containers to Dart `List<T>` collections.
///
/// This deserializer converts RDF Sequence containers (using numbered properties
/// like `rdf:_1`, `rdf:_2`, etc.) back into Dart lists. It is designed to work
/// with the deserialization infrastructure and handle RDF containers within
/// larger object graphs.
///
/// **RDF Container Handling**: Processes RDF Sequence containers where elements
/// are referenced using numbered properties (`rdf:_1`, `rdf:_2`, `rdf:_3`, etc.)
/// with the container typed as `rdf:Seq`. Order is preserved by processing
/// properties in numerical sequence.
///
/// **Element Deserialization**: Individual container elements are deserialized using
/// the provided item deserializer or registry-based lookup for the element type.
///
/// **Primary Usage Pattern**: Used through `ResourceReader` convenience methods:
/// ```dart
/// // Within a deserializer's fromRdfResource method:
/// final reader = context.reader(subject);
///
/// // Required RDF sequence (throws if missing)
/// final chapters = reader.requireRdfSeq<String>(Schema.chapters);
///
/// // Optional RDF sequence (returns null if missing)
/// final tags = reader.optionalRdfSeq<String>(Schema.tags) ?? const [];
///
/// // With custom item deserializer
/// final authors = reader.requireRdfSeq<Person>(
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
///   RdfSeqDeserializer<String>.new,
/// );
/// ```
///
/// **Integration**: Works with `DeserializationContext` to recursively deserialize
/// complex nested structures and track processed triples for completeness validation.
/// This class is not typically instantiated directly or registered in the registry,
/// but rather used by the collection deserialization infrastructure.
class RdfSeqDeserializer<T> extends BaseRdfContainerListDeserializer<T> {
  const RdfSeqDeserializer({Deserializer<T>? itemDeserializer})
      : super(Rdf.Seq, itemDeserializer);
}

/// Deserializer for RDF Alternative (rdf:Alt) containers to Dart `List<T>` collections.
///
/// RDF Alternatives represent a set of alternative values where typically only
/// one should be chosen. The numbered properties may indicate preference order.
class RdfAltDeserializer<T> extends BaseRdfContainerListDeserializer<T> {
  const RdfAltDeserializer({Deserializer<T>? itemDeserializer})
      : super(Rdf.Alt, itemDeserializer);
}

/// Deserializer for RDF Bag (rdf:Bag) containers to Dart `List<T>` collections.
///
/// RDF Bags represent unordered collections where duplicates are allowed.
/// The numbered properties don't imply any ordering semantics, but we preserve
/// the order found in the RDF graph for consistency.
class RdfBagDeserializer<T> extends BaseRdfContainerListDeserializer<T> {
  const RdfBagDeserializer({Deserializer<T>? itemDeserializer})
      : super(Rdf.Bag, itemDeserializer);
}

class BaseRdfContainerListDeserializer<T>
    with RdfContainerDeserializerMixin<T>
    implements UnifiedResourceDeserializer<List<T>> {
  final Deserializer<T>? _deserializer;

  @override
  final IriTerm? typeIri;

  /// Creates an RDF container deserializer for `List<T>`.
  ///
  /// [typeIri] The RDF container type (rdf:Seq, rdf:Bag, or rdf:Alt)
  /// [itemDeserializer] Optional deserializer for container elements. If not provided,
  /// element deserialization will be resolved through the registry.
  const BaseRdfContainerListDeserializer(this.typeIri, [this._deserializer]);

  @override
  List<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
    if (subject is! BlankNodeTerm) {
      throw ArgumentError(
          """Expected subject to be a BlankNodeTerm but found: $subject. 
          RDF containers are typically represented as blank nodes since they are 
          anonymous collections. If you need to work with named containers (IRIs), 
          please implement a custom deserializer.
          
          You can use the BaseRdfContainerDeserializer base class to help with 
          the implementation details.""");
    }
    return readRdfContainer(subject, context, typeIri, _deserializer).toList();
  }
}

/// Abstract base class for deserializing RDF container structures to Dart collections.
///
/// This class provides common functionality for converting RDF container representations
/// (using numbered properties like `rdf:_1`, `rdf:_2`, etc.) back into Dart collection
/// types. Concrete implementations specify the target collection type `C` and element type `T`.
///
/// **RDF Container Types**: Supports all three standard RDF container types:
/// - **rdf:Seq**: Ordered sequences where numbered properties indicate position
/// - **rdf:Bag**: Unordered collections where numbered properties don't imply order
/// - **rdf:Alt**: Alternative values where numbered properties may indicate preference
///
/// **Container Structure**: RDF containers use numbered properties to reference elements:
/// ```turtle
/// _:container a rdf:Seq ;
///   rdf:_1 "first element" ;
///   rdf:_2 "second element" ;
///   rdf:_3 "third element" .
/// ```
///
/// **Element Processing**: Each numbered property value is deserialized using the
/// provided item deserializer or registry-based lookup, enabling complex nested
/// objects within collections.
///
/// **Processing Approach**: Loads all triples for the container subject first, then
/// yields deserialized elements on-demand. While the generator pattern provides lazy
/// iteration over results, the container structure is parsed upfront.
///
/// **Type Parameters**:
/// - `C`: The target collection type (e.g., `List<String>`, `Set<Person>`)
/// - `T`: The element type within the collection (e.g., `String`, `Person`)
///
/// Subclasses must implement `fromRdfResource()` to convert the lazy iterable
/// into the specific collection type required.
abstract mixin class RdfContainerDeserializerMixin<T> {
  /// Reads an RDF container structure and converts it to a typed Dart iterable.
  ///
  /// This method processes an RDF container (using numbered properties like `rdf:_1`,
  /// `rdf:_2`, etc.) and deserializes each element to the specified type T. RDF containers
  /// are commonly used to represent collections in RDF graphs.
  ///
  /// **RDF Container Structure**: An RDF container consists of:
  /// - A container type declaration (e.g., `rdf:type rdf:Seq`)
  /// - Numbered properties: `rdf:_1`, `rdf:_2`, `rdf:_3`, etc.
  /// - Each numbered property points to a container element
  ///
  /// **Lazy Evaluation**: The method returns an iterable that yields deserialized elements
  /// on-demand, though the container structure (numbered properties) is parsed upfront.
  /// This provides efficient iteration without requiring all elements to be deserialized
  /// at once, particularly beneficial when not all elements are needed.
  ///
  /// **Empty Container Handling**: If no numbered properties are found, returns an empty iterable.
  ///
  /// **Ordering**: Elements are returned in numerical order of their properties (rdf:_1, rdf:_2, etc.)
  /// regardless of the container type. Note that while rdf:Bag semantically has no order,
  /// we preserve the numerical order for consistency.
  ///
  /// **Usage by Subclasses**: Concrete deserializers should call this method from
  /// their `fromRdfResource()` implementation and convert the result to the target
  /// collection type:
  /// ```dart
  /// @override
  /// List<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
  ///   return readRdfContainer(subject, context).toList();
  /// }
  /// ```
  ///
  /// [subject] The RDF subject representing the container.
  /// [context] The deserialization context providing access to the RDF graph and deserializers.
  ///
  /// Returns a lazy iterable of deserialized container elements of type T in numerical order.
  ///
  /// Throws [ArgumentError] if the container type doesn't match the expected type.
  /// Throws [DeserializationException] if element deserialization fails.
  Iterable<T> readRdfContainer(
    RdfSubject subject,
    DeserializationContext context,
    IriTerm? typeIri,
    Deserializer<T>? deserializer,
  ) sync* {
    // Get all triples for this subject
    final allTriples = context.getTriplesForSubject(subject,
        includeBlankNodes: false, trackRead: false);
    final subjectTriples =
        allTriples.where((t) => t.subject == subject).toList();

    // Validate container type if specified
    if (typeIri != null) {
      final typeTriples = subjectTriples
          .where((t) => t.predicate == Rdf.type && t.object == typeIri)
          .toList();

      if (typeTriples.isEmpty) {
        final foundTypes = subjectTriples
            .where((t) => t.predicate == Rdf.type)
            .map((t) => t.object)
            .toList();

        throw ArgumentError(
            'Expected container of type ${_formatIri(typeIri)} but found types: '
            '${foundTypes.map(_formatObject).join(', ')}. '
            'Make sure the container has the correct rdf:type declaration.');
      }
    }

    // Find all numbered properties (rdf:_1, rdf:_2, etc.)
    final numberedTriples = <int, Triple>{};
    final rdfNamespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

    for (final triple in subjectTriples) {
      if (triple.predicate is IriTerm) {
        final predicateIri = (triple.predicate as IriTerm).value;
        if (predicateIri.startsWith('${rdfNamespace}_')) {
          final numberStr = predicateIri.substring('${rdfNamespace}_'.length);
          final number = int.tryParse(numberStr);
          if (number != null && number > 0) {
            numberedTriples[number] = triple;
          }
        }
      }
    }

    // Track all triples we're processing
    final processedTriples = [
      ...subjectTriples.where((t) => t.predicate == Rdf.type),
      ...numberedTriples.values,
    ];
    context.trackTriplesRead(subject, processedTriples);

    // Sort by number and yield elements in order
    final sortedNumbers = numberedTriples.keys.toList()..sort();

    for (final number in sortedNumbers) {
      final triple = numberedTriples[number]!;
      final object = triple.object;
      final deserialized =
          context.deserialize<T>(object, deserializer: deserializer);
      yield deserialized;
    }
  }

  /// Formats an IRI for display in error messages.
  String _formatIri(IriTerm iri) {
    final iriStr = iri.value;
    // Try to show common namespace prefixes
    if (iriStr.startsWith('http://www.w3.org/1999/02/22-rdf-syntax-ns#')) {
      return 'rdf:${iriStr.substring('http://www.w3.org/1999/02/22-rdf-syntax-ns#'.length)}';
    } else if (iriStr.startsWith('http://www.w3.org/2000/01/rdf-schema#')) {
      return 'rdfs:${iriStr.substring('http://www.w3.org/2000/01/rdf-schema#'.length)}';
    } else if (iriStr.startsWith('http://schema.org/')) {
      return 'schema:${iriStr.substring('http://schema.org/'.length)}';
    }
    return '<$iriStr>';
  }

  /// Formats an RDF object for display in error messages.
  String _formatObject(RdfObject object) {
    if (object is IriTerm) {
      return _formatIri(object);
    } else if (object is LiteralTerm) {
      return '"${object.value}"';
    } else {
      return object.toString();
    }
  }
}

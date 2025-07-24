import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// Serializer for Dart `List<T>` collections to RDF list structures.
///
/// This serializer converts Dart lists into RDF's standard linked list representation
/// using `rdf:first` and `rdf:rest` properties. It is designed to be used with
/// `ResourceBuilder.addCollection()` by other resource serializers to handle list
/// properties within larger RDF structures.
///
/// **Primary Usage Pattern**: Used with `ResourceBuilder.addCollection()`:
/// ```dart
/// // Within a resource serializer implementation:
/// builder.addCollection<List<String>, String>(
///   Schema.keywords,
///   object.tags,
///   RdfListSerializer<String>.new,
///   itemSerializer: StringSerializer(),
/// );
/// ```
///
/// **Convenience Method**: For the common case of adding RDF lists, use the
/// convenience method `ResourceBuilder.addRdfList()`:
/// ```dart
/// // Preferred approach for simple list serialization:
/// builder.addRdfList(Schema.keywords, object.tags);
///
/// // With custom item serializer:
/// builder.addRdfList(Schema.authors, object.authors,
///   itemSerializer: PersonSerializer());
/// ```
///
/// **Element Serialization**: Individual list elements are serialized using the
/// provided item serializer. If no serializer is specified, the registry will
/// be consulted to find appropriate serializers for each element type.
///
/// **Integration**: This serializer is not typically registered in the registry
/// or used directly, but rather instantiated on-demand by the collection
/// serialization infrastructure.
class RdfListSerializer<T>
    with RdfListSerializerMixin<T>
    implements UnifiedResourceSerializer<List<T>> {
  final Serializer<T>? itemSerializer;

  /// Creates an RDF list serializer for `List<T>`.
  ///
  /// [itemSerializer] Optional serializer for list elements. If not provided,
  /// element serialization will be resolved through the registry.
  const RdfListSerializer({this.itemSerializer});

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      List<T> values, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfList(values, context, itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }
}

/// Mixin class for serializing collection types to RDF list structures.
///
/// This class provides common functionality for converting Dart collections into
/// RDF list representations using the standard `rdf:first` and `rdf:rest` linked
/// list pattern. Concrete implementations specify the collection type `C` and
/// element type `T`.
///
/// **RDF List Pattern**: Creates linked list structures where each node contains:
/// - `rdf:first`: Points to the serialized form of the current element
/// - `rdf:rest`: Points to the next list node, or `rdf:nil` for the last element
///
/// **Element Serialization**: Individual elements are serialized using the
/// provided item serializer or registry-based lookup, enabling complex nested
/// objects within collections.
///
/// **Type Parameters**:
/// - `C`: The collection type being serialized (e.g., `List<String>`, `Set<Person>`)
/// - `T`: The element type within the collection (e.g., `String`, `Person`)
///
/// Subclasses must implement `toRdfResource()` to handle the specific collection
/// type and call `buildRdfList()` with the appropriate iterable.
abstract mixin class RdfListSerializerMixin<T> {
  IriTerm? get typeIri => Rdf.List;

  /// Builds an RDF list structure from a Dart iterable.
  ///
  /// This method creates the standard RDF list representation using `rdf:first` and
  /// `rdf:rest` properties to form a linked list structure. The implementation
  /// processes elements lazily for memory efficiency with large collections.
  ///
  /// **Usage by Subclasses**: Concrete serializers should call this method from
  /// their `toRdfResource()` implementation, passing the collection as an iterable.
  ///
  /// Example implementation:
  /// ```dart
  /// @override
  /// (RdfSubject, Iterable<Triple>) toRdfResource(List<T> values, SerializationContext context,
  ///     {RdfSubject? parentSubject}) {
  ///   final (subject, triples) = buildRdfList(values, context, parentSubject: parentSubject);
  ///   return (subject, triples.toList());
  /// }
  /// ```
  ///
  /// [values] The iterable of values to convert into an RDF list
  /// [context] The serialization context for element serialization
  /// [headNode] Optional existing subject to use as the list head
  /// [parentSubject] Optional parent subject for nested serialization context
  ///
  /// Returns a tuple containing the list head subject and the complete triple iterable.
  (RdfSubject headNode, Iterable<Triple> triples) buildRdfList(
      Iterable<T> values,
      SerializationContext context,
      Serializer<T>? serializer,
      {RdfSubject? headNode,
      RdfSubject? parentSubject}) {
    if (values.isEmpty) {
      return (Rdf.nil, const []);
    }

    headNode ??= BlankNodeTerm();
    return (
      headNode,
      _buildRdfListTriples(context, values.iterator, headNode,
          serializer: serializer, parentSubject: parentSubject)
    );
  }

  Iterable<Triple> _buildRdfListTriples(
      SerializationContext context, Iterator<T> iterator, RdfSubject headNode,
      {Serializer<T>? serializer, RdfSubject? parentSubject}) sync* {
    if (!iterator.moveNext()) {
      return;
    }

    var currentNode = headNode;

    do {
      final value = iterator.current;

      // Serialize the current value
      final (valueTerms, valueTriples) = context.serialize<T>(value,
          parentSubject: parentSubject, serializer: serializer);

      // Yield all triples from the serialized value
      yield* valueTriples;

      // Add rdf:first triple
      for (final valueTerm in valueTerms) {
        yield Triple(currentNode, Rdf.first, valueTerm as RdfObject);
      }

      // Check if there are more elements
      final hasNext = iterator.moveNext();

      if (hasNext) {
        // Not last element: create next node and point to it
        final nextNode = BlankNodeTerm();
        yield Triple(currentNode, Rdf.rest, nextNode);
        currentNode = nextNode;
      } else {
        // Last element: point to rdf:nil
        yield Triple(currentNode, Rdf.rest, Rdf.nil);
        break;
      }
    } while (true);
  }
}

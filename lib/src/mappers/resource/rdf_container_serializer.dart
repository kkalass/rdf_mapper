import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// Serializer for Dart `List<T>` collections to RDF Sequence (rdf:Seq) containers.
///
/// This serializer converts Dart lists into RDF's standard container representation
/// using numbered properties like `rdf:_1`, `rdf:_2`, etc. It preserves the order
/// of elements and is designed to be used with `ResourceBuilder.addCollection()`
/// by other resource serializers to handle ordered list properties within larger
/// RDF structures.
///
/// **Primary Usage Pattern**: Used with `ResourceBuilder.addCollection()`:
/// ```dart
/// // Within a resource serializer implementation:
/// builder.addCollection<List<String>, String>(
///   Schema.keywords,
///   object.tags,
///   (itemSerializer) => RdfSeqSerializer<String>(itemSerializer),
/// );
/// ```
///
/// **Convenience Method**: For the common case of adding RDF sequences, use the
/// convenience method `ResourceBuilder.addRdfSeq()`:
/// ```dart
/// // Preferred approach for simple sequence serialization:
/// builder.addRdfSeq(Schema.hasPart, object.chapters);
///
/// // With custom item serializer:
/// builder.addRdfSeq(Schema.hasPart, object.chapters,
///   itemSerializer: ChapterSerializer());
/// ```
///
/// **Element Serialization**: Individual list elements are serialized using the
/// provided item serializer. If no serializer is specified, the registry will
/// be consulted to find appropriate serializers for each element type.
///
/// **RDF Container Structure**: Creates containers with numbered properties:
/// ```turtle
/// _:container a rdf:Seq ;
///   rdf:_1 "first element" ;
///   rdf:_2 "second element" ;
///   rdf:_3 "third element" .
/// ```
///
/// **Integration**: This serializer is not typically registered in the registry
/// or used directly, but rather instantiated on-demand by the collection
/// serialization infrastructure.
class RdfSeqSerializer<T> extends BaseRdfContainerListSerializer<T> {
  /// Creates an RDF sequence serializer for `List<T>`.
  ///
  /// RDF Sequences (rdf:Seq) are ordered containers that preserve element order
  /// using numbered properties (rdf:_1, rdf:_2, etc.).
  ///
  /// [itemSerializer] Optional serializer for list elements. If not provided,
  /// element serialization will be resolved through the registry.
  const RdfSeqSerializer({Serializer<T>? itemSerializer})
      : super(Rdf.Seq, itemSerializer);
}

/// Serializer for Dart `List<T>` collections to RDF Alternative (rdf:Alt) containers.
///
/// RDF Alternatives represent a set of alternative values where typically only
/// one should be chosen. The order may indicate preference.
///
/// **Convenience Method**: For the common case of adding RDF alternatives, use the
/// convenience method `ResourceBuilder.addRdfAlt()`:
/// ```dart
/// // Preferred approach for alternatives:
/// builder.addRdfAlt(Schema.name, ['English Title', 'German Title', 'French Title']);
///
/// // With custom item serializer:
/// builder.addRdfAlt(Schema.image, object.alternativeImages,
///   itemSerializer: ImageSerializer());
/// ```
class RdfAltSerializer<T> extends BaseRdfContainerListSerializer<T> {
  /// Creates an RDF alternative serializer for `List<T>`.
  ///
  /// RDF Alternatives (rdf:Alt) represent alternative values using numbered
  /// properties, where the order may indicate preference.
  ///
  /// [itemSerializer] Optional serializer for list elements. If not provided,
  /// element serialization will be resolved through the registry.
  const RdfAltSerializer({Serializer<T>? itemSerializer}) : super(Rdf.Alt);
}

/// Serializer for Dart `List<T>` collections to RDF Bag (rdf:Bag) containers.
///
/// RDF Bags represent unordered collections where duplicates are allowed.
/// The numbered properties don't imply any ordering semantics.
///
/// **Convenience Method**: For the common case of adding RDF bags, use the
/// convenience method `ResourceBuilder.addRdfBag()`:
/// ```dart
/// // Preferred approach for unordered collections:
/// builder.addRdfBag(Schema.keywords, object.tags);
///
/// // With custom item serializer:
/// builder.addRdfBag(Schema.contributor, object.contributors,
///   itemSerializer: PersonSerializer());
/// ```
class RdfBagSerializer<T> extends BaseRdfContainerListSerializer<T> {
  /// Creates an RDF bag serializer for `List<T>`.
  ///
  /// RDF Bags (rdf:Bag) are unordered containers where the numbered properties
  /// (rdf:_1, rdf:_2, etc.) don't imply any ordering semantics.
  ///
  /// [itemSerializer] Optional serializer for list elements. If not provided,
  /// element serialization will be resolved through the registry.
  const RdfBagSerializer({Serializer<T>? itemSerializer})
      : super(Rdf.Bag, itemSerializer);
}

/// Base serializer for Dart `List<T>` collections to RDF container structures.
///
/// This class provides the common implementation for all RDF container types
/// (Seq, Bag, Alt) that serialize Dart lists to RDF containers with numbered
/// properties.
class BaseRdfContainerListSerializer<T>
    with RdfContainerSerializerMixin<T>
    implements UnifiedResourceSerializer<List<T>> {
  final IriTerm typeIri;
  final Serializer<T>? itemSerializer;

  /// Creates an RDF container serializer for `List<T>`.
  ///
  /// [typeIri] The RDF container type (rdf:Seq, rdf:Bag, or rdf:Alt)
  /// [itemSerializer] Optional serializer for list elements. If not provided,
  /// element serialization will be resolved through the registry.
  const BaseRdfContainerListSerializer(this.typeIri, [this.itemSerializer]);

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      List<T> values, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfContainer(
        BlankNodeTerm(), values, context, typeIri, itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }
}

/// Mixin for serializing collection types to RDF container structures.
///
/// This class provides common functionality for converting Dart collections into
/// RDF container representations using numbered properties (rdf:_1, rdf:_2, etc.).
/// Concrete implementations specify the collection type `C` and element type `T`.
///
/// **RDF Container Pattern**: Creates container structures with:
/// - A typed container subject (rdf:Seq, rdf:Bag, or rdf:Alt)
/// - Numbered properties: `rdf:_1`, `rdf:_2`, `rdf:_3`, etc.
/// - Each numbered property points to a serialized collection element
///
/// **Container Types**:
/// - **rdf:Seq**: Ordered sequence where order matters
/// - **rdf:Bag**: Unordered collection where order doesn't matter
/// - **rdf:Alt**: Alternative values where order may indicate preference
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
/// type and call `buildRdfContainer()` with the appropriate iterable.
abstract mixin class RdfContainerSerializerMixin<T> {
  /// Builds an RDF container structure from a Dart iterable.
  ///
  /// This method creates RDF container representations using numbered properties
  /// (rdf:_1, rdf:_2, etc.) to reference collection elements. The container is
  /// typed with the appropriate RDF container type (Seq, Bag, or Alt).
  ///
  /// **Container Structure Created**:
  /// ```turtle
  /// _:container a rdf:Seq ;  # or rdf:Bag, rdf:Alt
  ///   rdf:_1 <first-element> ;
  ///   rdf:_2 <second-element> ;
  ///   rdf:_3 <third-element> .
  /// ```
  ///
  /// **Lazy Evaluation**: The method returns an iterable that generates triples
  /// on-demand, making it memory-efficient for large collections.
  ///
  /// **Usage by Subclasses**: Concrete serializers should call this method from
  /// their `toRdfResource()` implementation, passing the collection as an iterable.
  ///
  /// Example implementation:
  /// ```dart
  /// @override
  /// (RdfSubject, Iterable<Triple>) toRdfResource(List<T> values, SerializationContext context,
  ///     {RdfSubject? parentSubject}) {
  ///   final (subject, triples) = buildRdfContainer(
  ///       BlankNodeTerm(), values, context, parentSubject: parentSubject);
  ///   return (subject, triples.toList());
  /// }
  /// ```
  ///
  /// [containerSubject] The RDF subject to use as the container (typically a blank node)
  /// [values] The iterable of values to convert into an RDF container
  /// [context] The serialization context for element serialization
  /// [parentSubject] Optional parent subject for nested serialization context
  ///
  /// Returns a tuple containing the container subject and the complete triple iterable.
  (RdfSubject headNode, Iterable<Triple> triples) buildRdfContainer(
      RdfSubject containerSubject,
      Iterable<T> values,
      SerializationContext context,
      IriTerm typeIri,
      Serializer<T>? serializer,
      {RdfSubject? parentSubject}) {
    return (
      containerSubject,
      _buildRdfContainerTriples(
          containerSubject, values, context, typeIri, serializer,
          parentSubject: parentSubject)
    );
  }

  /// Generates RDF container triples using a memory-efficient lazy approach.
  ///
  /// This generator function yields triples on-demand, following the same pattern
  /// as the RDF list serializer for consistency and memory efficiency.
  ///
  /// **Performance**: Processes elements lazily, making it suitable for large
  /// collections without requiring all triples to be stored in memory simultaneously.
  Iterable<Triple> _buildRdfContainerTriples(
      RdfSubject containerSubject,
      Iterable<T> values,
      SerializationContext context,
      IriTerm typeIri,
      Serializer<T>? serializer,
      {RdfSubject? parentSubject}) sync* {
    // Add the container type triple (rdf:Seq, rdf:Bag, or rdf:Alt)
    yield Triple(containerSubject, Rdf.type, typeIri);

    if (values.isEmpty) {
      return;
    }

    var counter = 1;
    for (final value in values) {
      if (value == null) {
        throw ArgumentError('Cannot serialize null value in collection');
      }
      final (itemObjects, extraTriples) = context.serialize(value,
          parentSubject: parentSubject, serializer: serializer);

      // Yield all triples from the serialized value first
      yield* extraTriples;

      // Then yield the container membership triples
      for (final itemObject in itemObjects) {
        yield Triple(
            containerSubject,
            context.createIriTerm('${Rdf.namespace}_$counter'),
            itemObject as RdfObject);
      }

      counter++;
    }
  }
}

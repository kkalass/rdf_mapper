import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Base marker interface for bidirectional RDF mappers.
///
/// A mapper combines the functionality of both a serializer and a deserializer,
/// providing bidirectional conversion between Dart objects and RDF representations.
/// This integration simplifies the common case where a type needs both serialization and
/// deserialization capabilities.
///
/// Mappers are the recommended base for custom implementations as they provide
/// a complete solution for both directions of mapping. They are registered with
/// [RdfMapperRegistry] to enable automatic type handling during serialization
/// and deserialization operations.
///
/// This is a marker interface that specific mapper interfaces extend.
sealed class Mapper<T> {
  const Mapper();
}

/// Bidirectional mapper between Dart objects and RDF local resources.
///
/// Combines the functionality of blank node deserialization and serialization
/// for handling anonymous nodes in RDF graphs. Blank nodes represent resources
/// without a globally unique identifier (URI), often used for resources that only
/// have local significance within a graph.
///
/// Use this mapper type when:
/// - Your object doesn't need a stable, externally-referenceable identity
/// - The object is primarily a composition element of other objects
/// - The object won't be referenced across different RDF documents
///
/// Example usage scenarios: complex nested structures, intermediate nodes in
/// object relationships, or helper objects that don't need independent identity.
abstract interface class LocalResourceMapper<T>
    implements
        Mapper<T>,
        LocalResourceDeserializer<T>,
        LocalResourceSerializer<T> {}

/// Bidirectional mapper for converting between Dart objects and collections of unmapped RDF triples.
///
/// This mapper type is fundamental to lossless RDF mapping, enabling the preservation
/// of RDF triples that are not explicitly handled by other mappers in your domain model.
/// It provides the mechanism for round-trip fidelity when working with RDF data that
/// contains more information than what your object model explicitly represents.
///
/// The mapper converts between:
/// - Collections of [Triple] instances (representing raw RDF data)
/// - Typed Dart objects that can store and manage these triples
///
/// Common implementations:
/// - [RdfGraphMapper]: Maps to/from [RdfGraph] instances (default)
/// - Custom mappers: For specialized graph data structures or optimized storage
///
/// Usage in lossless mapping:
/// ```dart
/// class Person {
///   final String name;
///   final RdfGraph unmappedGraph; // Handled by RdfGraphMapper
/// }
///
/// class PersonMapper implements GlobalResourceMapper<Person> {
///   @override
///   Person fromRdfResource(IriTerm subject, DeserializationContext context) {
///     final reader = context.reader(subject);
///     return Person(
///       name: reader.require<String>(foafName),
///       unmappedGraph: reader.getUnmapped<RdfGraph>(), // Uses UnmappedTriplesMapper
///     );
///   }
/// }
/// ```
///
/// This mapper type is automatically discovered when:
/// - Using [ResourceReader.getUnmapped] during deserialization
/// - Using [ResourceBuilder.addUnmapped] during serialization
/// - The type [T] has a registered [UnmappedTriplesMapper]
abstract interface class UnmappedTriplesMapper<T>
    implements
        Mapper<T>,
        UnmappedTriplesDeserializer<T>,
        UnmappedTriplesSerializer<T> {}

/// Bidirectional mapper between Dart objects and RDF IRI terms.
///
/// Combines the functionality of both [IriTermSerializer] and [IriTermDeserializer]
/// for seamless conversion between Dart objects and RDF IRI terms in both directions.
/// IRI terms represent resources in RDF using Internationalized Resource Identifiers.
///
/// This mapper type is useful for:
/// - Handling objects that represent simple URI/IRI identifiers
/// - Converting between IRI strings and typed objects
/// - Working with identifier types or wrapper classes
///
/// Unlike [GlobalResourceMapper], this mapper only deals with the IRI itself, not with
/// the associated triples that describe the resource the IRI identifies.
abstract interface class IriTermMapper<T>
    implements Mapper<T>, IriTermSerializer<T>, IriTermDeserializer<T> {}

/// Bidirectional mapper between Dart objects and RDF literal terms.
///
/// Combines the functionality of both [LiteralTermSerializer] and [LiteralTermDeserializer]
/// for seamless conversion between Dart objects and RDF literal terms in both directions.
/// Literal terms represent concrete data values in RDF like strings, numbers, dates, etc.
///
/// IMPORTANT: Literal terms on their own are not valid RDF - they can only exist as
/// objects in RDF triples (subject-predicate-object). This mapper cannot be used directly
/// to serialize/deserialize a complete RDF document from a standalone object. Instead,
/// literal term mappers are typically used for property values within resource mappers.
///
/// This mapper type is recommended for:
/// - Primitive types and their wrappers (String, int, double, DateTime, etc.)
/// - Custom value types that should be represented as RDF literals
/// - Any type that conceptually represents a single value rather than an entity
///
/// Most built-in Dart types will have standard implementations of this mapper.
abstract interface class LiteralTermMapper<T>
    implements
        Mapper<T>,
        LiteralTermSerializer<T>,
        LiteralTermDeserializer<T> {}

/// Bidirectional mapper between Dart objects and RDF subjects with associated triples.
///
/// Combines the functionality of both [ResourceSerializer] and [GlobalResourceDeserializer]
/// for seamless conversion between Dart objects and RDF subjects in both directions.
/// This mapper handles complex objects that are represented as a subject with
/// multiple associated triples in an RDF graph.
///
/// This mapper type is ideal for:
/// - Domain entities with multiple properties
/// - Objects that need a stable, globally unique identifier (IRI)
/// - Resources that might be referenced across different documents
/// - Objects with complex property relationships
///
/// This is the most commonly implemented mapper type for domain model classes.
abstract interface class GlobalResourceMapper<T>
    implements
        Mapper<T>,
        GlobalResourceSerializer<T>,
        GlobalResourceDeserializer<T> {}

/// A common base for resource mappers that can handle both global (IRI)
/// and local (Blank Node) RDF subjects.
///
/// This class provides the core logic for mapping between Dart objects and
/// RDF subjects (IRIs or Blank Nodes) and their associated triples.
/// It uses adapter classes (_GlobalResourceMapper and _LocalResourceMapper)
/// to conform to the specific GlobalResourceMapper and LocalResourceMapper interfaces.
///
/// During registration with [RdfMapperRegistry], the [asGlobalDeserializer],
/// [asLocalDeserializer] and [asSerializer] methods are automatically called to register the mapper
/// as both a [GlobalResourceMapper] and [LocalResourceMapper] internally.
/// This allows the same implementation to handle both IRI-based and blank
/// node-based RDF subjects seamlessly.
///
abstract class CommonResourceMapper<T> extends Mapper<T> {
  const CommonResourceMapper();

  /// Converts an RDF subject (IRI or Blank Node) to a Dart object of type [T].
  T fromRdfResource<S extends RdfSubject>(
      S subject, DeserializationContext context);

  /// Converts a Dart object of type [T] to an RDF subject (IRI or Blank Node)
  /// and its associated triples.
  (RdfSubject, List<Triple>) toRdfResource(
      T value, SerializationContext context,
      {RdfSubject? parentSubject});

  IriTerm? get typeIri;

  /// Returns a [GlobalResourceDeserializer] view of this common mapper.
  GlobalResourceDeserializer<T> asGlobalDeserializer() =>
      _GlobalResourceDeserializer<T>(this);

  /// Returns a [LocalResourceDeserializer] view of this common mapper.
  LocalResourceDeserializer<T> asLocalDeserializer() =>
      _LocalResourceDeserializer<T>(this);

  /// Returns a [LocalResourceDeserializer] view of this common mapper.
  ResourceSerializer<T> asSerializer() => _CommonResourceSerializer<T>(this);
}

// These are internal adapter classes, typically used only by CommonResourceMapper.
class _GlobalResourceDeserializer<T> implements GlobalResourceDeserializer<T> {
  final CommonResourceMapper<T> _mapper;

  _GlobalResourceDeserializer(CommonResourceMapper<T> mapper)
      : _mapper = mapper;

  @override
  T fromRdfResource(IriTerm subject, DeserializationContext context) =>
      _mapper.fromRdfResource(subject, context);

  @override
  IriTerm? get typeIri => _mapper.typeIri;

  @override
  String toString() => 'GlobalDeserializer: ${_mapper.toString()}';
}

class _LocalResourceDeserializer<T> implements LocalResourceDeserializer<T> {
  final CommonResourceMapper<T> _mapper;

  _LocalResourceDeserializer(CommonResourceMapper<T> mapper) : _mapper = mapper;

  @override
  T fromRdfResource(BlankNodeTerm subject, DeserializationContext context) =>
      _mapper.fromRdfResource(subject, context);

  @override
  IriTerm? get typeIri => _mapper.typeIri;

  @override
  String toString() => 'LocalDeserializer: ${_mapper.toString()}';
}

class _CommonResourceSerializer<T> implements CommonResourceSerializer<T> {
  final CommonResourceMapper<T> _mapper;

  _CommonResourceSerializer(CommonResourceMapper<T> mapper) : _mapper = mapper;

  @override
  (RdfSubject, List<Triple>) toRdfResource(
          T value, SerializationContext context,
          {RdfSubject? parentSubject}) =>
      _mapper.toRdfResource(value, context, parentSubject: parentSubject);

  @override
  IriTerm? get typeIri => _mapper.typeIri;

  @override
  String toString() => 'Serializer: ${_mapper.toString()}';
}

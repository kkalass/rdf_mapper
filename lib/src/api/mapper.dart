part of 'rdf_mapper_interfaces.dart';

sealed class BaseMapper<T> implements BaseSerializer<T>, BaseDeserializer<T> {
  const BaseMapper();
}

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
sealed class Mapper<T> extends BaseMapper<T>
    implements Serializer<T>, Deserializer<T> {
  const Mapper();
}

abstract interface class MultiObjectsMapper<T>
    implements
        Mapper<T>,
        MultiObjectsDeserializer<T>,
        MultiObjectsSerializer<T> {}

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
        BaseMapper<T>,
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

abstract interface class UnifiedResourceMapper<T>
    implements
        Mapper<T>,
        UnifiedResourceSerializer<T>,
        UnifiedResourceDeserializer<T> {}

typedef CollectionMapperFactory<C, T> = Mapper<C> Function(
    {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer});

/// Adapter that enables type transformation while delegating RDF mapping operations.
///
/// This class allows reusing an existing mapper for type [V] to handle type [T] by providing
/// conversion functions between the two types. It implements the adapter pattern to bridge
/// between related but different types in the mapping process.
///
/// Useful when:
/// - You have an existing mapper for type [V] and need to support a related type [T]
/// - Type [T] can be converted to/from type [V] without semantic loss
/// - You want to avoid duplicating mapping logic for similar types
///
/// Example:
/// ```dart
/// // Adapt a String mapper to handle a custom wrapper type
/// class UserId {
///   final String value;
///   UserId(this.value);
/// }
///
/// final userIdMapper = AdaptingUnifiedResourceMapper<UserId, String>(
///   stringMapper,
///   (userId) => userId.value,        // toWrappedType: UserId → String
///   (value) => UserId(value),        // fromWrappedType: String → UserId
/// );
/// ```
class AdaptingUnifiedResourceMapper<T, V> implements UnifiedResourceMapper<T> {
  final UnifiedResourceMapper<V> _wrappedMapper;
  final V Function(T) _toWrappedType;
  final T Function(V) _fromWrappedType;

  AdaptingUnifiedResourceMapper(
      this._wrappedMapper, this._toWrappedType, this._fromWrappedType);

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
          T value, SerializationContext context, {RdfSubject? parentSubject}) =>
      _wrappedMapper.toRdfResource(_toWrappedType(value), context,
          parentSubject: parentSubject);

  @override
  T fromRdfResource(RdfSubject subject, DeserializationContext context) =>
      _fromWrappedType(_wrappedMapper.fromRdfResource(subject, context));

  @override
  IriTerm? get typeIri => _wrappedMapper.typeIri;
}

/// Adapter that enables type transformation for multi-object mapping operations.
///
/// This class allows reusing an existing multi-objects mapper for type [V] to handle type [T]
/// by providing conversion functions between the two types. It implements the adapter pattern
/// to bridge between related but different collection types in the mapping process.
///
/// Useful when:
/// - You have an existing mapper for collections of type [V] and need to support collections of type [T]
/// - Type [T] can be converted to/from type [V] without semantic loss
/// - You want to avoid duplicating mapping logic for similar collection types
///
/// Example:
/// ```dart
/// // Adapt a List<String> mapper to handle a List<UserId>
/// class UserId {
///   final String value;
///   UserId(this.value);
/// }
///
/// final userIdListMapper = AdaptingMultiObjectsMapper<List<UserId>, List<String>>(
///   stringListMapper,
///   (userIds) => userIds.map((uid) => uid.value).toList(),    // toWrappedType: List<UserId> → List<String>
///   (values) => values.map((v) => UserId(v)).toList(),        // fromWrappedType: List<String> → List<UserId>
/// );
/// ```
class AdaptingMultiObjectsMapper<T, V> implements MultiObjectsMapper<T> {
  final MultiObjectsMapper<V> _wrappedMapper;
  final V Function(T) _toWrappedType;
  final T Function(V) _fromWrappedType;

  AdaptingMultiObjectsMapper(
      this._wrappedMapper, this._toWrappedType, this._fromWrappedType);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          T value, SerializationContext context) =>
      _wrappedMapper.toRdfObjects(_toWrappedType(value), context);

  @override
  T fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      _fromWrappedType(_wrappedMapper.fromRdfObjects(objects, context));
}

class UnifiedResourceMapperBase<T, I> implements UnifiedResourceMapper<T> {
  final UnifiedResourceSerializer<T> _serializer;
  final UnifiedResourceDeserializer<T> _deserializer;

  UnifiedResourceMapperBase(this._serializer, this._deserializer) {
    if (_serializer.typeIri != _deserializer.typeIri) {
      throw ArgumentError('Serializer and deserializer type IRIs do not match: '
          '${_serializer.typeIri} != ${_deserializer.typeIri}');
    }
  }

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
          T value, SerializationContext context,
          {RdfSubject? parentSubject}) =>
      _serializer.toRdfResource(value, context, parentSubject: parentSubject);

  @override
  T fromRdfResource(RdfSubject subject, DeserializationContext context) =>
      _deserializer.fromRdfResource(subject, context);
  @override
  IriTerm? get typeIri => _deserializer.typeIri;
}

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

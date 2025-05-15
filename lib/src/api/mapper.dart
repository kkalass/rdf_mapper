import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

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
sealed class Mapper<T> {}

/// Bidirectional mapper between Dart objects and RDF blank node subjects.
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
abstract interface class BlankNodeMapper<T>
    implements Mapper<T>, BlankNodeDeserializer<T>, BlankNodeSerializer<T> {}

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
/// Unlike [IriNodeMapper], this mapper only deals with the IRI itself, not with
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
/// literal term mappers are typically used for property values within node mappers.
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
/// Combines the functionality of both [NodeSerializer] and [IriNodeDeserializer]
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
abstract interface class IriNodeMapper<T>
    implements Mapper<T>, IriNodeSerializer<T>, IriNodeDeserializer<T> {}

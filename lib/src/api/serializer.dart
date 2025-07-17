part of 'rdf_mapper_interfaces.dart';

sealed class BaseSerializer<T> {}

/// Base marker interface for all RDF serializers.
///
/// Serializers convert Dart objects into RDF representations, enabling the transformation
/// of domain models into semantic web formats. This interface serves as the root
/// of the serializer hierarchy, providing a common type for all serializers.
///
/// The serializer system is divided into two main branches:
/// - [TermSerializer]: For converting objects to single RDF terms
/// - [ResourceSerializer]: For converting objects to subjects with associated triples
///
/// This serves as a semantic marker to group all serializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
sealed class Serializer<T> extends BaseSerializer<T> {}

abstract interface class UnmappedTriplesSerializer<T>
    extends BaseSerializer<T> {
  /// Converts a Dart object to a set of unmapped triples.
  ///
  /// This method processes the given object and converts it into a list of triples
  /// that are not mapped to any specific property or type. This is useful for
  /// handling additional data that doesn't fit into the standard serialization model.
  ///
  /// [subject] The subject IRI of the object being serialized
  /// [value] The object to convert
  ///
  /// Returns the resulting list of triples
  Iterable<Triple> toUnmappedTriples(RdfSubject subject, T value);
}

abstract interface class MultiObjectsSerializer<T> extends Serializer<T> {
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
      T value, SerializationContext context);
}

/// Groups those serializers that serialize a Dart object to an RDF term
/// (i.e. IriTerm or LiteralTerm) and not to a list of Triples.
///
/// Term serializers handle the conversion of Dart objects to individual RDF terms.
/// These are useful for types that naturally map to single values in RDF, such as
/// primitive types, identifiers, or simple value objects.
///
/// Term serializers are used when:
/// - The object represents a single value or identifier
/// - No additional triples are needed to represent the object
/// - The object maps directly to a standard RDF term type
sealed class TermSerializer<T> extends Serializer<T> {}

/// Serializes a Dart object to an RDF IRI term.
///
/// Implementations convert specific Dart types to IRI terms,
/// which are used to represent resources in RDF graphs. This serializer is
/// appropriate for objects that conceptually represent identifiers or references
/// to resources.
///
/// Common use cases include:
/// - URI/URL objects
/// - Custom identifier types
/// - Enumeration values that map to standard IRIs
/// - Reference types that should be serialized as resource references
abstract interface class IriTermSerializer<T> implements TermSerializer<T> {
  /// Converts a value to an IRI term.
  ///
  /// This method transforms the given Dart object into an IRI term that
  /// can be used in RDF triples. The serialization context provides access
  /// to the current serialization state and helps with referencing related objects.
  ///
  /// @param value The value to convert
  /// @param context The current serialization context
  /// @return The resulting IRI term
  IriTerm toRdfTerm(T value, SerializationContext context);
}

/// Serializes a Dart object to an RDF literal term.
///
/// Implementations convert specific Dart types to literal terms,
/// which are used to represent concrete values in RDF graphs. This serializer is
/// suited for primitive types and other objects that represent simple values.
///
/// IMPORTANT: A literal term alone is not a valid complete RDF structure - literals
/// can only appear as objects in RDF triples (subject-predicate-object). This serializer
/// is meant to be used as part of a larger serialization process, typically within
/// a [ResourceSerializer] implementation for handling property values.
///
/// Common use cases include:
/// - Strings, numbers, booleans, and dates
/// - Value objects that conceptually represent single values
/// - Custom types that should be represented as literals
/// - Any value where the string representation is sufficient
abstract interface class LiteralTermSerializer<T> implements TermSerializer<T> {
  /// Converts a value to a literal term.
  ///
  /// This method transforms the given Dart object into a literal term
  /// suitable for use in RDF triples. The serialization context provides access
  /// to the current serialization state and helps with handling related objects.
  ///
  /// @param value The value to convert
  /// @param context The current serialization context
  /// @return The resulting literal term
  LiteralTerm toRdfTerm(T value, SerializationContext context);
}

/// Base class for serializers that convert objects to RDF nodes (subjects with triples).
///
/// Node serializers handle complex objects by generating a subject term and a set of
/// triples that describe the object's properties. These serializers are used for domain
/// entities and objects with multiple properties that need to be represented in RDF.
///
/// The two main specializations are:
/// - [LocalResourceSerializer]: For anonymous resources using blank nodes
/// - [GlobalResourceSerializer]: For identifiable resources using IRIs
sealed class ResourceSerializer<T> extends Serializer<T> {
  /// The IRI of the type of the subject.
  ///
  /// This is used to add an 'rdf:type' triple when serializing to RDF.
  /// It ensures that the serialized data includes type information, which is
  /// crucial for proper deserialization and semantic interpretation.
  ///
  /// If you want to not associate a type with the subject, return null.
  /// This is valid for both BlankNodeTerm and IriTerm subjects, but
  /// it is generally considered good practice to always provide a type IRI.
  ///
  /// Without a type IRI, automatic deserialization may not be possible
  /// as the deserializer selection often depends on the type.
  IriTerm? get typeIri;

  /// Converts a Dart object to an RDF node (subject and associated triples).
  ///
  /// This method is the core of the node serialization process. It:
  /// 1. Creates a subject term (IRI or blank node) to represent the object
  /// 2. Generates a list of triples describing the object's properties
  /// 3. Returns both as a tuple
  ///
  /// The optional [parentSubject] parameter allows establishing relationships
  /// between this object and a parent object during nested serialization.
  ///
  /// @param value The object to serialize
  /// @param context The current serialization context
  /// @param parentSubject Optional parent subject for establishing relationships
  /// @return A tuple containing the subject term and list of associated triples
  (RdfSubject, Iterable<Triple>) toRdfResource(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

/// Serializes Dart objects to RDF blank nodes with associated triples.
///
/// This serializer generates anonymous RDF resources using blank nodes.
/// Blank nodes are useful for resources that don't need stable, global identifiers
/// and exist primarily in relation to other resources.
///
/// Use cases include:
/// - Helper or component objects
/// - Nested structures
/// - Objects whose identity is only significant within the local graph
abstract interface class LocalResourceSerializer<T>
    implements ResourceSerializer<T> {
  @override

  /// Converts a value to a blank node with associated triples.
  ///
  /// The implementation must generate a unique blank node term and a set of
  /// triples that describe the object's properties using that blank node as subject.
  ///
  /// @param value The object to serialize
  /// @param context The serialization context
  /// @param parentSubject Optional parent subject for establishing relationships
  /// @return A tuple with the blank node term and associated triples
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

/// Serializes Dart objects to RDF resources with IRI identifiers and associated triples.
///
/// This serializer generates named RDF resources using IRI terms as subjects.
/// IRIs provide stable, global identifiers for resources, making them suitable for
/// entities that need to be referenced across different contexts.
///
/// This is the most common serializer for domain entities and should be used when:
/// - Objects need stable, persistent identifiers
/// - Resources might be referenced by other resources
/// - The object represents a significant domain entity
abstract interface class GlobalResourceSerializer<T>
    implements ResourceSerializer<T> {
  @override

  /// Converts a value to an IRI-identified node with associated triples.
  ///
  /// The implementation must:
  /// 1. Generate or derive an IRI term for the object
  /// 2. Create triples describing the object's properties
  /// 3. Return both as a tuple
  ///
  /// @param value The object to serialize
  /// @param context The serialization context
  /// @param parentSubject Optional parent subject for establishing relationships
  /// @return A tuple with the IRI term and associated triples
  (IriTerm, Iterable<Triple>) toRdfResource(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

typedef CollectionSerializerFactory<C, T> = Serializer<C> Function(
    {Serializer<T>? itemSerializer});

/// Interface for serializing a Dart collection or container [C] of items [T] into an RDF collection structure.
///
/// Implementations are responsible for creating the RDF triples that define
/// the collection's structure (e.g., rdf:first/rdf:rest for rdf:List, or rdf:_1, rdf:_2 etc. for rdf:Seq etc.).
/// They should use the provided [context] to serialize the individual [T] items,
/// and must accept a Serializer&lt;T&gt; in the constructor for allowing the user to control type-specific serialization.
abstract interface class UnifiedResourceSerializer<C>
    extends ResourceSerializer<C> {}

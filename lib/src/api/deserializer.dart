part of 'rdf_mapper_interfaces.dart';

/// Base marker interface for all RDF deserializers.
///
/// Deserializers convert RDF representations into Dart objects, enabling the transformation
/// of semantic web data into domain models. This interface serves as the root of the
/// deserializer hierarchy, providing a common type for all deserializers.
///
/// The deserializer system is divided into two main branches:
/// - [TermDeserializer]: For converting single RDF terms to objects
/// - [ResourceDeserializer]: For converting subjects with associated triples to objects
///
/// This serves as a semantic marker to group all deserializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
sealed class BaseDeserializer<T> {}

sealed class Deserializer<T> extends BaseDeserializer<T> {}

abstract interface class UnmappedTriplesDeserializer<T>
    implements BaseDeserializer<T> {
  /// Indicates whether this deserializer requires deep triple collection for blank nodes.
  ///
  /// When `true`, the caller should recursively collect all triples
  /// associated with blank nodes that are referenced by the top-level triples
  /// before calling `fromUnmappedTriples`. This includes transitively following
  /// all blank node references to ensure the complete object graph is available.
  ///
  /// When `false`, only the direct top-level triples should be passed to
  /// `fromUnmappedTriples` without following blank node references.
  ///
  /// Returns `false` by default, indicating shallow triple collection.
  bool get deep => false;

  /// Converts a set of unmapped triples to a Dart object.
  ///
  /// This method processes the given triples that were not mapped to any specific
  /// property or type and converts them into a Dart object.
  ///
  /// [triples] The list of triples to convert
  /// [context] The current deserialization context
  ///
  /// Returns the resulting Dart object
  T fromUnmappedTriples(Iterable<Triple> triples);
}

abstract interface class MultiObjectsDeserializer<T>
    implements Deserializer<T> {
  /// Converts a collection of RDF objeccts into a Dart collection of objects.
  ///
  /// This method processes the given objects and their associated triples,
  /// deserializing them into a Dart object of type T.
  ///
  /// [objects] The iterable of RDF objects to convert
  /// [context] The current deserialization context
  ///
  /// Returns the resulting Dart object
  T fromRdfObjects(Iterable<RdfObject> objects, DeserializationContext context);
}

/// Base class for deserializers that convert RDF terms to Dart objects.
///
/// Term deserializers handle the conversion of individual RDF terms to Dart objects.
/// These are useful for primitive types and simple value objects that can be
/// represented as single terms (IRIs or literals) in RDF.
///
/// The two main specializations are:
/// - [IriTermDeserializer]: For converting IRI terms to objects
/// - [LiteralTermDeserializer]: For converting literal terms to objects
sealed class TermDeserializer<T> extends Deserializer<T> {}

/// Deserializes an RDF IRI term to a Dart object.
///
/// Implementations convert IRI terms to specific Dart types,
/// enabling the transformation of RDF resources into domain objects.
/// This deserializer is appropriate for objects that are represented by
/// identifiers or references in RDF.
///
/// Common use cases include:
/// - URI/URL objects
/// - Custom identifier types
/// - Enumeration values that map to standard IRIs
/// - Reference types that are serialized as resource references
abstract interface class IriTermDeserializer<T> implements TermDeserializer<T> {
  /// Converts an IRI term to a value.
  ///
  /// This method transforms the given RDF IRI term into a Dart object.
  /// The deserialization context provides access to the current deserialization
  /// state and helps with resolving related objects.
  ///
  /// [term] The IRI term to convert
  /// [context] The current deserialization context
  ///
  /// Returns the resulting Dart object
  T fromRdfTerm(IriTerm term, DeserializationContext context);
}

/// Deserializes an RDF literal term to a Dart object.
///
/// Implementations convert literal terms to specific Dart types,
/// enabling the transformation of RDF literal values into domain objects.
/// This deserializer is suited for primitive types and other objects that
/// represent simple values.
///
/// IMPORTANT: This deserializer processes only individual literal terms, not
/// complete RDF documents. In RDF, literals can only appear as objects in
/// triples (subject-predicate-object). This deserializer is typically used
/// as part of a larger deserialization process, such as within a [ResourceDeserializer]
/// implementation for handling property values.
///
/// Common use cases include:
/// - Strings, numbers, booleans, and dates
/// - Value objects that conceptually represent single values
/// - Custom types that are represented as literals
/// - Any value where the string representation is sufficient
abstract interface class LiteralTermDeserializer<T>
    implements TermDeserializer<T> {
  /// The RDF datatype this deserializer handles.
  ///
  /// When deserializing a literal term and we do not find a deserializer for
  /// the dart type, we will take a deserializer that matches the
  /// datatype of the literal term. If you do not specify a datatype,
  /// the deserializer will only be used if the target dart type is known and matches exactly.
  ///
  /// This means that we cannot use a deserializer without datatype for deserializing into
  /// a basic dart type like `Object`.
  IriTerm? get datatype;

  /// Converts a literal term to a value.
  ///
  /// This method transforms the given RDF literal term into a Dart object.
  /// The deserialization context provides access to the current deserialization
  /// state and helps with handling related objects.
  ///
  /// [term] The literal term to convert
  /// [context] The current deserialization context
  ///
  /// Returns the resulting Dart object
  T fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false});
}

/// Base class for deserializers that convert RDF subjects with associated triples to Dart objects.
///
/// Resource deserializers handle complex objects by reading a subject and its related triples
/// from an RDF graph. These deserializers are used for domain entities and objects with
/// multiple properties that are represented as subjects with properties in RDF.
///
/// The two main specializations are:
/// - [LocalResourceDeserializer]: For anonymous resources using blank nodes
/// - [GlobalResourceDeserializer]: For identifiable resources using IRIs
sealed class ResourceDeserializer<T> extends Deserializer<T> {
  /// The IRI of the RDF type this deserializer can handle.
  ///
  /// This is used for type-based lookup of deserializers during automatic deserialization.
  /// When a subject with this type IRI is encountered, this deserializer will be selected
  /// to handle the conversion.
  ///
  /// It is optional since it is technically valid (though not recommended) to omit the
  /// RDF type triple for a subject. However, omitting the type will prevent automatic
  /// type-based deserializer selection.
  ///
  /// Without a type IRI, deserialization will only work when you explicitly target
  /// a specific subject with a known Dart type, not when using general methods like
  /// [RdfMapper.decodeObjects].
  IriTerm? get typeIri;
}

/// Deserializes an RDF local resource to a Dart object.
///
/// This deserializer transforms blank nodes and their associated triples into
/// Dart objects. Blank nodes are anonymous resources in RDF without global identifiers,
/// typically used for nested or composed structures.
///
/// Use cases include:
/// - Helper or component objects
/// - Nested structures
/// - Objects whose identity is only significant within the local graph
abstract interface class LocalResourceDeserializer<T>
    implements ResourceDeserializer<T> {
  /// Converts a local resource to a value.
  ///
  /// This method reads a blank node and its associated triples from the graph
  /// and transforms them into a Dart object. The deserialization context provides
  /// access to the graph and helps with resolving related objects.
  ///
  /// [term] The blank node term to convert
  /// [context] The deserialization context, providing access to the graph
  ///
  /// Returns the resulting Dart object
  T fromRdfResource(BlankNodeTerm term, DeserializationContext context);
}

/// Deserializes an RDF IRI-identified subject to a Dart object.
///
/// This deserializer transforms IRI subjects and their associated triples into
/// Dart objects. IRI-identified subjects represent named resources in RDF with
/// global identifiers, typically used for significant domain entities.
///
/// This is the most common deserializer for domain entities and should be used when:
/// - Objects have stable, persistent identifiers
/// - Resources might be referenced by other resources
/// - The object represents a significant domain entity
abstract interface class GlobalResourceDeserializer<T>
    implements ResourceDeserializer<T> {
  /// Converts an IRI-identified global resource to an object of type T.
  ///
  /// This method reads an IRI subject and its associated triples from the graph
  /// and transforms them into a Dart object. The deserialization context provides
  /// access to the graph and helps with resolving related objects.
  ///
  /// [term] The IRI term to convert
  /// [context] The deserialization context providing access to the graph
  ///
  /// Returns the resulting Dart object
  T fromRdfResource(IriTerm term, DeserializationContext context);
}

typedef CollectionDeserializerFactory<C, T> = Deserializer<C> Function(
    {Deserializer<T>? itemDeserializer});

/// Interface for deserializing an RDF collection structure into a Dart collection [C] of items [T].
///
/// Implementations are responsible for traversing the RDF triples that define
/// the collection's (or container's) structure and reconstructing the Dart collection.
/// They should use the provided [context] to deserialize the individual [T] items
/// and must accept a Deserializer&lt;T&gt; in the constructor for allowing the user to control type-specific deserialization.
abstract interface class UnifiedResourceDeserializer<C>
    extends ResourceDeserializer<C> {
  /// Deserializes an RDF collection identified by [collectionHead] into a Dart collection [C].
  ///
  /// The [context] should be used to deserialize individual items within the collection.
  C fromRdfResource(RdfSubject collectionHead, DeserializationContext context);
}

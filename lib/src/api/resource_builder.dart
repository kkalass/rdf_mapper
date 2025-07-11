import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Builder for fluent RDF resource serialization.
///
/// The ResourceBuilder provides a convenient fluent API for constructing RDF resources
/// with their associated triples. It simplifies the process of building complex
/// RDF structures by maintaining the current subject context and offering methods
/// to add various types of predicates and objects.
///
/// This class implements the Builder pattern to enable method chaining, making
/// the code for creating RDF structures more readable and maintainable.
///
/// Key features:
/// - Fluent API for adding properties to RDF subjects
/// - Support for literals, IRIs, and nested resource structures
/// - Conditional methods for handling null or empty values
/// - Type-safe serialization of Dart objects to RDF
///
/// Basic example:
/// ```dart
/// final (subject, triples) = context
///     .resourceBuilder(IriTerm('http://example.org/resource'))
///     .addValue(Dc.title, 'The Title')
///     .addValue(Dc.creator, 'The Author')
///     .build();
/// ```
///
/// More complex example with nested objects:
/// ```dart
/// final (person, triples) = context
///     .resourceBuilder(IriTerm('http://example.org/person/1'))
///     .addValue(Foaf.name, 'John Doe')
///     .addValue(Foaf.age, 30)
///     .addValue(Foaf.address, address)
///     .addValues(Foaf.knows, friends)
///     .build();
/// ```
class ResourceBuilder<S extends RdfSubject> {
  final S _subject;
  final List<Triple> _triples;
  final SerializationService _service;

  /// Creates a new ResourceBuilder for the fluent API.
  ///
  /// This constructor is typically not called directly. Instead, create a
  /// builder through the [SerializationContext.resourceBuilder] method.
  ///
  /// Parameters:
  /// - [_subject]: The RDF subject to build properties for.
  /// - [_service]: The serialization service for converting objects to RDF.
  /// - [initialTriples]: Optional list of initial triples to include.
  ResourceBuilder(this._subject, this._service, {List<Triple>? initialTriples})
      : _triples = initialTriples ?? [];

  ResourceBuilder<S> addValue<V>(
    RdfPredicate predicate,
    V value, {
    LiteralTermSerializer<V>? literalTermSerializer,
    IriTermSerializer<V>? iriTermSerializer,
    ResourceSerializer<V>? resourceSerializer,
  }) {
    _triples.addAll(
      _service.value(_subject, predicate, value,
          literalTermSerializer: literalTermSerializer,
          iriTermSerializer: iriTermSerializer,
          resourceSerializer: resourceSerializer),
    );
    return this;
  }

  /// Adds unmapped RDF triples from a previously captured unmapped data structure.
  ///
  /// This method is essential for lossless mapping, allowing you to restore triples
  /// that were captured using [ResourceReader.getUnmapped] during a previous
  /// deserialization operation. This ensures complete round-trip fidelity when
  /// serializing objects that contain unmapped data.
  ///
  /// The [value] parameter should be a data structure containing RDF triples,
  /// typically an [RdfGraph] or a custom type that implements [UnmappedTriplesMapper].
  /// If no [unmappedTriplesSerializer] is provided, the system will attempt to
  /// find a registered mapper for the type of [value].
  ///
  /// Usage example:
  /// ```dart
  /// return context.resourceBuilder(IriTerm(person.id))
  ///   .addValue(foafName, person.name)
  ///   .addValue(foafAge, person.age)
  ///   .addUnmapped(person.unmappedGraph)  // Restore previously captured data
  ///   .build();
  /// ```
  ///
  /// Parameters:
  /// * [value] - The unmapped data structure containing RDF triples to add
  /// * [unmappedTriplesSerializer] - Optional custom serializer for the unmapped data type
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addUnmapped<V>(
    V value, {
    UnmappedTriplesSerializer<V>? unmappedTriplesSerializer,
  }) {
    _triples.addAll(
      _service.unmappedTriples(_subject, value,
          unmappedTriplesSerializer: unmappedTriplesSerializer),
    );
    return this;
  }

  ResourceBuilder<S> addValueIfNotNull<V>(
    RdfPredicate predicate,
    V? value, {
    LiteralTermSerializer<V>? literalTermSerializer,
    IriTermSerializer<V>? iriTermSerializer,
    ResourceSerializer<V>? resourceSerializer,
  }) {
    if (value == null) {
      return this;
    }
    return addValue(predicate, value,
        literalTermSerializer: literalTermSerializer,
        iriTermSerializer: iriTermSerializer,
        resourceSerializer: resourceSerializer);
  }

  ResourceBuilder<S> addValuesFromSource<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  }) {
    _triples.addAll(
      _service.valuesFromSource(_subject, predicate, toIterable, instance,
          literalTermSerializer: literalTermSerializer,
          iriTermSerializer: iriTermSerializer,
          resourceSerializer: resourceSerializer),
    );
    return this;
  }

  ResourceBuilder<S> addValues<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    LiteralTermSerializer<V>? literalTermSerializer,
    IriTermSerializer<V>? iriTermSerializer,
    ResourceSerializer<V>? resourceSerializer,
  }) {
    _triples.addAll(
      _service.values(
        _subject,
        predicate,
        values,
        literalTermSerializer: literalTermSerializer,
        iriTermSerializer: iriTermSerializer,
        resourceSerializer: resourceSerializer,
      ),
    );
    return this;
  }

  /// Adds a map of key-value pairs as child resources.
  ///
  /// This method is useful for serializing dictionary-like structures where both
  /// the keys and values need to be serialized as part of the RDF graph.
  /// Map entries can be serialized as literals, IRIs, or resources depending on
  /// the serializer provided.
  ///
  /// Examples:
  /// ```dart
  /// // Serializes a metadata dictionary as linked resources
  /// builder.addMap(
  ///   Schema.additionalProperty,
  ///   metadata,
  ///   resourceSerializer: MetadataEntrySerializer(),
  /// );
  ///
  /// // Serializes map entries as IRI terms
  /// builder.addMap(
  ///   Schema.sameAs,
  ///   uriMappings,
  ///   iriTermSerializer: UriMappingSerializer(),
  /// );
  ///
  /// // Serializes map entries as literal terms
  /// builder.addMap(
  ///   Schema.propertyValue,
  ///   keyValuePairs,
  ///   literalTermSerializer: KeyValueSerializer(),
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [instance]: The map to serialize.
  /// - [literalTermSerializer]: Optional serializer for map entries as literals.
  /// - [iriTermSerializer]: Optional serializer for map entries as IRIs.
  /// - [resourceSerializer]: Optional serializer for map entries as resources.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addMap<K, V>(
    RdfPredicate predicate,
    Map<K, V> instance, {
    LiteralTermSerializer<MapEntry<K, V>>? literalTermSerializer,
    IriTermSerializer<MapEntry<K, V>>? iriTermSerializer,
    ResourceSerializer<MapEntry<K, V>>? resourceSerializer,
  }) {
    _triples.addAll(
      _service.valueMap(_subject, predicate, instance,
          resourceSerializer: resourceSerializer,
          iriTermSerializer: iriTermSerializer,
          literalTermSerializer: literalTermSerializer),
    );
    return this;
  }

  /// Conditionally applies a transformation to this builder.
  ///
  /// Useful for complex conditional logic that doesn't fit the other conditional methods.
  /// This method allows applying a function to the builder only when a specified condition is true,
  /// making it powerful for creating conditional RDF structures.
  ///
  /// Example:
  /// ```dart
  /// builder.when(
  ///   person.isActive,
  ///   (b) => b.addValue(Schema.status, 'active')
  ///           .addValue(Foaf.member, organization)
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [condition]: The boolean condition to evaluate.
  /// - [action]: The function to apply to the builder when the condition is true.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> when(
    bool condition,
    void Function(ResourceBuilder<S> builder) action,
  ) {
    if (condition) {
      action(this);
    }
    return this;
  }

  /// Builds the resource and returns the subject and list of triples.
  ///
  /// This finalizes the RDF building process and returns both the subject resource
  /// and an unmodifiable list of all the triples that have been created.
  ///
  /// Example:
  /// ```dart
  /// final (person, triples) = builder
  ///   .addValue(Foaf.name, 'John Doe')
  ///   .build();
  /// ```
  ///
  /// Returns a tuple containing the subject and all generated triples.
  (S, List<Triple>) build() {
    return (_subject, List.unmodifiable(_triples));
  }
}

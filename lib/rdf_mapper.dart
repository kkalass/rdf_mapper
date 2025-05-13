/// RDF Mapping Library for Dart
///
/// This library provides a comprehensive solution for mapping between Dart objects and RDF (Resource Description Framework),
/// enabling seamless integration of semantic web technologies in Dart applications.
///
/// ## What is RDF?
///
/// RDF (Resource Description Framework) is a standard model for data interchange on the Web. It extends the linking
/// structure of the Web by using URIs to name relationships between things as well as the two ends of the link.
/// This simple model allows structured and semi-structured data to be mixed, exposed, and shared across different
/// applications.
///
/// RDF is built around three-part statements called "triples" in the form of subject-predicate-object:
/// - Subject: The resource being described (identified by an IRI or a blank node)
/// - Predicate: The property or relationship (always an IRI)
/// - Object: The value or related resource (an IRI, blank node, or literal value)
///
/// ## Library Overview
///
/// This library provides bidirectional mapping between Dart objects and RDF representations using a registry of mappers.
/// The API is organized into:
///
/// - **Primary API**: String-based operations for typical use cases, allowing serialization to and from RDF string formats
/// - **Graph API**: Direct graph manipulation for advanced scenarios, working with in-memory graph structures
/// - **Mapper System**: Extensible system of serializers and deserializers for custom types
///
/// ## Key Concepts
///
/// - **Terms vs Nodes**: The library distinguishes between RDF Terms (single values like IRIs or Literals) and
///   Nodes (subjects with their associated triples)
/// - **Mappers**: Combined serializers and deserializers for bidirectional conversion
/// - **Context**: Provides access to the current graph and related utilities during (de)serialization
///
/// ## Usage Example
///
/// ```dart
/// import 'package:rdf_mapper/rdf_mapper.dart';
///
/// // Create a mapper instance with default registry
/// final rdfMapper = RdfMapper.withDefaultRegistry();
///
/// // Register a custom mapper for your class
/// rdfMapper.registerMapper<Person>(PersonMapper());
///
/// // String-based serialization
/// final turtle = rdfMapper.serialize(myPerson);
///
/// // String-based deserialization
/// final person = rdfMapper.deserialize<Person>(turtle);
///
/// // Graph-based operations
/// final graph = rdfMapper.graph.serialize(myPerson);
/// final personFromGraph = rdfMapper.graph.deserialize<Person>(graph);
/// ```
///
library rdf_mapper;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/graph_operations.dart';
import 'package:rdf_mapper/src/api/mapper.dart';

import 'src/api/rdf_mapper_registry.dart';
import 'src/api/rdf_mapper_service.dart';

// Core API exports
export 'src/api/deserialization_context.dart';
export 'src/api/deserialization_service.dart';
export 'src/api/deserializer.dart';
export 'src/api/graph_operations.dart';
export 'src/api/mapper.dart';
export 'src/api/node_builder.dart';
export 'src/api/node_reader.dart';
export 'src/api/rdf_mapper_registry.dart';
export 'src/api/rdf_mapper_service.dart';
export 'src/api/serialization_context.dart';
export 'src/api/serialization_service.dart';
export 'src/api/serializer.dart';
export 'src/util/namespace.dart';
// Exception exports - essential for error handling
export 'src/exceptions/deserialization_exception.dart';
export 'src/exceptions/deserializer_not_found_exception.dart';
export 'src/exceptions/property_value_not_found_exception.dart';
export 'src/exceptions/rdf_mapping_exception.dart';
export 'src/exceptions/serialization_exception.dart';
export 'src/exceptions/serializer_not_found_exception.dart';
export 'src/exceptions/too_many_property_values_exception.dart';

// Standard mapper exports - useful as examples or for extension
export 'src/mappers/iri/extracting_iri_term_deserializer.dart';
export 'src/mappers/iri/iri_full_deserializer.dart';
export 'src/mappers/iri/iri_full_serializer.dart';
export 'src/mappers/iri/iri_id_serializer.dart';

// Base classes for literal mappers - essential for custom mapper implementation
export 'src/mappers/literal/base_rdf_literal_term_deserializer.dart';
export 'src/mappers/literal/base_rdf_literal_term_serializer.dart';

// Standard literal mappers - useful for reference and extension
export 'src/mappers/literal/bool_deserializer.dart';
export 'src/mappers/literal/bool_serializer.dart';
export 'src/mappers/literal/date_time_deserializer.dart';
export 'src/mappers/literal/date_time_serializer.dart';
export 'src/mappers/literal/double_deserializer.dart';
export 'src/mappers/literal/double_serializer.dart';
export 'src/mappers/literal/int_deserializer.dart';
export 'src/mappers/literal/int_serializer.dart';
export 'src/mappers/literal/string_deserializer.dart';
export 'src/mappers/literal/string_serializer.dart';

/// Central facade for the RDF Mapper library, providing access to object mapping and registry operations.
///
/// This class serves as the primary entry point for the RDF Mapper system, offering a simplified API
/// for mapping objects to and from RDF string representations, as well as access to graph operations
/// through the [graph] property.
///
/// The API is organized into two main categories:
/// - Primary API: String-based operations for typical use cases
/// - Graph API: Direct graph manipulation through the [graph] property for advanced scenarios
final class RdfMapper {
  final RdfMapperService _service;
  final RdfCore _rdfCore;
  final GraphOperations _graphOperations;

  /// Creates an RDF Mapper facade with custom components.
  ///
  /// Allows dependency injection of both the registry and RDF core components,
  /// enabling more flexible usage and better testability.
  ///
  /// @param registry The mapper registry to use for serialization/deserialization
  /// @param rdfCore Optional RDF core instance for string parsing/serialization
  RdfMapper({required RdfMapperRegistry registry, RdfCore? rdfCore})
    : _service = RdfMapperService(registry: registry),
      _rdfCore = rdfCore ?? RdfCore.withStandardCodecs(),
      _graphOperations = GraphOperations(RdfMapperService(registry: registry));

  /// Creates an RDF Mapper facade with a default registry and standard mappers.
  factory RdfMapper.withDefaultRegistry() =>
      RdfMapper(registry: RdfMapperRegistry());

  /// Access to the underlying registry for custom mapper registration.
  RdfMapperRegistry get registry => _service.registry;

  /// Access to graph-based operations.
  ///
  /// This property provides access to the graph operations API, which works directly
  /// with RDF graphs instead of string representations.
  GraphOperations get graph => _graphOperations;

  // ---- PRIMARY API: STRING-BASED OPERATIONS ----

  /// Deserializes an object of type [T] from an RDF string representation.
  ///
  /// This method parses the provided [rdfString] into an RDF graph using the specified
  /// [contentType], then deserializes it into an object of type [T] using registered mappers.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  ///
  /// [documentUrl] Optional base URI for resolving relative references in the document.
  ///
  /// The [register] callback allows temporary registration of custom mappers
  /// for this operation without affecting the global registry.
  ///
  /// Usage:
  /// ```dart
  /// // Register a mapper for the Person class
  /// rdfMapper.registerMapper<Person>(PersonMapper());
  ///
  /// final turtle = '''
  ///   @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  ///   <http://example.org/person/1> a foaf:Person ;
  ///     foaf:name "John Doe" ;
  ///     foaf:age 30 .
  /// ''';
  ///
  /// final person = rdfMapper.deserialize<Person>(turtle);
  /// ```
  T deserialize<T>(
    String rdfString, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.decode(
      rdfString,
      contentType: contentType,
      documentUrl: documentUrl,
    );
    return _graphOperations.deserialize<T>(graph, register: register);
  }

  /// Deserializes an object of type [T] from an RDF string, identified by the subject.
  ///
  /// This method is similar to [deserialize] but allows specifying a particular subject
  /// to deserialize when the RDF representation contains multiple subjects.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  ///
  /// [documentUrl] Optional base URI for resolving relative references in the document.
  T deserializeBySubject<T>(
    String rdfString,
    RdfSubject subject, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.decode(
      rdfString,
      contentType: contentType,
      documentUrl: documentUrl,
    );
    return _graphOperations.deserializeBySubject<T>(
      graph,
      subject,
      register: register,
    );
  }

  /// Deserializes all subjects from an RDF string into a list of objects.
  ///
  /// This method parses the RDF string and deserializes all subjects in the graph
  /// into objects using the registered mappers. The resulting list may contain
  /// objects of different types.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  ///
  /// [documentUrl] Optional base URI for resolving relative references in the document.
  ///
  /// Usage:
  /// ```dart
  /// // Register mappers for all relevant classes
  /// rdfMapper.registerMapper<Person>(PersonMapper());
  ///
  /// final turtle = '''
  ///   @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  ///   <http://example.org/person/1> a foaf:Person ;
  ///     foaf:name "John Doe" ;
  ///     foaf:age 30 .
  ///   <http://example.org/person/2> a foaf:Person ;
  ///     foaf:name "Jane Smith" ;
  ///     foaf:age 28 .
  /// ''';
  ///
  /// final people = rdfMapper.deserializeAll(turtle)
  ///   .whereType<Person>()
  ///   .toList();
  /// ```
  List<Object> deserializeAll(
    String rdfString, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.decode(
      rdfString,
      contentType: contentType,
      documentUrl: documentUrl,
    );
    return _graphOperations.deserializeAll(graph, register: register);
  }

  /// Deserializes all subjects of type [T] from an RDF string.
  ///
  /// This method is a type-safe variant of [deserializeAll] that filters
  /// the results to only include objects of the specified type.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  ///
  /// [documentUrl] Optional base URI for resolving relative references in the document.
  List<T> deserializeAllOfType<T>(
    String rdfString, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.decode(
      rdfString,
      contentType: contentType,
      documentUrl: documentUrl,
    );
    return _graphOperations.deserializeAllOfType<T>(graph, register: register);
  }

  /// Serializes a Dart object or collection to an RDF string representation.
  ///
  /// This method intelligently handles both single instances and collections:
  /// - For a single object, it creates a graph with that object's triples
  /// - For an Iterable of objects, it combines all objects into a single graph
  ///
  /// Parameters:
  /// - [instance]: The object or collection of objects to serialize
  /// - [contentType]: MIME type for output format (e.g., 'text/turtle', 'application/ld+json')
  ///   If omitted, defaults to 'text/turtle'
  /// - [baseUri]: Optional base URI for the RDF document, used for relative IRI resolution
  /// - [register]: Callback function to temporarily register additional mappers for this operation
  ///
  /// Returns a string containing the serialized RDF representation.
  ///
  /// Example with single instance:
  /// ```dart
  /// final person = Person(
  ///   id: 'http://example.org/person/1',
  ///   name: 'Alice',
  /// );
  ///
  /// final turtle = rdfMapper.serialize(person);
  /// ```
  ///
  /// Example with multiple instances:
  /// ```dart
  /// final people = [
  ///   Person(id: 'http://example.org/person/1', name: 'John Doe'),
  ///   Person(id: 'http://example.org/person/2', name: 'Jane Smith')
  /// ];
  ///
  /// final jsonLd = rdfMapper.serialize(
  ///   people,
  ///   contentType: 'application/ld+json',
  /// );
  /// ```
  ///
  /// Throws [SerializerNotFoundException] if no suitable mapper is registered for the instance type.
  String serialize<T>(
    T instance, {
    String? contentType,
    String? baseUri,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = this.graph.serialize<T>(instance, register: register);
    return _rdfCore.encode(graph, contentType: contentType, baseUri: baseUri);
  }

  /// Registers a mapper for bidirectional conversion between Dart objects and RDF.
  ///
  /// This method adds a [Mapper] implementation to the registry, enabling serialization
  /// and deserialization of objects of type [T]. The mapper determines how objects are
  /// converted to RDF triples and reconstructed from them.
  ///
  /// The registry supports four distinct mapper types based on RDF node characteristics:
  ///
  /// - [IriNodeMapper]: Maps objects to/from IRI subjects (identified by URIs)
  ///   Used for entity objects with identity and complex properties
  ///
  /// - [BlankNodeMapper]: Maps objects to/from blank node subjects
  ///   Used for embedded objects without their own identity
  ///
  /// - [LiteralTermMapper]: Maps objects to/from RDF literal terms
  ///   Used for value objects with datatype annotations
  ///
  /// - [IriTermMapper]: Maps objects to/from IRI reference terms
  ///   Used for object references and URIs
  ///
  /// Example with IriNodeMapper:
  /// ```dart
  /// class PersonMapper implements IriNodeMapper<Person> {
  ///   static final foaf = Namespace('http://xmlns.com/foaf/0.1/');
  ///   static final rdf = Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
  ///
  ///   @override
  ///   RdfIriNode toRdfNode(Person instance, SerializationContext context) {
  ///     return context.nodeBuilder(Uri.parse(instance.id))
  ///       .iri(rdf('type'), foaf('Person'))
  ///       .literal(foaf('name'), instance.name)
  ///       .build();
  ///   }
  ///
  ///   @override
  ///   Person fromRdfNode(RdfSubject subject, DeserializationContext context) {
  ///     return Person(
  ///       id: subject.iri.toString(),
  ///       name: context.reader.require<String>(foaf('name')),
  ///     );
  ///   }
  ///
  ///   @override
  ///   RdfIriReference typeIri() => foaf('Person');
  /// }
  ///
  /// // Register the mapper
  /// rdfMapper.registerMapper<Person>(PersonMapper());
  /// ```
  void registerMapper<T>(Mapper<T> mapper) {
    registry.registerMapper(mapper);
  }
}

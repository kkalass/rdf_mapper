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
/// - **Terms vs Resources**: The library distinguishes between RDF Terms (single values like IRIs or Literals) and
///   Resources (subjects with their associated triples)
/// - **Mappers**: Combined serializers and deserializers for bidirectional conversion
/// - **Context**: Provides access to the current graph and related utilities during (de)serialization
/// - **Datatype Strictness**: Enforces consistency between RDF datatypes and Dart types for semantic preservation
///
/// ## Datatype Handling
///
/// The library enforces strict datatype validation by default to ensure roundtrip consistency and prevent
/// data corruption. When encountering datatype mismatches, detailed exception messages provide multiple
/// resolution strategies:
///
/// - **Global Registration**: Register custom mappers for non-standard datatypes
/// - **Wrapper Types**: Create domain-specific types with custom datatypes using `DelegatingRdfLiteralTermMapper`
/// - **Local Overrides**: Use custom mappers for specific predicates only
/// - **Bypass Option**: Disable validation when flexible handling is required (use carefully)
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
/// // Handle custom datatypes with wrapper types
/// class Temperature {
///   final double celsius;
///   const Temperature(this.celsius);
/// }
///
/// class TemperatureMapper extends DelegatingRdfLiteralTermMapper<Temperature, double> {
///   static final celsiusType = IriTerm('http://qudt.org/vocab/unit/CEL');
///   const TemperatureMapper() : super(const DoubleMapper(), celsiusType);
///
///   @override
///   Temperature convertFrom(double value) => Temperature(value);
///   @override
///   double convertTo(Temperature value) => value.celsius;
/// }
///
/// rdfMapper.registerMapper<Temperature>(TemperatureMapper());
///
/// // String-based serialization
/// final turtle = rdfMapper.encodeObject(myPerson);
///
/// // String-based deserialization
/// final person = rdfMapper.decodeObject<Person>(turtle);
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
import 'package:rdf_mapper/src/codec/rdf_mapper_string_codec.dart';

import 'src/api/rdf_mapper_registry.dart';
import 'src/api/rdf_mapper_service.dart';

// Core API exports
export 'src/api/deserialization_context.dart';
export 'src/api/deserialization_service.dart';
export 'src/api/deserializer.dart';
export 'src/api/graph_operations.dart';
export 'src/api/mapper.dart';
export 'src/api/resource_builder.dart';
export 'src/api/resource_reader.dart';
export 'src/api/rdf_mapper_registry.dart';
export 'src/api/rdf_mapper_service.dart';
export 'src/api/serialization_context.dart';
export 'src/api/serialization_service.dart';
export 'src/api/serializer.dart';
export 'src/codec/rdf_mapper_codec.dart';
export 'src/codec/rdf_mapper_string_codec.dart';
// Exception exports - essential for error handling
export 'src/exceptions/codec_exceptions.dart';
export 'src/exceptions/deserialization_exception.dart';
export 'src/exceptions/deserializer_datatype_mismatch_exception.dart';
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
export 'src/mappers/iri/iri_full_mapper.dart';
export 'src/mappers/iri/iri_id_serializer.dart';
// Base classes for literal mappers - essential for custom mapper implementation
export 'src/mappers/literal/base_rdf_literal_term_deserializer.dart';
export 'src/mappers/literal/base_rdf_literal_term_serializer.dart';
// Standard literal mappers - useful for reference and extension
export 'src/mappers/literal/base_rdf_literal_term_mapper.dart';
export 'src/mappers/literal/bool_mapper.dart';
export 'src/mappers/literal/date_time_mapper.dart';
export 'src/mappers/literal/delegating_rdf_literal_term_mapper.dart';
export 'src/mappers/literal/double_mapper.dart';
export 'src/mappers/literal/int_mapper.dart';
export 'src/mappers/literal/string_mapper.dart';
export 'src/util/namespace.dart';

/// Central facade for the RDF Mapper library, providing access to object mapping and registry operations.
///
/// This class serves as the primary entry point for the RDF Mapper system, offering a simplified API
/// for mapping objects to and from RDF string representations, as well as access to graph operations
/// through the [graph] property.
///
/// The API is organized into two main categories:
/// - Primary API: String-based operations ([encodeObject], [decodeObject], [encodeObjects], [decodeObjects])
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
  /// [registry] The mapper registry to use for serialization/deserialization.
  /// [rdfCore] Optional RDF core instance for string parsing/serialization.
  RdfMapper({required RdfMapperRegistry registry, RdfCore? rdfCore})
      : _service = RdfMapperService(registry: registry),
        _rdfCore = rdfCore ?? RdfCore.withStandardCodecs(),
        _graphOperations =
            GraphOperations(RdfMapperService(registry: registry));

  /// Creates an RDF Mapper facade with a default registry and standard mappers.
  ///
  /// Returns a new RdfMapper instance initialized with a default registry.
  /// This is the simplest way to create an instance for general use.
  factory RdfMapper.withDefaultRegistry() =>
      RdfMapper(registry: RdfMapperRegistry());

  /// Creates an RDF Mapper facade with a custom-configured registry.
  ///
  /// This factory allows you to pass a callback function that configures
  /// the registry with custom mappers or serializers.
  ///
  /// [register] A callback function that receives the newly created registry
  ///   and can register custom mappers on it.
  ///
  /// Example:
  /// ```dart
  /// final mapper = RdfMapper.withMappers((registry) {
  ///   registry.registerMapper<Person>(PersonMapper());
  ///   registry.registerMapper<Book>(BookMapper());
  /// });
  /// ```
  factory RdfMapper.withMappers(
    void Function(RdfMapperRegistry registry) register,
  ) {
    final registry = RdfMapperRegistry();
    register(registry);
    return RdfMapper(registry: registry);
  }

  /// Access to the underlying registry for custom mapper registration.
  RdfMapperRegistry get registry => _service.registry;

  /// Access to graph-based operations.
  ///
  /// This property provides access to the graph operations API, which works directly
  /// with RDF graphs instead of string representations.
  GraphOperations get graph => _graphOperations;

  // ---- PRIMARY API: STRING-BASED OPERATIONS ----

  /// Returns a codec for converting between objects of type [T] and RDF strings.
  ///
  /// The returned codec handles the entire conversion pipeline while preserving
  /// all important options:
  /// - For encoding: Object → RDF Graph → String
  /// - For decoding: String → RDF Graph → Object
  ///
  /// This provides a functional-style API that can be composed with other converters
  /// when needed.
  ///
  /// Note that you either need to register a [GlobalResourceMapper] for the type [T]
  /// globally before using this codec or pass a [register] function to the codec
  /// which registers this mapper (and any further custom ones, if applicable).
  ///
  ///
  /// Example:
  /// ```dart
  /// final codec = rdfMapper.objectCodec<Person>();
  /// final turtle = codec.encode(person, baseUri: 'http://example.org/');
  /// final person2 = codec.decode(turtle, documentUrl: 'http://example.org/');
  /// ```
  ///
  /// Parameters:
  /// * [contentType] - Specifies the RDF format (e.g., 'text/turtle', 'application/ld+json').
  ///   If not specified, defaults to the format that was registered first in the RdfCodecRegistry - usually 'text/turtle'.
  /// * [register] - Allows temporary registration of custom mappers for this codec.
  /// * [stringDecoderOptions] - Additional options for string decoding.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  RdfObjectStringCodec<T> objectCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
  }) {
    return RdfObjectStringCodec<T>(
      objectCodec: _graphOperations.objectCodec<T>(register: register),
      graphCodec: _rdfCore.codec(
        contentType: contentType,
        encoderOptions: stringEncoderOptions,
        decoderOptions: stringDecoderOptions,
      ),
    );
  }

  /// Returns a codec for handling collections of type [T] and RDF strings.
  ///
  /// The returned codec handles the entire conversion pipeline while preserving
  /// all important options:
  /// - For encoding: Iterable<Object> → RDF Graph → String
  /// - For decoding: String → RDF Graph → Iterable<Object>
  ///
  /// This codec is specifically designed for working with collections of objects,
  /// allowing efficient batch processing of multiple entities in a single operation.
  ///
  /// Note that it is perfectly fine to use [Object] for [T] here, the actual type
  /// will be inferred from the input. The decoder will rely on
  /// `rdf:type` to find the correct mapper for each object.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Parameters:
  /// * [contentType] - Specifies the RDF format (e.g., 'text/turtle', 'application/ld+json').
  ///   If not specified, defaults to the format registered first in the RdfCodecRegistry.
  /// * [register] - Allows temporary registration of custom mappers for this codec.
  /// * [stringDecoderOptions] - Additional options for string decoding.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  RdfObjectsStringCodec<T> objectsCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
  }) {
    return RdfObjectsStringCodec<T>(
      objectsCodec: _graphOperations.objectsCodec<T>(register: register),
      graphCodec: _rdfCore.codec(
        contentType: contentType,
        encoderOptions: stringEncoderOptions,
        decoderOptions: stringDecoderOptions,
      ),
    );
  }

  /// Deserializes an object of type [T] from an RDF string representation.
  ///
  /// This method parses the provided [rdfString] into an RDF graph using the specified
  /// [contentType], then deserializes it into an object of type [T] using registered mappers.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// Parameters:
  /// * [rdfString] - The RDF string representation to deserialize.
  /// * [subject] - Optional specific subject to deserialize from the graph.
  /// * [contentType] - MIME type like 'text/turtle' or 'application/ld+json'.
  ///   If not specified, the contentType will be auto-detected.
  /// * [documentUrl] - Optional base URI for resolving relative references in the document.
  /// * [register] - Callback function to temporarily register custom mappers.
  /// * [stringDecoderOptions] - Additional options for string decoding.
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
  /// final person = rdfMapper.decodeObject<Person>(turtle);
  /// ```
  T decodeObject<T>(
    String rdfString, {
    RdfSubject? subject,
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
  }) {
    return objectCodec<T>(
      contentType: contentType,
      register: register,
      stringDecoderOptions: stringDecoderOptions,
    ).decode(rdfString, documentUrl: documentUrl, subject: subject);
  }

  /// Deserializes all subjects from an RDF string into a list of objects.
  ///
  /// This method parses the RDF string and deserializes all subjects in the graph
  /// into objects using the registered mappers. The resulting list contains
  /// only objects of type [T].
  ///
  /// Note that it is perfectly fine to use [Object] for [T] here, the actual type
  /// will be inferred from the input. The decoder will rely on
  /// `rdf:type` to find the correct mapper for each object.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// [rdfString] The RDF string representation to deserialize.
  /// [contentType] MIME type like 'text/turtle' or 'application/ld+json'.
  /// Parameters:
  /// * [rdfString] - The RDF string representation to deserialize.
  /// * [contentType] - MIME type like 'text/turtle' or 'application/ld+json'.
  ///   If not specified, the contentType will be auto-detected.
  /// * [documentUrl] - Optional base URI for resolving relative references in the document.
  /// * [register] - Callback function to temporarily register custom mappers.
  /// * [stringDecoderOptions] - Additional options for string decoding.
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
  /// final people = rdfMapper.decodeObjects<Person>(turtle);
  /// ```
  List<T> decodeObjects<T>(
    String rdfString, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
  }) {
    return objectsCodec<T>(
      contentType: contentType,
      register: register,
      stringDecoderOptions: stringDecoderOptions,
    ).decode(rdfString, documentUrl: documentUrl).toList();
  }

  /// Serializes a Dart object or collection to an RDF string representation.
  ///
  /// This method intelligently handles both single instances and collections:
  /// - For a single object, it creates a graph with that object's triples
  /// - For an Iterable of objects, it combines all objects into a single graph
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly serialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// Parameters:
  /// * [instance] - The object to serialize.
  /// * [contentType] - MIME type for output format (e.g., 'text/turtle', 'application/ld+json').
  ///   If omitted, defaults to 'text/turtle'.
  /// * [baseUri] - Optional base URI for the RDF document, used for relative IRI resolution.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  /// * [register] - Callback function to temporarily register additional mappers for this operation.
  ///
  /// Returns a string containing the serialized RDF representation.
  ///
  /// Example:
  /// ```dart
  /// final person = Person(
  ///   id: 'http://example.org/person/1',
  ///   name: 'Alice',
  /// );
  ///
  /// final turtle = rdfMapper.encodeObject(person);
  /// ```
  ///
  /// Throws [SerializerNotFoundException] if no suitable mapper is registered for the instance type.
  String encodeObject<T>(
    T instance, {
    String? contentType,
    String? baseUri,
    RdfGraphEncoderOptions? stringEncoderOptions,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Use the codec approach with the appropriate type
    return objectCodec<T>(
      contentType: contentType,
      stringEncoderOptions: stringEncoderOptions,
      register: register,
    ).encode(instance, baseUri: baseUri);
  }

  /// Serializes a collection of Dart objects to an RDF string representation.
  ///
  /// This method is similar to [encodeObject] but optimized for collections of objects.
  /// It combines all objects into a single RDF graph before serializing to a string.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback.
  ///
  /// Parameters:
  /// * [instance] - The collection of objects to serialize.
  /// * [contentType] - MIME type for output format (e.g., 'text/turtle', 'application/ld+json').
  ///   If omitted, defaults to 'text/turtle'.
  /// * [baseUri] - Optional base URI for the RDF document, used for relative IRI resolution.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  /// * [register] - Callback function to temporarily register additional mappers for this operation.
  ///
  /// Returns a string containing the serialized RDF representation of all objects.
  ///
  /// Example:
  /// ```dart
  /// final people = [
  ///   Person(id: 'http://example.org/person/1', name: 'John Doe'),
  ///   Person(id: 'http://example.org/person/2', name: 'Jane Smith')
  /// ];
  ///
  /// final jsonLd = rdfMapper.encodeObjects(
  ///   people,
  ///   contentType: 'application/ld+json',
  /// );
  /// ```
  ///
  /// Throws [SerializerNotFoundException] if no suitable mapper is registered for the instance type.
  String encodeObjects<T>(
    Iterable<T> instance, {
    String? contentType,
    String? baseUri,
    RdfGraphEncoderOptions? stringEncoderOptions,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Use the codec approach with the appropriate type
    return objectsCodec<T>(
      contentType: contentType,
      stringEncoderOptions: stringEncoderOptions,
      register: register,
    ).encode(instance, baseUri: baseUri);
  }

  /// Registers a mapper for bidirectional conversion between Dart objects and RDF.
  ///
  /// This method adds a [Mapper] implementation to the registry, enabling serialization
  /// and deserialization of objects of type [T]. The mapper determines how objects are
  /// converted to RDF triples and reconstructed from them.
  ///
  /// The registry supports four distinct mapper types based on RDF node characteristics:
  ///
  /// - [GlobalResourceMapper]: Maps objects to/from IRI subjects (identified by URIs)
  ///   Used for entity objects with identity and complex properties
  ///
  /// - [LocalResourceMapper]: Maps objects to/from blank node subjects
  ///   Used for embedded objects without their own identity
  ///
  /// - [LiteralTermMapper]: Maps objects to/from RDF literal terms
  ///   Used for value objects with datatype annotations
  ///
  /// - [IriTermMapper]: Maps objects to/from IRI reference terms
  ///   Used for object references and URIs
  ///
  /// Example with GlobalResourceMapper:
  /// ```dart
  /// class PersonMapper implements GlobalResourceMapper<Person> {
  ///
  ///   @override
  ///   (IriTerm, List<Triple>) toRdfResource(Person instance, SerializationContext context, {RdfSubject? parentSubject}) {
  ///     return context.resourceBuilder(IriTerm(instance.id))
  ///       .addValue(FoafPerson.name, instance.name)
  ///       .build();
  ///   }
  ///
  ///   @override
  ///   Person fromRdfResource(IriTerm subject, DeserializationContext context) {
  ///     return Person(
  ///       // you can of course also parse the iri to extract the actual id
  ///       // and then create the full IRI from the id in toRdfResource
  ///       id: subject.iri,
  ///       name: context.reader.require<String>(FoafPerson.name),
  ///     );
  ///   }
  ///
  ///   @override
  ///   IriTerm get typeIri => FoafPerson.classIri;
  /// }
  ///
  /// // Register the mapper
  /// rdfMapper.registerMapper<Person>(PersonMapper());
  /// ```
  void registerMapper<T>(Mapper<T> mapper) {
    registry.registerMapper(mapper);
  }
}

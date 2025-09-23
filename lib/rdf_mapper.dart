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
///   static final celsiusType = const IriTerm('http://qudt.org/vocab/unit/CEL');
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
///
/// // Working with relative IRIs for compact representation
/// const baseUri = 'http://docs.example.org/';
/// const relativeMapper = IriRelativeMapper(baseUri);
/// final relativeIri = relativeMapper.toRdfTerm('chapter1.html', context);
/// // Creates: const IriTerm('http://docs.example.org/chapter1.html')
/// ```
///
library rdf_mapper;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/completeness_mode.dart';
import 'package:rdf_mapper/src/api/graph_operations.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/codec/rdf_mapper_string_codec.dart';

import 'src/api/rdf_mapper_registry.dart';
import 'src/api/rdf_mapper_service.dart';

// Core API exports
export 'src/api/completeness_mode.dart';
export 'src/api/deserialization_context.dart';
export 'src/api/deserialization_service.dart';
export 'src/api/graph_operations.dart';
export 'src/api/resource_builder.dart';
export 'src/api/resource_reader.dart';
export 'src/api/rdf_mapper_registry.dart';
export 'src/api/rdf_mapper_service.dart';
export 'src/api/serialization_context.dart';
export 'src/api/serialization_provider.dart';
export 'src/api/serialization_service.dart';
export 'src/api/rdf_mapper_interfaces.dart';
export 'src/codec/rdf_mapper_codec.dart';
export 'src/codec/rdf_mapper_string_codec.dart';
// Exception exports - essential for error handling
export 'src/exceptions/codec_exceptions.dart';
export 'src/exceptions/deserialization_exception.dart';
export 'src/exceptions/deserializer_datatype_mismatch_exception.dart';
export 'src/exceptions/deserializer_not_found_exception.dart';
export 'src/exceptions/incomplete_deserialization_exception.dart';
export 'src/exceptions/invalid_rdf_list_structure_exception.dart';
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
export 'src/mappers/iri/iri_relative_deserializer.dart';
export 'src/mappers/iri/iri_relative_serializer.dart';
export 'src/mappers/iri/iri_relative_mapper.dart';
export 'src/mappers/iri/iri_relative_serialization_provider.dart';
export 'src/mappers/iri/base_rdf_iri_term_mapper.dart';
export 'src/mappers/iri/convenience_iri_mappers.dart';
// Base classes for literal mappers - essential for custom mapper implementation
export 'src/mappers/literal/base_rdf_literal_term_deserializer.dart';
export 'src/mappers/literal/base_rdf_literal_term_serializer.dart';
export 'src/mappers/literal/language_override_mapper.dart';
export 'src/mappers/literal/datatype_override_mapper.dart';
// Standard literal mappers - useful for reference and extension
export 'src/mappers/literal/base_rdf_literal_term_mapper.dart';
export 'src/mappers/literal/bool_mapper.dart';
export 'src/mappers/literal/date_mapper.dart';
export 'src/mappers/literal/date_time_mapper.dart';
export 'src/mappers/literal/delegating_rdf_literal_term_mapper.dart';
export 'src/mappers/literal/double_mapper.dart';
export 'src/mappers/literal/int_mapper.dart';
export 'src/mappers/literal/string_mapper.dart';
export 'src/mappers/resource/rdf_graph_mapper.dart';
export 'src/mappers/resource/rdf_container_mapper.dart';
export 'src/mappers/resource/rdf_container_deserializer.dart';
export 'src/mappers/resource/rdf_container_serializer.dart';
export 'src/mappers/resource/rdf_list_mapper.dart';
export 'src/mappers/resource/rdf_list_deserializer.dart';
export 'src/mappers/resource/rdf_list_serializer.dart';
export 'src/mappers/unmapped/predicates_map_mapper.dart';
export 'src/mappers/multi/unordered_items_mapper.dart';
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
  RdfMapper(
      {required RdfMapperRegistry registry,
      RdfCore? rdfCore,
      IriTermFactory iriTermFactory = IriTerm.validated})
      : _service = RdfMapperService(
            registry: registry, iriTermFactory: iriTermFactory),
        _rdfCore = rdfCore ??
            RdfCore.withStandardCodecs(iriTermFactory: iriTermFactory),
        _graphOperations = GraphOperations(RdfMapperService(
            registry: registry, iriTermFactory: iriTermFactory));

  /// Creates an RDF Mapper facade with a default registry and standard mappers.
  ///
  /// Returns a new RdfMapper instance initialized with a default registry.
  /// This is the simplest way to create an instance for general use.
  factory RdfMapper.withDefaultRegistry(
          {IriTermFactory iriTermFactory = IriTerm.validated}) =>
      RdfMapper(registry: RdfMapperRegistry(), iriTermFactory: iriTermFactory);

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
      {IriTermFactory iriTermFactory = IriTerm.validated}) {
    final registry = RdfMapperRegistry();
    register(registry);
    return RdfMapper(registry: registry, iriTermFactory: iriTermFactory);
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
  /// * [completeness] - Controls how incomplete deserialization is handled during decoding:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
  RdfObjectStringCodec<T> objectCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    return RdfObjectStringCodec<T>(
      objectCodec: _graphOperations.objectCodec<T>(
          register: register, completeness: completeness),
      graphCodec: _rdfCore.codec(
        contentType: contentType,
        encoderOptions: stringEncoderOptions,
        decoderOptions: stringDecoderOptions,
      ),
    );
  }

  /// Returns a lossless codec for converting between objects of type [T] and RDF strings with complete data preservation.
  ///
  /// The returned codec handles bidirectional conversion while preserving all RDF data:
  /// - For encoding: (Object, RdfGraph) → Combined RDF Graph → String
  /// - For decoding: String → RDF Graph → (Object, Remainder RdfGraph)
  ///
  /// This codec is essential for lossless mapping workflows where no RDF data should be lost
  /// during round-trip operations. It works with records containing both the target object
  /// and an RdfGraph with unmapped/remainder triples.
  ///
  /// The codec ensures perfect round-trip fidelity by:
  /// - Capturing all triples not mapped to object properties during decoding
  /// - Restoring all original triples (both mapped and unmapped) during encoding
  /// - Preserving blank node structures and complex RDF patterns
  ///
  /// Note that you either need to register a [GlobalResourceMapper] for the type [T]
  /// globally before using this codec or pass a [register] function to the codec
  /// which registers this mapper (and any further custom ones, if applicable).
  ///
  /// Example:
  /// ```dart
  /// final codec = rdfMapper.objectLosslessCodec<Person>();
  ///
  /// // Decode with complete data preservation
  /// final (person, remainder) = codec.decode(turtle, documentUrl: 'http://example.org/');
  ///
  /// // Modify the object as needed
  /// final updatedPerson = person.copyWith(age: person.age + 1);
  ///
  /// // Encode back with all original data preserved
  /// final restoredTurtle = codec.encode((updatedPerson, remainder), baseUri: 'http://example.org/');
  /// ```
  ///
  /// Parameters:
  /// * [contentType] - Specifies the RDF format (e.g., 'text/turtle', 'application/ld+json').
  ///   If not specified, defaults to the format that was registered first in the RdfCodecRegistry - usually 'text/turtle'.
  /// * [register] - Allows temporary registration of custom mappers for this codec.
  /// * [stringDecoderOptions] - Additional options for string decoding.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  RdfObjectLosslessStringCodec<T> objectLosslessCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
  }) {
    return RdfObjectLosslessStringCodec<T>(
      objectCodec: _graphOperations.objectLosslessCodec<T>(register: register),
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
  /// * [completeness] - Controls how incomplete deserialization is handled during decoding:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
  RdfObjectsStringCodec<T> objectsCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    return RdfObjectsStringCodec<T>(
      objectsCodec: _graphOperations.objectsCodec<T>(
          register: register, completeness: completeness),
      graphCodec: _rdfCore.codec(
        contentType: contentType,
        encoderOptions: stringEncoderOptions,
        decoderOptions: stringDecoderOptions,
      ),
    );
  }

  /// Returns a lossless codec for converting between collections of type [T] and RDF strings with complete data preservation.
  ///
  /// The returned codec handles bidirectional conversion for collections while preserving all RDF data:
  /// - For encoding: (Iterable<Object>, RdfGraph) → Combined RDF Graph → String
  /// - For decoding: String → RDF Graph → (Iterable<Object>, Remainder RdfGraph)
  ///
  /// This codec is designed for lossless processing of entire RDF documents containing multiple
  /// objects while ensuring no data loss during conversion. It works with records containing
  /// both the target object collection and an RdfGraph with unmapped/remainder triples.
  ///
  /// The codec provides complete round-trip fidelity for complex documents by:
  /// - Capturing all triples not mapped to any object properties during decoding
  /// - Restoring all original document triples (both mapped and unmapped) during encoding
  /// - Handling mixed object types and preserving unknown RDF structures
  ///
  /// Note that it is perfectly fine to use [Object] for [T] here, the actual type
  /// will be inferred from the input. The decoder will rely on
  /// `rdf:type` to find the correct mapper for each object.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Example:
  /// ```dart
  /// final codec = rdfMapper.objectsLosslessCodec<Person>();
  ///
  /// // Decode entire document with complete data preservation
  /// final (people, remainder) = codec.decode(turtle, documentUrl: 'http://example.org/');
  ///
  /// // Process the objects as needed
  /// final updatedPeople = people.map((p) => p.copyWith(age: p.age + 1)).toList();
  ///
  /// // Encode back with all original document data preserved
  /// final restoredTurtle = codec.encode((updatedPeople, remainder), baseUri: 'http://example.org/');
  /// ```
  ///
  /// Parameters:
  /// * [contentType] - Specifies the RDF format (e.g., 'text/turtle', 'application/ld+json').
  ///   If not specified, defaults to the format registered first in the RdfCodecRegistry.
  /// * [register] - Allows temporary registration of custom mappers for this codec.
  /// * [stringDecoderOptions] - Additional options for string decoding.
  /// * [stringEncoderOptions] - Additional options for string encoding.
  RdfObjectsLosslessStringCodec<T> objectsLosslessCodec<T>({
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
    RdfGraphEncoderOptions? stringEncoderOptions,
  }) {
    return RdfObjectsLosslessStringCodec<T>(
      objectsCodec:
          _graphOperations.objectsLosslessCodec<T>(register: register),
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
  /// * [completeness] - Controls how incomplete deserialization is handled:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
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
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    return objectCodec<T>(
      contentType: contentType,
      register: register,
      stringDecoderOptions: stringDecoderOptions,
      completeness: completeness,
    ).decode(rdfString, documentUrl: documentUrl, subject: subject);
  }

  /// Deserializes a single object from an RDF string with lossless data preservation.
  ///
  /// This method provides lossless deserialization by returning both the deserialized
  /// object and any RDF triples that were not part of the object's mapping. This ensures
  /// complete data preservation and enables perfect round-trip operations.
  ///
  /// The method returns a record `(T object, RdfGraph remainderGraph)` where:
  /// - `object` contains all explicitly mapped properties
  /// - `remainderGraph` contains all triples not consumed during object deserialization
  ///
  /// If your object's mapper uses [ResourceReader.getUnmapped], the object itself
  /// may also contain unmapped triples that were directly associated with its subject.
  ///
  /// Usage example:
  /// ```dart
  /// final (person, remainder) = rdfMapper.decodeObjectLossless<Person>(turtle);
  ///
  /// // Use the object normally
  /// print('Person: ${person.name}');
  ///
  /// // Inspect or preserve the remainder for later use
  /// print('Preserved ${remainder.triples.length} unmapped triples');
  ///
  /// // Perfect round-trip is possible
  /// final restored = rdfMapper.encodeObjectLossless((person, remainder));
  /// ```
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback.
  ///
  /// Parameters:
  /// * [rdfString] - The RDF string to deserialize
  /// * [subject] - Optional specific subject to deserialize (if null, finds suitable subject)
  /// * [contentType] - MIME type of the RDF format (defaults to 'text/turtle')
  /// * [documentUrl] - Optional base URL for relative IRI resolution
  /// * [register] - Optional callback to register mappers for this operation
  /// * [stringDecoderOptions] - Optional decoder configuration
  ///
  /// Returns a record containing the deserialized object and remainder graph.
  ///
  /// Throws [DeserializerNotFoundException] if no suitable mapper is registered for the target type.
  (T, RdfGraph) decodeObjectLossless<T>(
    String rdfString, {
    RdfSubject? subject,
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
  }) {
    return objectLosslessCodec<T>(
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
  /// * [completenessMode] - Controls how incomplete deserialization is handled:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
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
    CompletenessMode completenessMode = CompletenessMode.strict,
  }) {
    return objectsCodec<T>(
      contentType: contentType,
      register: register,
      stringDecoderOptions: stringDecoderOptions,
      completeness: completenessMode,
    ).decode(rdfString, documentUrl: documentUrl).toList();
  }

  /// Deserializes multiple objects from an RDF string with lossless data preservation.
  ///
  /// This method provides lossless deserialization of collections by returning both
  /// the deserialized objects and any RDF triples that were not part of any object's
  /// mapping. This ensures complete data preservation for entire RDF documents.
  ///
  /// The method returns a record `(List<T> objects, RdfGraph remainderGraph)` where:
  /// - `objects` contains all successfully deserialized objects of type [T]
  /// - `remainderGraph` contains all triples not consumed during any object deserialization
  ///
  /// Usage example:
  /// ```dart
  /// final (people, remainder) = rdfMapper.decodeObjectsLossless<Person>(turtle);
  ///
  /// // Process the deserialized objects
  /// for (final person in people) {
  ///   print('Person: ${person.name}');
  /// }
  ///
  /// // Handle any unprocessed triples
  /// if (remainder.triples.isNotEmpty) {
  ///   print('Document contained ${remainder.triples.length} unmapped triples');
  /// }
  ///
  /// // Perfect round-trip is possible
  /// final restored = rdfMapper.encodeObjectsLossless((people, remainder));
  /// ```
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback. Use [Object] as the type parameter to deserialize
  /// mixed object types.
  ///
  /// Parameters:
  /// * [rdfString] - The RDF string to deserialize
  /// * [contentType] - MIME type of the RDF format (defaults to 'text/turtle')
  /// * [documentUrl] - Optional base URL for relative IRI resolution
  /// * [register] - Optional callback to register mappers for this operation
  /// * [stringDecoderOptions] - Optional decoder configuration
  ///
  /// Returns a record containing the list of deserialized objects and remainder graph.
  ///
  /// Throws [DeserializerNotFoundException] if no suitable mapper is registered for the target type.
  (List<T>, RdfGraph) decodeObjectsLossless<T>(
    String rdfString, {
    String? contentType,
    String? documentUrl,
    void Function(RdfMapperRegistry registry)? register,
    RdfGraphDecoderOptions? stringDecoderOptions,
  }) {
    final r = objectsLosslessCodec<T>(
      contentType: contentType,
      register: register,
      stringDecoderOptions: stringDecoderOptions,
    ).decode(rdfString, documentUrl: documentUrl);
    return (r.$1.toList(), r.$2);
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
  /// * [contentType] - MIME type for output format (e.g., 'text/turtle', 'application/ld+json', 'application/n-triples').
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

  /// Serializes a Dart object with remainder graph to an RDF string with lossless preservation.
  ///
  /// This method enables lossless round-trip operations by combining a serialized object
  /// with previously captured unmapped RDF data. The [instance] parameter should be a
  /// record containing both the object to serialize and an [RdfGraph] with remainder triples.
  ///
  /// This is the counterpart to [decodeObjectLossless], allowing perfect restoration
  /// of original RDF documents that contained data not explicitly mapped to object properties.
  ///
  /// Usage example:
  /// ```dart
  /// // During deserialization, capture unmapped data
  /// final (person, remainder) = rdfMapper.decodeObjectLossless<Person>(originalTurtle);
  ///
  /// // Modify the object as needed
  /// final updatedPerson = person.copyWith(age: person.age + 1);
  ///
  /// // Restore to RDF with all original data preserved
  /// final restoredTurtle = rdfMapper.encodeObjectLossless((updatedPerson, remainder));
  ///
  /// // restoredTurtle now contains both the updated object AND all unmapped triples
  /// ```
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback.
  ///
  /// Parameters:
  /// * [instance] - A record containing the object to serialize and remainder graph
  /// * [contentType] - MIME type for output format (defaults to 'text/turtle')
  /// * [baseUri] - Optional base URI for the RDF document
  /// * [stringEncoderOptions] - Optional encoder configuration
  /// * [register] - Optional callback to register mappers for this operation
  ///
  /// Returns the complete RDF string representation with both object and remainder data.
  ///
  /// Throws [SerializerNotFoundException] if no suitable mapper is registered for the object type.
  String encodeObjectLossless<T>(
    (T, RdfGraph) instance, {
    String? contentType,
    String? baseUri,
    RdfGraphEncoderOptions? stringEncoderOptions,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Use the codec approach with the appropriate type
    return objectLosslessCodec<T>(
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

  /// Serializes a collection of Dart objects with remainder graph to an RDF string with lossless preservation.
  ///
  /// This method enables lossless round-trip operations for collections by combining serialized
  /// objects with previously captured unmapped RDF data. The [instance] parameter should be a
  /// record containing both the collection of objects to serialize and an [RdfGraph] with remainder triples.
  ///
  /// This is the counterpart to [decodeObjectsLossless], allowing perfect restoration
  /// of original RDF documents containing multiple objects plus unmapped data.
  ///
  /// Usage example:
  /// ```dart
  /// // During deserialization, capture unmapped data
  /// final (people, remainder) = rdfMapper.decodeObjectsLossless<Person>(originalTurtle);
  ///
  /// // Process the collection as needed
  /// final updatedPeople = people.map((p) => p.copyWith(age: p.age + 1)).toList();
  ///
  /// // Restore to RDF with all original data preserved
  /// final restoredTurtle = rdfMapper.encodeObjectsLossless((updatedPeople, remainder));
  ///
  /// // restoredTurtle contains all objects AND all unmapped triples from the original
  /// ```
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback.
  ///
  /// Parameters:
  /// * [instance] - A record containing the objects collection and remainder graph
  /// * [contentType] - MIME type for output format (defaults to 'text/turtle')
  /// * [baseUri] - Optional base URI for the RDF document
  /// * [stringEncoderOptions] - Optional encoder configuration
  /// * [register] - Optional callback to register mappers for this operation
  ///
  /// Returns the complete RDF string representation with both objects and remainder data.
  ///
  /// Throws [SerializerNotFoundException] if no suitable mapper is registered for the object type.
  String encodeObjectsLossless<T>(
    (Iterable<T>, RdfGraph) instance, {
    String? contentType,
    String? baseUri,
    RdfGraphEncoderOptions? stringEncoderOptions,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Use the codec approach with the appropriate type
    return objectsLosslessCodec<T>(
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
  /// The registry supports five distinct mapper types based on RDF node characteristics:
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
  /// - [UnmappedTriplesMapper]: Maps objects to/from collections of unmapped RDF triples
  ///   Used for lossless mapping scenarios where unmapped data needs to be preserved
  ///
  /// **Note about UnmappedTriplesMapper:**
  /// Registering an [UnmappedTriplesMapper] only enables the type for unmapped triples
  /// handling through [ResourceReader.getUnmapped] and [ResourceBuilder.addUnmapped].
  /// To use the type as a resource (e.g., as a property value), you must register
  /// separate GlobalResourceMapper and LocalResourceMapper implementations.
  ///
  /// For RdfGraph, the library provides RdfGraphGlobalResourceMapper and
  /// RdfGraphLocalResourceMapper, but these require a clear single root subject
  /// for serialization to work correctly.
  ///
  /// Example with GlobalResourceMapper:
  /// ```dart
  /// class PersonMapper implements GlobalResourceMapper<Person> {
  ///
  ///   @override
  ///   (IriTerm, Iterable<Triple>) toRdfResource(Person instance, SerializationContext context, {RdfSubject? parentSubject}) {
  ///     return context.resourceBuilder(const IriTerm(instance.id))
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
  ///
  /// Example with UnmappedTriplesMapper:
  /// ```dart
  /// class MyCustomGraphMapper implements UnmappedTriplesMapper<MyCustomGraph> {
  ///   @override
  ///   MyCustomGraph fromUnmappedTriples(Iterable<Triple> triples) {
  ///     return MyCustomGraph(triples.toSet());
  ///   }
  ///
  ///   @override
  ///   Iterable<Triple> toUnmappedTriples(MyCustomGraph value) {
  ///     return value.triples;
  ///   }
  /// }
  ///
  /// // Register the unmapped triples mapper
  /// rdfMapper.registerMapper<MyCustomGraph>(MyCustomGraphMapper());
  ///
  /// // Now MyCustomGraph is automatically available for:
  /// // 1. getUnmapped<MyCustomGraph>() in ResourceReader
  /// // 2. addUnmapped(myGraph) in ResourceBuilder
  /// // 3. As a regular property type in other mappers:
  /// //    reader.require<MyCustomGraph>(someProperty)
  /// ```
  void registerMapper<T>(BaseMapper<T> mapper) {
    registry.registerMapper(mapper);
  }
}

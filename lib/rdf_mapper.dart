/// RDF ORM Facade Library for Dart
///
/// This library provides a simplified and unified entry point for RDF object-relational mapping (ORM)
/// operations, exposing the core API of the rdf_orm subsystem for convenient and idiomatic use.
///
/// It is inspired by the structure and philosophy of the rdf.dart facade, but is tailored to the ORM domain.
///
/// ## Usage Example
///
/// ```dart
/// import 'package:rdf_mapper/rdf_mapper.dart';
///
/// final rdfmapper = RdfMapper.withDefaultRegistry();
///
/// // String-based operations
/// final turtle = rdfmapper.serialize(myObject);
/// final obj = rdfmapper.deserialize<MyType>(turtle);
///
/// // Graph-based operations
/// final graph = rdfmapper.graph.serialize(myObject);
/// final objFromGraph = rdfmapper.graph.deserialize<MyType>(graph);
/// ```
///
library rdf_mapper;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/graph_operations.dart';
import 'package:rdf_mapper/src/api/mapper.dart';

import 'src/api/rdf_mapper_registry.dart';
import 'src/api/rdf_mapper_service.dart';

export 'src/api/deserialization_context.dart';
export 'src/api/graph_operations.dart';
export 'src/api/rdf_mapper_registry.dart';
export 'src/api/rdf_mapper_service.dart';
export 'src/api/serialization_context.dart';

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
      _rdfCore = rdfCore ?? RdfCore.withStandardFormats(),
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
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return _graphOperations.deserialize<T>(graph, register: register);
  }

  /// Deserializes an object of type [T] from an RDF string, identified by the subject.
  ///
  /// This method is similar to [deserialize] but allows specifying a particular subject
  /// to deserialize when the RDF representation contains multiple subjects.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  T deserializeBySubject<T>(
    String rdfString,
    RdfSubject subjectId, {
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return _graphOperations.deserializeBySubject<T>(
      graph,
      subjectId,
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
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return _graphOperations.deserializeAll(graph, register: register);
  }

  /// Deserializes all subjects of type [T] from an RDF string.
  ///
  /// This method is a type-safe variant of [deserializeAll] that filters
  /// the results to only include objects of the specified type.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the contentType will be auto-detected.
  List<T> deserializeAllOfType<T>(
    String rdfString, {
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return deserializeAll(
      rdfString,
      contentType: contentType,
      register: register,
    ).whereType<T>().toList();
  }

  String serialize<T>(
    T instance, {
    String? contentType,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = this.graph.serialize<T>(instance, register: register);
    return _rdfCore.serialize(graph, contentType: contentType);
  }

  void registerMapper<T>(Mapper<T> mapper) {
    registry.registerMapper(mapper);
  }
}

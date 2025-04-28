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
import 'package:rdf_mapper/src/mappers/rdf_blank_subject_mapper.dart';
import 'package:rdf_mapper/src/mappers/rdf_iri_term_mapper.dart';
import 'package:rdf_mapper/src/mappers/rdf_literal_term_mapper.dart';
import 'package:rdf_mapper/src/mappers/rdf_subject_mapper.dart';
import 'package:rdf_mapper/src/api/graph_operations.dart';

import 'src/api/rdf_mapper_registry.dart';
import 'src/api/rdf_mapper_service.dart';

export 'src/api/deserialization_context.dart';
export 'src/context/deserialization_context_impl.dart';
export 'src/deserializers/rdf_blank_node_term_deserializer.dart';
export 'src/deserializers/rdf_iri_term_deserializer.dart';
export 'src/serializers/rdf_iri_term_serializer.dart';
export 'src/deserializers/rdf_literal_term_deserializer.dart';
export 'src/serializers/rdf_literal_term_serializer.dart';
export 'src/api/rdf_mapper_registry.dart';
export 'src/api/rdf_mapper_service.dart';
export 'src/deserializers/rdf_subject_deserializer.dart';
export 'src/mappers/rdf_subject_mapper.dart';
export 'src/serializers/rdf_subject_serializer.dart';
export 'src/api/serialization_context.dart';
export 'src/context/serialization_context_impl.dart';
export 'src/api/graph_operations.dart';

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
  /// [format], then deserializes it into an object of type [T] using registered mappers.
  ///
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the format will be auto-detected.
  ///
  /// The [register] callback allows temporary registration of custom mappers
  /// for this operation without affecting the global registry.
  ///
  /// Usage:
  /// ```dart
  /// // Register a mapper for the Person class
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
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
    String? format,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: format);
    return _graphOperations.deserialize<T>(graph, register: register);
  }

  /// Deserializes an object of type [T] from an RDF string, identified by the subject.
  ///
  /// This method is similar to [deserialize] but allows specifying a particular subject
  /// to deserialize when the RDF representation contains multiple subjects.
  ///
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the format will be auto-detected.
  T deserializeBySubject<T>(
    String rdfString,
    RdfSubject subjectId, {
    String? format,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: format);
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
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the format will be auto-detected.
  ///
  /// Usage:
  /// ```dart
  /// // Register mappers for all relevant classes
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
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
    String? format,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: format);
    return _graphOperations.deserializeAll(graph, register: register);
  }

  /// Deserializes all subjects of type [T] from an RDF string.
  ///
  /// This method is a type-safe variant of [deserializeAll] that filters
  /// the results to only include objects of the specified type.
  ///
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// If not specified, the format will be auto-detected.
  List<T> deserializeAllOfType<T>(
    String rdfString, {
    String? format,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return deserializeAll(
      rdfString,
      format: format,
      register: register,
    ).whereType<T>().toList();
  }

  /// Serializes an object of type [T] to an RDF string representation.
  ///
  /// This method converts the provided [instance] to an RDF graph using registered serializers,
  /// then serializes the graph to a string in the specified format.
  ///
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// Defaults to 'text/turtle' if not specified.
  ///
  /// Usage:
  /// ```dart
  /// // Register a mapper for the Person class
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
  ///
  /// final person = Person(
  ///   id: 'http://example.org/person/1',
  ///   name: 'John Doe',
  ///   age: 30,
  /// );
  ///
  /// final turtle = rdfMapper.serialize(person);
  /// ```
  String serialize<T>(
    T instance, {
    String format = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = this.graph.serialize<T>(instance, register: register);
    return _rdfCore.serialize(graph, contentType: format);
  }

  /// Serializes a list of objects to an RDF string representation.
  ///
  /// This method converts the provided [instances] to an RDF graph using registered serializers,
  /// then serializes the graph to a string in the specified format.
  ///
  /// [format] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// Defaults to 'text/turtle' if not specified.
  ///
  /// Usage:
  /// ```dart
  /// // Register a mapper for the Person class
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
  ///
  /// final people = [
  ///   Person(id: 'http://example.org/person/1', name: 'John Doe', age: 30),
  ///   Person(id: 'http://example.org/person/2', name: 'Jane Smith', age: 28),
  /// ];
  ///
  /// final turtle = rdfMapper.serializeList(people);
  /// ```
  String serializeList<T>(
    List<T> instances, {
    String format = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = this.graph.serializeList<T>(instances, register: register);
    return _rdfCore.serialize(graph, contentType: format);
  }

  // ---- MAPPER REGISTRATION METHODS ----

  /// Registers a subject mapper for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerSubjectMapper].
  /// It simplifies the registration of mappers directly through the facade.
  ///
  /// Example:
  /// ```dart
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
  /// final person = Person(...);
  /// final graph = rdfMapper.graph.serialize(person);
  /// ```
  void registerSubjectMapper<T>(RdfSubjectMapper<T> mapper) {
    registry.registerSubjectMapper<T>(mapper);
  }

  /// Registers a blank subject mapper for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerBlankSubjectMapper].
  /// It simplifies the registration of mappers for blank nodes directly through the facade.
  ///
  /// Example:
  /// ```dart
  /// rdfMapper.registerBlankSubjectMapper<Address>(AddressMapper());
  /// ```
  void registerBlankSubjectMapper<T>(RdfBlankSubjectMapper<T> mapper) {
    registry.registerBlankSubjectMapper<T>(mapper);
  }

  /// Registers both a literal serializer and deserializer for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerLiteralMapper].
  void registerLiteralMapper<T>(RdfLiteralTermMapper<T> mapper) {
    registry.registerLiteralMapper<T>(mapper);
  }

  /// Registers an IRI term mapper for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerIriTermMapper].
  void registerIriTermMapper<T>(RdfIriTermMapper<T> mapper) {
    registry.registerIriTermMapper<T>(mapper);
  }
}

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
/// final graph = rdfmapper.toGraph(myObject);
/// final obj = rdfmapper.fromGraph<MyType>(graph);
/// ```
///
library rdf_mapper;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_blank_subject_mapper.dart';
import 'package:rdf_mapper/rdf_iri_term_mapper.dart';
import 'package:rdf_mapper/rdf_literal_term_mapper.dart';
import 'package:rdf_mapper/rdf_subject_mapper.dart';

import 'rdf_mapper_registry.dart';
import 'rdf_mapper_service.dart';

export 'deserialization_context.dart';
export 'deserialization_context_impl.dart';
export 'rdf_blank_node_term_deserializer.dart';
export 'rdf_blank_subject_mapper.dart';
export 'rdf_iri_term_deserializer.dart';
export 'rdf_iri_term_mapper.dart';
export 'rdf_iri_term_serializer.dart';
export 'rdf_literal_term_deserializer.dart';
export 'rdf_literal_term_mapper.dart';
export 'rdf_literal_term_serializer.dart';
export 'rdf_mapper_registry.dart';
export 'rdf_mapper_service.dart';
export 'rdf_subject_deserializer.dart';
export 'rdf_subject_mapper.dart';
export 'rdf_subject_serializer.dart';
export 'serialization_context.dart';
export 'serialization_context_impl.dart';

/// Central facade for the RDF Mapper library, providing access to object mapping and registry operations.
///
/// This class serves as the primary entry point for the RDF Mapper system, offering a simplified API
/// for mapping objects to and from RDF graphs, and for accessing the underlying registry.
final class RdfMapper {
  final RdfMapperService _service;
  final RdfCore _rdfCore;

  /// Creates an ORM facade with custom components.
  ///
  /// Allows dependency injection of both the registry and RDF core components,
  /// enabling more flexible usage and better testability.
  ///
  /// @param registry The mapper registry to use for serialization/deserialization
  /// @param rdfCore Optional RDF core instance for string parsing/serialization
  RdfMapper({required RdfMapperRegistry registry, RdfCore? rdfCore})
    : _service = RdfMapperService(registry: registry),
      _rdfCore = rdfCore ?? RdfCore.withStandardFormats();

  /// Creates an ORM facade with a default registry and standard mappers.
  factory RdfMapper.withDefaultRegistry() =>
      RdfMapper(registry: RdfMapperRegistry());

  /// Access to the underlying registry for custom mapper registration.
  RdfMapperRegistry get registry => _service.registry;

  /// Deserialize an object of type [T] from an RDF graph, identified by the subject.
  T fromGraphBySubject<T>(
    RdfGraph graph,
    RdfSubject subjectId, {
    // Optionally override the subject deserializer
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraphBySubject<T>(graph, subjectId, register: register);
  }

  /// Convenience method to deserialize the single subject [T] from an RDF graph
  T fromGraphSingleSubject<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraphSingleSubject(graph, register: register);
  }

  /// Deserialize a list of objects from all subjects in the RDF graph.
  List<Object> fromGraph(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraph(graph, register: register);
  }

  /// Serialize an object of type [T] to an RDF graph.
  RdfGraph toGraph<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.toGraph<T>(instance, register: register);
  }

  /// Serialize a list of objects to an RDF graph.
  RdfGraph toGraphFromList<T>(
    List<T> instances, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.toGraphFromList<T>(instances, register: register);
  }

  /// Deserialize an object of type [T] from an RDF string representation.
  ///
  /// This method parses the provided [rdfString] into an RDF graph using the specified
  /// [contentType] format, then deserializes it into an object of type [T] using the
  /// registered subject mappers.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// Defaults to 'text/turtle' if not specified.
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
  /// final person = rdfMapper.fromString<Person>(turtle);
  /// ```
  T fromString<T>(
    String rdfString, {
    String contentType = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return fromGraphSingleSubject<T>(graph, register: register);
  }

  /// Deserialize an object of type [T] from an RDF string, identified by the subject.
  ///
  /// This method is similar to [fromString] but allows specifying a particular subject
  /// to deserialize when the RDF representation contains multiple subjects.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// Defaults to 'text/turtle' if not specified.
  T fromStringBySubject<T>(
    String rdfString,
    RdfSubject subjectId, {
    String contentType = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return fromGraphBySubject<T>(graph, subjectId, register: register);
  }

  /// Deserialize multiple objects from an RDF string representation.
  ///
  /// This method deserializes all subjects in the parsed RDF graph into a list of objects.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
  /// Defaults to 'text/turtle' if not specified.
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
  /// final people = rdfMapper.fromStringAllSubjects(turtle)
  ///   .whereType<Person>()
  ///   .toList();
  /// ```
  List<Object> fromStringAllSubjects(
    String rdfString, {
    String contentType = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = _rdfCore.parse(rdfString, contentType: contentType);
    return fromGraph(graph, register: register);
  }

  /// Serialize an object of type [T] to an RDF string representation.
  ///
  /// This method converts the provided [instance] to an RDF graph using registered serializers,
  /// then serializes the graph to a string in the specified format.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
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
  /// final turtle = rdfMapper.toString(person);
  /// ```
  String toStringFromSubject<T>(
    T instance, {
    String contentType = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = toGraph<T>(instance, register: register);
    return _rdfCore.serialize(graph, contentType: contentType);
  }

  /// Serialize a list of objects to an RDF string representation.
  ///
  /// This method converts the provided [instances] to an RDF graph using registered serializers,
  /// then serializes the graph to a string in the specified format.
  ///
  /// [contentType] should be a MIME type like 'text/turtle' or 'application/ld+json'.
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
  /// final turtle = rdfMapper.toStringFromList(people);
  /// ```
  String toStringFromSubjects<T>(
    List<T> instances, {
    String contentType = 'text/turtle',
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final graph = toGraphFromList<T>(instances, register: register);
    return _rdfCore.serialize(graph, contentType: contentType);
  }

  /// Registers a subject mapper for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerSubjectMapper].
  /// It simplifies the registration of mappers directly through the facade.
  ///
  /// Example:
  /// ```dart
  /// rdfMapper.registerSubjectMapper<Person>(PersonMapper());
  /// final person = Person(...);
  /// final graph = rdfMapper.toGraph(person);
  /// ```
  ///
  /// @param mapper The mapper implementation for type T
  void registerSubjectMapper<T>(RdfSubjectMapper<T> mapper) {
    registry.registerSubjectMapper<T>(mapper);
  }

  /// Registers a subject mapper for type [T] for subjects that are not
  /// globally identified by an IriTerm but only use a locally referencable BlankNodeTerm.
  ///
  /// This is a convenience method that delegates to [registry.registerBlankNodeTermDeserializer] and [registry.registerSubjectSerializer] .
  /// It simplifies the registration of mappers for blank nodes directly through the facade.
  ///
  /// Example:
  /// ```dart
  /// rdfMapper.registerBlankSubjectMapper<Address>(AddressMapper());
  /// final address = Address(...);
  /// final graph = rdfMapper.toGraph(address);
  /// ```
  ///
  /// @param mapper The mapper implementation for type T
  void registerBlankSubjectMapper<T>(RdfBlankSubjectMapper<T> mapper) {
    registry.registerBlankNodeTermDeserializer<T>(mapper);
    registry.registerSubjectSerializer<T>(mapper);
  }

  /// Registers a literal mapper for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerLiteralSerializer] and [registry.registerLiteralDeserializer].
  ///
  /// @param serializer The serializer implementation for type T
  void registerLiteralMapper<T>(RdfLiteralTermMapper<T> mapper) {
    registry.registerLiteralSerializer<T>(mapper);
    registry.registerLiteralDeserializer<T>(mapper);
  }

  /// Registers an IRI term serializer for type [T].
  ///
  /// This is a convenience method that delegates to [registry.registerIriTermSerializer] and [registry.registerIriTermDeserializer].
  ///
  /// @param serializer The serializer implementation for type T
  void registerIriTermMapper<T>(RdfIriTermMapper<T> mapper) {
    registry.registerIriTermSerializer<T>(mapper);
    registry.registerIriTermDeserializer<T>(mapper);
  }
}

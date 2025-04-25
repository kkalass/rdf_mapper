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
/// import 'package:rdf_mapper/rdf_orm.dart';
///
/// final orm = RdfOrm.withDefaultRegistry();
/// final graph = orm.toGraph('root', myObject);
/// final obj = orm.fromGraph<MyType>('root', graph, subject);
/// ```
///
library rdf_orm;

import 'package:rdf_core/graph/rdf_graph.dart';
import 'package:rdf_core/graph/rdf_term.dart';

import 'rdf_mapper_registry.dart';
import 'rdf_mapper_service.dart';

export 'deserialization_context.dart';
export 'deserialization_context_impl.dart';
export 'rdf_blank_node_term_deserializer.dart';
export 'rdf_iri_term_deserializer.dart';
export 'rdf_iri_term_serializer.dart';
export 'rdf_literal_term_deserializer.dart';
export 'rdf_literal_term_serializer.dart';
export 'rdf_mapper_registry.dart';
export 'rdf_mapper_service.dart';
export 'rdf_subject_deserializer.dart';
export 'rdf_subject_mapper.dart';
export 'rdf_subject_serializer.dart';
export 'serialization_context.dart';
export 'serialization_context_impl.dart';

/// Central facade for the RDF ORM library, providing access to object mapping and registry operations.
///
/// This class serves as the primary entry point for the RDF ORM system, offering a simplified API
/// for mapping objects to and from RDF graphs, and for accessing the underlying registry.
final class RdfOrm {
  final RdfMapperService _service;

  /// Creates an ORM facade with a custom registry.
  RdfOrm({required RdfMapperRegistry registry})
    : _service = RdfMapperService(registry: registry);

  /// Creates an ORM facade with a default registry and standard mappers.
  factory RdfOrm.withDefaultRegistry() => RdfOrm(registry: RdfMapperRegistry());

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
  T fromGraph<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraph(graph, register: register);
  }

  /// Deserialize a list of objects from all subjects in the RDF graph.
  List<Object> fromGraphAllSubjects(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraphAllSubjects(graph, register: register);
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
}

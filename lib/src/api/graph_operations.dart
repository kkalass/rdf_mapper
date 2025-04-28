import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_service.dart';

/// Provides graph-based operations for the RDF Mapper.
///
/// This class encapsulates all operations that work directly with RDF graphs,
/// separating these concerns from string-based operations in the main API.
final class GraphOperations {
  final RdfMapperService _service;

  /// Creates a new GraphOperations instance.
  ///
  /// @param service The mapper service to delegate operations to
  GraphOperations(this._service);

  /// Deserializes an object of type [T] from an RDF graph.
  ///
  /// This method expects the graph to contain exactly one subject of the specified type.
  /// If multiple subjects exist, consider using [deserializeBySubject] or [deserializeAll].
  T deserialize<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraphSingleSubject(graph, register: register);
  }

  /// Deserializes an object of type [T] from an RDF graph, identified by the subject.
  ///
  /// This method allows specifying a particular subject to deserialize when the RDF graph
  /// contains multiple subjects.
  T deserializeBySubject<T>(
    RdfGraph graph,
    RdfSubject subjectId, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraphBySubject<T>(graph, subjectId, register: register);
  }

  /// Deserializes all subjects from an RDF graph into a list of objects.
  ///
  /// This method deserializes all subjects in the graph into objects using the
  /// registered mappers. The resulting list may contain objects of different types.
  List<Object> deserializeAll(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.fromGraph(graph, register: register);
  }

  /// Deserializes all subjects of type [T] from an RDF graph.
  ///
  /// This method is a type-safe variant of [deserializeAll] that filters
  /// the results to only include objects of the specified type.
  List<T> deserializeAllOfType<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return deserializeAll(graph, register: register).whereType<T>().toList();
  }

  /// Converts an object of type [T] to an RDF graph.
  ///
  /// This method uses the registered mappers to convert the object to an RDF graph.
  RdfGraph serialize<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.toGraph<T>(instance, register: register);
  }

  /// Converts a list of objects to an RDF graph.
  ///
  /// This method uses the registered mappers to convert each object in the list
  /// to RDF triples, which are combined into a single graph.
  RdfGraph serializeList<T>(
    List<T> instances, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.toGraphFromList<T>(instances, register: register);
  }
}

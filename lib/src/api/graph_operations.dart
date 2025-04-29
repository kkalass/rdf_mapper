import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_service.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';

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
    return _service.deserialize(graph, register: register);
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
    return _service.deserializeBySubject<T>(
      graph,
      subjectId,
      register: register,
    );
  }

  /// Deserializes all subjects from an RDF graph into a list of objects.
  ///
  /// This method deserializes all subjects in the graph into objects using the
  /// registered mappers. The resulting list may contain objects of different types.
  List<Object> deserializeAll(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.deserializeAll(graph, register: register);
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

  /// Serializes an object or collection of objects to an RDF graph.
  ///
  /// This method intelligently handles both single instances and collections:
  /// - For a single object, it creates a graph with that object's triples
  /// - For an Iterable of objects, it combines all objects into a single graph
  ///
  /// Usage with single instance:
  /// ```dart
  /// final person = Person(id: 'http://example.org/person/1', name: 'John Doe');
  /// final graph = graphOperations.serialize(person);
  /// ```
  ///
  /// Usage with multiple instances:
  /// ```dart
  /// final people = [
  ///   Person(id: 'http://example.org/person/1', name: 'John Doe'),
  ///   Person(id: 'http://example.org/person/2', name: 'Jane Smith')
  /// ];
  /// final graph = graphOperations.serialize(people);
  /// ```
  RdfGraph serialize<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Clone registry if registration callback is provided
    final registry =
        register != null ? _service.registry.clone() : _service.registry;
    if (register != null) {
      register(registry);
    }

    final Iterable instances =
        instance is Iterable && !registry.hasNodeSerializerFor<T>()
            ? instance
            : [instance];
    final allTriples = <Triple>[];

    final context = SerializationContextImpl(registry: registry);

    for (final instance in instances) {
      // Since we can't use a generic type parameter based on runtime type,
      // we rely on the context.subject method without an explicit serializer.
      // The SerializationContextImpl class will internally select the correct
      // serializer based on the runtime type of the instance object.
      allTriples.addAll(context.node(instance));
    }

    return RdfGraph(triples: allTriples);
  }
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_service.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';

/// Provides direct graph-based operations for RDF object mapping.
///
/// The GraphOperations class encapsulates all functionality that works directly with
/// RDF graphs rather than string representations. It provides graph-level serialization
/// and deserialization capabilities for advanced use cases where direct access to the
/// RDF graph structure is needed.
///
/// This API layer is particularly useful when:
/// - Working with existing RDF graphs from other sources
/// - Building complex graph structures incrementally
/// - Performing graph transformations before serialization to strings
/// - Integrating with graph-based RDF libraries
///
/// This class is typically accessed through the [RdfMapper.graph] property,
/// but can also be used independently when string conversion is not needed.
final class GraphOperations {
  final RdfMapperService _service;

  /// Creates a new GraphOperations instance.
  ///
  /// @param service The mapper service to delegate operations to
  GraphOperations(this._service);

  /// Deserializes an object of type [T] from an RDF graph.
  ///
  /// This method finds and deserializes a subject of the specified type in the graph.
  /// It will attempt to find a subject with an rdf:type triple matching a registered
  /// deserializer for type [T].
  ///
  /// Note that this method expects the graph to contain exactly one deserializable
  /// subject of the specified type. If multiple subjects could match, use
  /// [deserializeBySubject] or [deserializeAll] instead.
  ///
  /// Example:
  /// ```dart
  /// final person = graphOperations.deserialize<Person>(graph);
  /// ```
  ///
  /// @param graph The RDF graph to deserialize from
  /// @param register Optional callback to register temporary mappers
  /// @return The deserialized object of type T
  /// @throws TooManyDeserializableSubjectsException if multiple subjects can be deserialized
  /// @throws NoDeserializableSubjectsException if no deserializable subject is found
  T deserialize<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.deserialize(graph, register: register);
  }

  /// Deserializes an object of type [T] from an RDF graph, using a specific subject.
  ///
  /// Unlike [deserialize], this method allows you to specify exactly which subject
  /// to deserialize when the graph contains multiple subjects. This is useful when
  /// working with complex graphs that contain multiple related resources.
  ///
  /// Example:
  /// ```dart
  /// final subject = IriTerm('http://example.org/people/john');
  /// final person = graphOperations.deserializeBySubject<Person>(graph, subject);
  /// ```
  ///
  /// @param graph The RDF graph to deserialize from
  /// @param subjectId The subject identifier (IRI or blank node) to deserialize
  /// @param register Optional callback to register temporary mappers
  /// @return The deserialized object of type T
  /// @throws DeserializerNotFoundException if no deserializer is found for the type
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

  /// Deserializes all deserializable subjects from an RDF graph into a list of objects.
  ///
  /// This method iterates through all subjects in the graph and attempts to deserialize
  /// each one using registered deserializers. The resulting list may contain objects of
  /// different types, based on the rdf:type triples in the graph.
  ///
  /// This is useful for processing mixed-type RDF data where the exact structure
  /// of the graph is not known in advance.
  ///
  /// Example:
  /// ```dart
  /// // Register all relevant mappers
  /// registry.registerMapper<Person>(PersonMapper());
  /// registry.registerMapper<Organization>(OrganizationMapper());
  ///
  /// // Deserialize all subjects
  /// final entities = graphOperations.deserializeAll(graph);
  /// final people = entities.whereType<Person>().toList();
  /// final orgs = entities.whereType<Organization>().toList();
  /// ```
  ///
  /// @param graph The RDF graph to deserialize from
  /// @param register Optional callback to register temporary mappers
  /// @return A list of deserialized objects (of potentially different types)
  List<Object> deserializeAll(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _service.deserializeAll(graph, register: register);
  }

  /// Deserializes all subjects of type [T] from an RDF graph.
  ///
  /// This method is a type-safe variant of [deserializeAll] that filters
  /// the results to only include objects of the specified type. It's a convenient
  /// way to extract all instances of a specific type from a graph.
  ///
  /// Example:
  /// ```dart
  /// final people = graphOperations.deserializeAllOfType<Person>(graph);
  /// ```
  ///
  /// @param graph The RDF graph to deserialize from
  /// @param register Optional callback to register temporary mappers
  /// @return A list of deserialized objects of type T
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
  /// The method handles type detection automatically and selects the appropriate
  /// serializer based on the runtime type of the objects.
  ///
  /// Example with single instance:
  /// ```dart
  /// final person = Person(id: 'http://example.org/person/1', name: 'John Doe');
  /// final graph = graphOperations.serialize(person);
  /// ```
  ///
  /// Example with multiple instances:
  /// ```dart
  /// final people = [
  ///   Person(id: 'http://example.org/person/1', name: 'John Doe'),
  ///   Person(id: 'http://example.org/person/2', name: 'Jane Smith')
  /// ];
  /// final graph = graphOperations.serialize(people);
  /// ```
  ///
  /// @param instance The object or collection of objects to serialize
  /// @param register Optional callback to register temporary mappers
  /// @return An RDF graph containing the serialized object(s)
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

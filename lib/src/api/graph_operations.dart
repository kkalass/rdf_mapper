import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_service.dart';
import 'package:rdf_mapper/src/codec/rdf_mapper_codec.dart';

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

  RdfObjectCodec<T> objectCode<T>({
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return RdfObjectCodec<T>(service: _service, register: register);
  }

  RdfObjectsCodec<T> objectsCodec<T>({
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return RdfObjectsCodec<T>(service: _service, register: register);
  }

  /// Deserializes an object of type [T] from an RDF graph.
  ///
  /// This method finds and deserializes a subject of the specified type in the graph.
  /// It will attempt to find a subject with an rdf:type triple matching a registered
  /// deserializer for type [T].
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using an
  /// [IriNodeMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// Note that this method expects the graph to contain exactly one deserializable
  /// subject of the specified type. If multiple subjects could match, use
  /// [deserializeBySubject] or [decodeObjects] instead.
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
  T decodeObject<T>(
    RdfGraph graph, {
    RdfSubject? subject,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectCode<T>(register: register).decode(graph, subject: subject);
  }

  /// Deserializes all subjects of type [T] from an RDF graph.
  ///
  /// Note that it
  /// is perfectly valid to call this method with Object as the type parameter,
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using an
  /// [IriNodeMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// Example 1:
  /// ```dart
  /// final people = graphOperations.deserializeAllOfType<Person>(graph);
  /// ```
  ///
  /// Example 2:
  /// ```dart
  /// // Register all relevant mappers
  /// registry.registerMapper<Person>(PersonMapper());
  /// registry.registerMapper<Organization>(OrganizationMapper());
  ///
  /// // Deserialize all subjects
  /// final entities = graphOperations.deserializeAll<Object>(graph);
  /// final people = entities.whereType<Person>().toList();
  /// final orgs = entities.whereType<Organization>().toList();
  /// ```
  ///
  /// @param graph The RDF graph to deserialize from
  /// @param register Optional callback to register temporary mappers
  /// @return A list of deserialized objects of type T
  List<T> decodeObjects<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectsCodec<T>().decode(graph, register: register).toList();
  }

  /// Serializes an object of type [T] to an RDF graph.
  ///
  /// This method converts a Dart object to its RDF representation using
  /// registered mappers, producing a graph of RDF triples.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using an
  /// [IriNodeMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// @param instance The object to serialize
  /// @param register Optional callback to register temporary mappers
  /// @return An RDF graph containing the serialized object
  RdfGraph encodeObject<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectCode<T>(register: register).encode(instance);
  }

  /// Serializes a collection of objects of type [T] to an RDF graph.
  ///
  /// This method converts multiple Dart objects to their RDF representation
  /// using registered mappers, combining them into a single graph.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using an
  /// [IriNodeMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that
  /// use [LiteralTermMapper] cannot be directly deserialized as complete RDF documents,
  /// since RDF literals can only exist as objects within triples, not as standalone
  /// subjects. Attempting to use this method with literal types will result in errors.
  ///
  /// @param instance The collection of objects to serialize
  /// @param register Optional callback to register temporary mappers
  /// @return An RDF graph containing all serialized objects
  RdfGraph encodeObjects<T>(
    Iterable<T> instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectsCodec<T>().encode(instance, register: register);
  }
}

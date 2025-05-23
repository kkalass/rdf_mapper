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
  /// [_service] The mapper service to delegate operations to
  GraphOperations(this._service);

  /// Creates a codec for serializing and deserializing a single object of type [T].
  ///
  /// Returns a reusable codec object that can be used for multiple serialization
  /// or deserialization operations of the same type, which can be more efficient
  /// when working with multiple objects.
  ///
  /// [register] Optional callback to register mappers that will be available for the lifetime of the returned codec
  ///
  /// Returns a codec for type T
  RdfObjectCodec<T> objectCodec<T>({
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return RdfObjectCodec<T>(service: _service, register: register);
  }

  /// Creates a codec for serializing and deserializing collections of objects of type [T].
  ///
  /// Returns a reusable codec object that can be used for multiple serialization
  /// or deserialization operations of collections of the same type, which can be
  /// more efficient when processing multiple collections.
  ///
  /// [register] Optional callback to register mappers that will be available for the lifetime of the returned codec
  ///
  /// Returns a codec for collections of type T
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
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that use [LiteralTermMapper] cannot be directly
  /// deserialized as complete RDF documents, since RDF literals can only exist as objects
  /// within triples, not as standalone subjects. Attempting to use this method with
  /// literal types will result in errors.
  ///
  /// Note that this method expects the graph to contain exactly one deserializable
  /// subject of the specified type. If multiple subjects could match, use
  /// [decodeObjects] instead, or specify the exact [subject] to deserialize.
  ///
  /// Example:
  /// ```dart
  /// final person = graphOperations.decodeObject<Person>(graph);
  /// ```
  ///
  /// [graph] The RDF graph to deserialize from
  /// [subject] Optional subject URI to specifically target for deserialization
  /// [register] Optional callback to register mappers for this operation
  ///
  /// Returns the deserialized object of type T
  ///
  /// Throws [TooManyDeserializableSubjectsException] if multiple subjects can be deserialized
  /// Throws [NoDeserializableSubjectsException] if no deserializable subject is found
  T decodeObject<T>(
    RdfGraph graph, {
    RdfSubject? subject,
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectCodec<T>(register: register).decode(graph, subject: subject);
  }

  /// Deserializes all subjects of type [T] from an RDF graph.
  ///
  /// This method identifies and deserializes all subjects in the graph that match
  /// the specified type [T]. It's particularly useful for retrieving multiple
  /// related entities from a single graph.
  ///
  /// Note that it is perfectly valid to call this method with Object as the type parameter,
  /// which will deserialize all subjects that have registered mappers.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. that use [LiteralTermMapper] cannot be directly
  /// deserialized as complete RDF documents, since RDF literals can only exist as objects
  /// within triples, not as standalone subjects. Attempting to use this method with
  /// literal types will result in errors.
  ///
  /// Example 1:
  /// ```dart
  /// final people = graphOperations.decodeObjects<Person>(graph);
  /// ```
  ///
  /// Example 2:
  /// ```dart
  /// // Deserialize all subjects with custom mappers
  /// final entities = graphOperations.decodeObjects<Object>(graph, register: (registry) {
  ///   registry.registerMapper<Person>(PersonMapper());
  ///   registry.registerMapper<Organization>(OrganizationMapper());
  /// });
  /// final people = entities.whereType<Person>().toList();
  /// final orgs = entities.whereType<Organization>().toList();
  /// ```
  ///
  /// [graph] The RDF graph to deserialize from
  /// [register] Optional callback to register mappers for this operation
  ///
  /// Returns a list of deserialized objects of type T
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
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. cannot be directly serialized as standalone RDF subjects,
  /// since they are represented as literal values in RDF. These types should only be used as
  /// properties of resource objects, not as top-level objects to encode.
  ///
  /// Example:
  /// ```dart
  /// final person = Person(name: 'Alice', age: 30);
  /// final graph = graphOperations.encodeObject<Person>(person);
  /// ```
  ///
  /// [instance] The object to serialize
  /// [register] Optional callback to register mappers for this operation
  ///
  /// Returns an RDF graph containing the serialized object
  RdfGraph encodeObject<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectCodec<T>(register: register).encode(instance);
  }

  /// Serializes a collection of objects of type [T] to an RDF graph.
  ///
  /// This method converts multiple Dart objects to their RDF representation
  /// using registered mappers, combining them into a single graph. This is especially
  /// useful for creating graphs with multiple related entities.
  ///
  /// IMPORTANT: When using this method, the type [T] must be mapped using a
  /// [GlobalResourceMapper] either globally in the [RdfMapper] instance or locally by
  /// providing a register callback and register it there.
  ///
  /// Simple types like String, int, etc. cannot be directly serialized as standalone RDF subjects,
  /// since they are represented as literal values in RDF. These types should only be used as
  /// properties of resource objects, not as top-level objects to encode.
  ///
  /// Example:
  /// ```dart
  /// final people = [
  ///   Person(name: 'Alice', age: 30),
  ///   Person(name: 'Bob', age: 25),
  /// ];
  /// final graph = graphOperations.encodeObjects<Person>(people);
  /// ```
  ///
  /// [instances] The collection of objects to serialize
  /// [register] Optional callback to register mappers for this operation
  ///
  /// Returns an RDF graph containing all serialized objects
  RdfGraph encodeObjects<T>(
    Iterable<T> instances, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return objectsCodec<T>().encode(instances, register: register);
  }
}

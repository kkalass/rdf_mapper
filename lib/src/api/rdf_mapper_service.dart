import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';

final _log = Logger("rdf_orm.service");

/// Service for converting objects to/from RDF
///
/// This service handles the complete workflow of serializing/deserializing
/// domain objects to/from RDF, using the registered mappers.
final class RdfMapperService {
  final RdfMapperRegistry _registry;

  /// Creates a new RDF mapper service
  RdfMapperService({required RdfMapperRegistry registry})
    : _registry = registry;

  /// Access to the registry for registering custom mappers
  RdfMapperRegistry get registry => _registry;

  /// Deserialize an object of type [T] from an RDF graph which is identified by [rdfSubject] parameter.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  ///
  /// Example:
  /// ```dart
  /// orm.fromGraph<MyType>(graph, subject, register: (registry) {
  ///   registry.registerMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  T deserializeBySubject<T>(
    RdfGraph graph,
    RdfSubject rdfSubjectId, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    _log.fine('Delegated mapping graph to ${T.toString()}');

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    var context = DeserializationContextImpl(graph: graph, registry: registry);

    return context.deserialize<T>(rdfSubjectId, null, null, null, null);
  }

  /// Convenience method to deserialize the single subject [T] from an RDF graph
  T deserialize<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    var result = deserializeAll(graph, register: register);
    if (result.isEmpty) {
      throw DeserializationException('No subject found in graph');
    }
    if (result.length > 1) {
      throw DeserializationException(
        'More than one subject found in graph: ${result.map((e) => e.toString()).join(', ')}',
      );
    }
    return result[0] as T;
  }

  /// Deserialize a list of objects from all subjects in the RDF graph.
  ///
  /// This implementation ensures that each unique subject is only deserialized once,
  /// regardless of how mappers handle referenced subjects. It tracks which subjects
  /// have already been deserialized during the process to prevent duplicates.
  ///
  /// Root objects are defined as those that aren't primarily referenced as properties
  /// of other objects. Only these root objects are returned.
  ///
  /// If any subject cannot be deserialized because a deserializer is not found for its type,
  /// a [DeserializerNotFoundException] will be thrown.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  List<Object> deserializeAll(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    // Find all subjects with a type
    final typedSubjects = graph.findTriples(predicate: RdfPredicates.type);

    if (typedSubjects.isEmpty) {
      return [];
    }

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }

    // Create a specialized context that tracks processed subjects
    final context = TrackingDeserializationContext(
      graph: graph,
      registry: registry,
    );

    // Map to store deserialized objects by subject
    final Map<RdfSubject, Object> deserializedObjects = {};

    // First pass: deserialize all typed subjects
    for (final triple in typedSubjects) {
      final subject = triple.subject;
      final type = triple.object;

      // Skip if not an IRI type or already processed
      if (type is! IriTerm || deserializedObjects.containsKey(subject)) {
        continue;
      }

      try {
        // Deserialize the object and track it by subject
        final obj = context.deserializeSubject(subject, type);
        deserializedObjects[subject] = obj;
      } on DeserializerNotFoundException {
        // Propagate deserializer not found exceptions - we don't want to silently ignore them
        _log.warning(
          "No deserializer found for subject $subject with type $type",
        );
        rethrow;
      }
    }

    // Second pass: identify subjects that are primarily referenced as properties
    final subjectReferences = context.getProcessedSubjects();

    // Third pass: filter out subjects that are primarily referenced by others
    final rootObjects = <Object>[];

    for (final entry in deserializedObjects.entries) {
      final subject = entry.key;
      final object = entry.value;

      // A subject is considered a root object if:
      // 1. It has a type triple (which we've guaranteed above)
      // 2. It is not primarily referenced by other subjects
      if (!subjectReferences.contains(subject)) {
        rootObjects.add(object);
      }
    }

    return rootObjects;
  }

  /// Serialize an object of type [T] to an RDF graph.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  /// This allows for dynamic, per-call configuration without affecting the global registry.
  ///
  /// Example:
  /// ```dart
  /// orm.toGraph('root', myObject, register: (registry) {
  ///   registry.registerMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  /// @param instance The object to convert
  /// @param uri Optional URI to use as the subject
  /// @return RDF graph representing the object
  /// @throws StateError if no mapper is registered for type T
  RdfGraph serialize<T>(
    T instance, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    _log.fine('Converting instance of ${T.toString()} to RDF graph');

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    final context = SerializationContextImpl(registry: registry);

    var (_, triples) = context.subject<T>(instance);

    return RdfGraph(triples: triples);
  }

  /// Serialize a list of objects to an RDF graph.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  ///
  /// Example:
  /// ```dart
  /// orm.toGraphFromList('root', items, register: (registry) {
  ///   registry.registerMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  RdfGraph serializeList<T>(
    List<T> instances, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    _log.fine('Converting instance of ${T.toString()} to RDF graph');

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    final context = SerializationContextImpl(registry: registry);
    var triples =
        instances.expand((instance) {
          var (_, triples) = context.subject(instance);
          return triples;
        }).toList();

    return RdfGraph(triples: triples);
  }
}

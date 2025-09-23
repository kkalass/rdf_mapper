import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

final _log = Logger("rdf_orm.service");

/// Core service for mapping between Dart objects and RDF representations.
///
/// The RdfMapperService handles the complete workflow of serializing and deserializing
/// domain objects to and from RDF graphs. It acts as the central coordinator in the
/// mapping process, delegating to registered mappers and managing the serialization
/// and deserialization contexts.
///
/// This service is the bridge between the higher-level API (like RdfMapper) and
/// the actual implementation of the mapping operations. It encapsulates the core
/// mapping logic while depending on the registry for mapper resolution.
///
/// Key responsibilities:
/// - Creating appropriate serialization/deserialization contexts
/// - Managing the temporary registration of mappers
/// - Handling special cases like multi-object serialization
/// - Implementing the type resolution strategy
/// - Error handling during the mapping process
///
/// While this class can be used directly, it's typically accessed through the
/// higher-level abstractions like RdfMapper and GraphOperations.
final class RdfMapperService {
  final RdfMapperRegistry _registry;
  final IriTermFactory _iriTermFactory;

  /// Creates a new RDF mapper service.
  ///
  /// The service requires a registry that contains the mappers needed for
  /// serialization and deserialization operations.
  ///
  /// [registry] The registry containing mappers for different types
  RdfMapperService(
      {required RdfMapperRegistry registry,
      IriTermFactory iriTermFactory = IriTerm.validated})
      : _registry = registry,
        _iriTermFactory = iriTermFactory;

  /// Access to the underlying registry for registering custom mappers.
  ///
  /// This property allows direct access to the mapper registry, enabling
  /// registration of custom mappers for specific types.
  ///
  /// Returns the mapper registry used by this service.
  RdfMapperRegistry get registry => _registry;

  /// Deserializes an object of type [T] from an RDF graph, using a specific subject.
  ///
  /// This method deserializes a single object from an RDF graph, identified by
  /// the specified subject. This is useful when working with graphs that contain
  /// multiple subjects and you need to target a specific one.
  ///
  /// The deserialization process:
  /// 1. Creates a deserialization context with the provided graph
  /// 2. Looks up the appropriate deserializer for type T
  /// 3. Uses the deserializer to convert the RDF subject to a Dart object
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  ///
  /// Example:
  /// ```dart
  /// // Deserialize a person from a specific subject
  /// final person = service.deserializeBySubject<Person>(
  ///   graph,
  ///   const IriTerm('http://example.org/people/john'),
  ///   register: (registry) {
  ///     registry.registerMapper(AddressMapper());
  ///   }
  /// );
  /// ```
  ///
  /// Parameters:
  /// * [graph] - The RDF graph containing the data
  /// * [rdfSubject] - The subject identifier to deserialize
  /// * [register] - Optional callback to register temporary mappers
  /// * [completeness] - Controls how incomplete deserialization is handled:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
  ///
  /// Returns the deserialized object of type T
  ///
  /// Throws [DeserializerNotFoundException] if no deserializer is found for type T
  T deserializeBySubject<T>(
    RdfGraph graph,
    RdfSubject rdfSubject, {
    void Function(RdfMapperRegistry registry)? register,
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    final (result, remaining) = deserializeBySubjectLossless<T>(
      graph,
      rdfSubject,
      register: register,
    );
    _checkCompleteness(completeness, remaining);
    return result;
  }

  /// Deserializes the single subject of type [T] from an RDF graph.
  ///
  /// This method is a convenience wrapper that expects the graph to contain
  /// exactly one deserializable subject of the specified type. It's the simplest
  /// way to deserialize a single object when you don't need to specify which
  /// subject to target.
  ///
  /// If the graph contains no subjects or multiple subjects, an exception is thrown.
  /// For graphs with multiple subjects, use [deserializeBySubject] or [deserializeAll] instead.
  ///
  /// Example:
  /// ```dart
  /// // Deserialize a single person from a graph
  /// final person = service.deserialize<Person>(graph);
  /// ```
  ///
  /// Parameters:
  /// * [graph] - The RDF graph to deserialize from
  /// * [register] - Optional callback to register temporary mappers
  /// * [completeness] - Controls how incomplete deserialization is handled:
  ///   - [CompletenessMode.strict] (default): Throws [IncompleteDeserializationException] if any triples cannot be mapped
  ///   - [CompletenessMode.lenient]: Silently ignores unmapped triples (data loss may occur)
  ///   - [CompletenessMode.warnOnly]: Logs warnings for unmapped triples but continues (data loss may occur)
  ///   - [CompletenessMode.infoOnly]: Logs info messages for unmapped triples but continues (data loss may occur)
  ///
  /// Returns the deserialized object of type T
  ///
  /// Throws [DeserializationException] if no subject or multiple subjects are found
  /// Throws [DeserializerNotFoundException] if no deserializer is found for the subject
  T deserialize<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    final (result, remaining) =
        _deserializeLossless<T>(graph, register: register);
    _checkCompleteness(completeness, remaining);
    return result;
  }

  /// Deserializes a list of objects from all subjects in an RDF graph.
  ///
  /// This method attempts to deserialize all subjects in the graph using registered
  /// deserializers. It handles the complexity of identifying which subjects are
  /// "root" objects versus nested objects that are properties of other objects.
  ///
  /// The implementation uses a multi-pass approach:
  /// 1. First pass: Identify and deserialize all subjects with rdf:type triples
  /// 2. Second pass: Track which subjects are referenced by other subjects
  /// 3. Third pass: Filter out subjects that are primarily referenced as properties
  ///
  /// This ensures that only the top-level objects are returned, not their nested
  /// components, avoiding duplicate or inappropriate objects in the result list.
  ///
  /// The [completeness] parameter controls how incomplete deserialization is handled:
  /// - [CompletenessMode.strict]: Throws [IncompleteDeserializationException] if any triples remain
  /// - [CompletenessMode.warnOnly]: Logs warning message and continues
  /// - [CompletenessMode.infoOnly]: Logs info message and continues
  /// - [CompletenessMode.lenient]: Silently ignores unprocessed triples
  ///
  /// Example:
  /// ```dart
  /// // Deserialize all objects from a graph with strict validation
  /// final objects = service.deserializeAll(graph,
  ///   completeness: CompletenessMode.strict);
  /// final people = objects.whereType<Person>().toList();
  /// final organizations = objects.whereType<Organization>().toList();
  /// ```
  ///
  /// [graph] The RDF graph to deserialize from
  /// [register] Optional callback to register temporary mappers
  /// [completeness] How to handle incomplete deserialization (defaults to strict)
  ///
  /// Returns a list of deserialized objects (potentially of different types)
  ///
  /// Throws [IncompleteDeserializationException] if completeness is strict and triples remain
  /// Throws [DeserializerNotFoundException] if a deserializer is missing for any subject
  List<T> deserializeAll<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
    CompletenessMode completeness = CompletenessMode.strict,
  }) {
    var (result, remaining) = _deserializeAllLosslessInternal<T>(
      graph,
      register: register,
    );

    _checkCompleteness(
      completeness,
      remaining,
    );

    return result;
  }

  void _checkCompleteness(
    CompletenessMode completeness,
    RdfGraph remaining,
  ) {
    // Handle completeness validation based on mode
    if (remaining.triples.isNotEmpty) {
      if (completeness.shouldThrow) {
        throw IncompleteDeserializationException(
          remainingGraph: remaining,
        );
      } else if (completeness.shouldLog) {
        final (unmappedSubjects, unmappedTypes) =
            IncompleteDeserializationException.getUnmappedInfo(remaining);
        final message = 'Incomplete RDF deserialization: '
            '${remaining.triples.length} unprocessed triples, '
            '${unmappedSubjects.length} failed subjects, '
            '${unmappedTypes.length} unmapped types';

        if (completeness.shouldLogWarning) {
          _log.warning(message);
        } else {
          _log.info(message);
        }
      }
    }
  }

  (
    List<T> rootObjects,
    RdfGraph remaining,
  ) deserializeAllLossless<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _deserializeAllLosslessInternal<T>(
      graph,
      register: register,
    );
  }

  (
    List<T> rootObjects,
    RdfGraph remaining,
  ) _deserializeAllLosslessInternal<T>(RdfGraph graph,
      {void Function(RdfMapperRegistry registry)? register, int? maxSubjects}) {
    // Find all subjects with a type
    final typedSubjects = graph.findTriples(predicate: Rdf.type);

    if (typedSubjects.isEmpty) {
      return (<T>[], graph);
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
    final Map<RdfSubject, Set<Triple>> processedTriplesBySubject = {};
    // Keep track of subjects that couldn't be deserialized due to missing mappers
    final Set<RdfSubject> failedSubjects = {};
    // Keep track of types that had no deserializers
    final Set<IriTerm> failedTypes = {};

    // First pass: deserialize all typed subjects
    for (final triple in typedSubjects) {
      final subject = triple.subject;
      final type = triple.object;

      // Skip if not an IRI type or already processed
      if (type is! IriTerm ||
          deserializedObjects.containsKey(subject) ||
          failedSubjects.contains(subject)) {
        continue;
      }

      try {
        // Deserialize the object and track it by subject
        context.clearProcessedTriples();
        final obj = context.deserializeResource(subject, type);
        processedTriplesBySubject[subject] = context.getProcessedTriples();
        deserializedObjects[subject] = obj;
      } on DeserializerNotFoundException {
        // Record this subject as failed to deserialize
        failedSubjects.add(subject);
        failedTypes.add(type);
        _log.fine("No deserializer found for subject $subject with type $type");
        // Don't rethrow - we'll check if it's a root node later
      }
    }

    // Second pass: identify subjects that are primarily referenced as properties
    final subjectReferences = context.getProcessedSubjects();

    // Third pass: filter out subjects that are primarily referenced by others
    final rootObjects = <T>[];
    final processedTriples = <Triple>{};
    for (final entry in deserializedObjects.entries) {
      final subject = entry.key;
      final object = entry.value;

      // A subject is considered a root object if:
      // 1. It has a type triple (which we've guaranteed above)
      // 2. It is not primarily referenced by other subjects
      if (!subjectReferences.contains(subject) && object is T) {
        rootObjects.add(object as T);
        final processed = processedTriplesBySubject[subject] ?? <Triple>{};

        processedTriples.addAll(processed);
        if (maxSubjects != null && rootObjects.length >= maxSubjects) {
          _log.fine(
              'Reached max subjects limit of $maxSubjects, stopping early.');
          break;
        }
        _log.fine('Adding root object $object with subject $subject');
      } else {
        _log.fine('Skipping $object with subject $subject, '
            'referenced by others: ${subjectReferences.contains(subject)} and type: ${T}');
      }
    }

    RdfGraph remainder = graph.withoutTriples(processedTriples);
    return (rootObjects, remainder);
  }

  /// Serializes an object of type [T] to an RDF graph.
  ///
  /// This method converts a single Dart object into an RDF graph representation
  /// using the appropriate registered serializer. The serialization process:
  /// 1. Creates a serialization context
  /// 2. Looks up the appropriate serializer for the object's type
  /// 3. Uses the serializer to convert the object to RDF triples
  /// 4. Returns the triples as an RDF graph
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry,
  /// allowing for dynamic, per-call configuration without affecting the global registry.
  ///
  /// Example:
  /// ```dart
  /// final person = Person(id: 'http://example.org/person/1', name: 'John Doe');
  /// final graph = service.serialize(person);
  /// ```
  ///
  /// [instance] The object to convert
  /// [register] Optional callback to register temporary mappers
  ///
  /// Returns RDF graph representing the object
  ///
  /// Throws [SerializerNotFoundException] if no serializer is registered for the object's type
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
    final context = SerializationContextImpl(
        registry: registry, iriTermFactory: _iriTermFactory);
    final triples = context.resource(instance);
    return RdfGraph.fromTriples(triples);
  }

  RdfGraph serializeLossless<T>(
    (T, RdfGraph) input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final (instance, graph) = input;
    final serializedGraph = serialize(instance, register: register);
    return serializedGraph.merge(graph);
  }

  /// Serializes a list of objects to a combined RDF graph.
  ///
  /// This method converts multiple objects into a single RDF graph by serializing
  /// each object individually and combining their triples. This is useful for
  /// creating graphs that contain multiple related resources.
  ///
  /// The implementation handles each object separately but combines them into
  /// a single coherent graph, maintaining any relationships between the objects.
  ///
  /// Example:
  /// ```dart
  /// final people = [person1, person2, person3];
  /// final graph = service.serializeList(people);
  /// ```
  ///
  /// [instances] The list of objects to serialize
  /// [register] Optional callback to register temporary mappers
  ///
  /// Returns a combined RDF graph containing all objects' triples
  ///
  /// Throws [SerializerNotFoundException] if no serializer is found for any object's type
  RdfGraph serializeList<T>(
    Iterable<T> instances, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    _log.fine('Converting instance of ${T.toString()} to RDF graph');

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    final context = SerializationContextImpl(
        registry: registry, iriTermFactory: _iriTermFactory);
    var triples = instances.expand((instance) {
      return context.resource(instance);
    }).toList();

    return RdfGraph(triples: triples);
  }

  RdfGraph serializeListLossless<T>(
    (Iterable<T>, RdfGraph) input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    final (instances, remainder) = input;
    final graph = serializeList<T>(instances, register: register);
    return graph.merge(remainder);
  }

  /// Deserializes a single object from an RDF graph preserving the remainder.
  ///
  /// This method is similar to [deserialize] but returns both the deserialized object
  /// and any remaining RDF triples that weren't processed.
  ///
  /// [graph] The RDF graph to deserialize from
  /// [register] Optional callback to register temporary mappers
  ///
  /// Returns a tuple containing the deserialized object and remaining graph
  (T, RdfGraph) deserializeLossless<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return _deserializeLossless<T>(graph, register: register);
  }

  (
    T root,
    RdfGraph remaining,
  ) _deserializeLossless<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    var subjects = graph.triples.map((t) => t.subject).toSet();
    if (subjects.length == 1) {
      // Easy case: only one subject in the graph
      return deserializeBySubjectLossless<T>(graph, subjects.single,
          register: register);
    }
    var deserializer = registry.findDeserializerByType<T>();
    if (deserializer is ResourceDeserializer<T>) {
      var typeIri = deserializer.typeIri; // Ensure the deserializer is valid
      if (typeIri != null) {
        subjects = graph
            .findTriples(predicate: Rdf.type, object: typeIri)
            .map((t) => t.subject)
            .toSet();
        if (subjects.length == 1) {
          // We found exactly one subject with the type IRI handled by the deserializer
          // identified by the result Type.
          return deserializeBySubjectLossless<T>(graph, subjects.single,
              register: register);
        }
      }
    }
    var (result, remaining) = _deserializeAllLosslessInternal<T>(graph,
        register: register, maxSubjects: 1);
    if (result.isEmpty) {
      throw DeserializationException('No subject found in graph');
    }
    if (result.length > 1) {
      throw DeserializationException(
        'More than one subject found in graph: ${result.map((e) => e.toString()).join(', ')}',
      );
    }
    return (result[0], remaining);
  }

  /// Deserializes an object from a specific subject preserving the remainder.
  ///
  /// This method is similar to [deserializeBySubject] but returns both the deserialized
  /// object and any remaining RDF triples that weren't processed.
  ///
  /// [graph] The RDF graph containing the data
  /// [rdfSubject] The subject identifier to deserialize
  /// [register] Optional callback to register temporary mappers
  ///
  /// Returns a tuple containing the deserialized object and remaining graph
  (T, RdfGraph) deserializeBySubjectLossless<T>(
    RdfGraph graph,
    RdfSubject rdfSubject, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    _log.fine('Delegated mapping graph to ${T.toString()}');

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    var context = DeserializationContextImpl(graph: graph, registry: registry);

    var result = context.deserialize<T>(rdfSubject);

    return (result, graph.withoutTriples(context.getAllProcessedTriples()));
  }
}

import 'package:logging/logging.dart';
import 'package:rdf_core/constants/rdf_constants.dart';
import 'package:rdf_core/graph/rdf_graph.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/deserialization_context_impl.dart';
import 'package:rdf_mapper/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/rdf_mapper_registry.dart';
import 'package:rdf_mapper/serialization_context_impl.dart';

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

  /// Deserialize an object of type [T] from a list of triples.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  T fromTriplesByRdfSubjectId<T>(
    List<Triple> triples,
    RdfSubject rdfSubjectId, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return fromGraphBySubject(
      RdfGraph(triples: triples),
      rdfSubjectId,
      register: register,
    );
  }

  /// Deserialize an object of type [T] from an RDF graph which is identified by [rdfSubject] parameter.
  ///
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  ///
  /// Example:
  /// ```dart
  /// orm.fromGraph<MyType>(graph, subject, register: (registry) {
  ///   registry.registerSubjectMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  T fromGraphBySubject<T>(
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

    return context.fromRdf<T>(rdfSubjectId, null, null, null, null);
  }

  /// Convenience method to deserialize the single subject [T] from an RDF graph
  T fromGraph<T>(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    var result = fromGraphAllSubjects(graph, register: register);
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
  /// Optionally, a [register] callback can be provided to temporarily register
  /// custom mappers for this operation. The callback receives a clone of the registry.
  List<Object> fromGraphAllSubjects(
    RdfGraph graph, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    var deserializationSubjects = graph.findTriples(
      predicate: RdfConstants.typeIri,
    );

    // Clone registry if registration callback is provided
    final registry = register != null ? _registry.clone() : _registry;
    if (register != null) {
      register(registry);
    }
    var context = DeserializationContextImpl(graph: graph, registry: registry);

    return deserializationSubjects
        .map((triple) {
          final subject = triple.subject;
          final object = triple.object;
          if ((subject is! IriTerm) || (object is! IriTerm)) {
            _log.warning(
              "Will skip deserialization of subject $subject with type $object because both subject and type need to be IRIs in order to be able to deserialize.",
            );
            return null;
          }
          try {
            return context.fromRdfByTypeIri(subject, object);
          } on DeserializerNotFoundException {
            _log.warning(
              "Will skip deserialization of subject $subject with type $object because there is no Deserializer available in the registry.",
            );
            return null;
          }
        })
        .whereType<Object>()
        .toList();
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
  ///   registry.registerSubjectMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  /// @param instance The object to convert
  /// @param uri Optional URI to use as the subject
  /// @return RDF graph representing the object
  /// @throws StateError if no mapper is registered for type T
  RdfGraph toGraph<T>(
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
  ///   registry.registerSubjectMapper(ItemMapper(baseUrl));
  /// });
  /// ```
  RdfGraph toGraphFromList<T>(
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

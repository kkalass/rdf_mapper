import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserialization_service.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/resource_reader.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_vocabularies/rdf.dart';

final _log = Logger('DeserializationContextImpl');

/// Standard implementation of deserialization context
class DeserializationContextImpl extends DeserializationContext
    implements DeserializationService {
  final RdfGraph _graph;
  final RdfMapperRegistry _registry;

  final Map<RdfSubject, List<Triple>> _readTriplesBySubject = {};

  DeserializationContextImpl({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  })  : _graph = graph,
        _registry = registry;

  /// Implementation of the reader method to support fluent API.
  @override
  ResourceReader reader(RdfSubject subject) {
    return ResourceReader(subject, this);
  }

  Object deserializeResource(RdfSubject subjectIri, IriTerm typeIri) {
    var context = this;
    switch (subjectIri) {
      case BlankNodeTerm _:
        var dartType = _registry.getLocalResourceDartTypeByIriType(typeIri);
        if (dartType != null) {
          _registerTypeRead(dartType, subjectIri, typeIri: typeIri);
        }
        var deser = _registry.getLocalResourceDeserializerByType(typeIri);
        return deser.fromRdfResource(subjectIri, context);
      case IriTerm _:
        var dartType = _registry.getGlobalResourceDartTypeByIriType(typeIri);
        if (dartType != null) {
          _registerTypeRead(dartType, subjectIri, typeIri: typeIri);
        }
        var deser = _registry.getGlobalResourceDeserializerByType(typeIri);
        return deser.fromRdfResource(subjectIri, context);
    }
  }

  void _registerTypeRead(Type dartType, RdfSubject subject,
      {IriTerm? typeIri}) {
    if (typeIri == null) {
      typeIri = _graph
          .findTriples(subject: subject, predicate: Rdf.type)
          .singleOrNull
          ?.object as IriTerm?;
    }
    if (typeIri == null) {
      _log.fine('Cannot register type read for $dartType without a type IRI.');
      return;
    }
    var ser = _registry.getResourceSerializerByType(dartType);
    if (ser.typeIri == typeIri) {
      _readTriplesBySubject.putIfAbsent(subject, () => []).add(
            Triple(
              subject,
              Rdf.type,
              typeIri,
            ),
          );
    }
  }

  // Hook for the Tracking implementation to track deserialized resources.
  void _onDeserializeResource(RdfTerm term) {}

  T deserialize<T>(
    RdfTerm term,
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  ) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (globalResourceDeserializer != null ||
            _registry.hasGlobalResourceDeserializerFor<T>()) {
          var deser = globalResourceDeserializer ??
              _registry.getGlobalResourceDeserializer<T>();
          _onDeserializeResource(term);
          final ret = deser.fromRdfResource(term, context);
          _registerTypeRead(T, term);
          return ret;
        }
        var deser =
            iriTermDeserializer ?? _registry.getIriTermDeserializer<T>();
        return deser.fromRdfTerm(term, context);
      case LiteralTerm _:
        return fromLiteralTerm(term, deserializer: literalTermDeserializer);
      case BlankNodeTerm _:
        var deser = localResourceDeserializer ??
            _registry.getLocalResourceDeserializer<T>();
        _onDeserializeResource(term);
        final ret = deser.fromRdfResource(term, context);
        _registerTypeRead(T, term);
        return ret;
    }
  }

  T fromLiteralTerm<T>(LiteralTerm term,
      {LiteralTermDeserializer<T>? deserializer,
      bool bypassDatatypeCheck = false}) {
    var deser = deserializer ?? _registry.getLiteralTermDeserializer<T>();
    return deser.fromRdfTerm(term, this,
        bypassDatatypeCheck: bypassDatatypeCheck);
  }

  @override
  T? optional<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    final triples = _findTriplesForReading(subject, predicate);
    if (triples.isEmpty) {
      return null;
    }
    if (enforceSingleValue && triples.length > 1) {
      throw TooManyPropertyValuesException(
        subject: subject,
        predicate: predicate,
        objects: triples.map((t) => t.object).toList(),
      );
    }

    final rdfObject = triples.first.object;
    return deserialize<T>(
      rdfObject,
      iriTermDeserializer,
      globalResourceDeserializer,
      literalTermDeserializer,
      localResourceDeserializer,
    );
  }

  List<Triple> _findTriplesForReading(
      RdfSubject subject, RdfPredicate predicate) {
    final readTriples =
        _graph.findTriples(subject: subject, predicate: predicate);
    _readTriplesBySubject.putIfAbsent(subject, () => []).addAll(readTriples);
    // Hook for tracking deserialization
    return readTriples;
  }

  List<Triple> _getRemainingTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true}) {
    final readTriples = (_readTriplesBySubject[subject] ?? const []).toSet();
    final result = [
      ..._graph.findTriples(
        subject: subject,
      )
    ];
    result.removeWhere((triple) => readTriples.contains(triple));
    if (!includeBlankNodes) {
      return result;
    }
    final blankNodes =
        getBlankNodeObjectsDeep(_graph, result, <BlankNodeTerm>{});
    return [
      ...result,
      ...blankNodes.expand((term) => _graph.findTriples(subject: term)),
    ];
  }

  @override
  T getUnmapped<T>(RdfSubject subject,
      {bool includeBlankNodes = true,
      UnmappedTriplesDeserializer? unmappedTriplesDeserializer}) {
    final triples = _getRemainingTriplesForSubject(subject,
        includeBlankNodes: includeBlankNodes);
    unmappedTriplesDeserializer ??=
        _registry.getUnmappedTriplesDeserializer<T>();
    return unmappedTriplesDeserializer.fromUnmappedTriples(triples);
  }

  @override
  List<Triple> getAllRemainingTriples() {
    final allReadTriples =
        _readTriplesBySubject.values.expand((e) => e).toSet();
    return _graph.triples
        .where((triple) => !allReadTriples.contains(triple))
        .toList(growable: false);
  }

  @override
  R collect<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    final triples = _findTriplesForReading(subject, predicate);
    final convertedTriples = triples.map(
      (triple) => deserialize(
        triple.object,
        iriTermDeserializer,
        globalResourceDeserializer,
        literalTermDeserializer,
        localResourceDeserializer,
      ),
    );
    return collector(convertedTriples);
  }

  @override
  T require<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    var result = optional<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriTermDeserializer: iriTermDeserializer,
      globalResourceDeserializer: globalResourceDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
    if (result == null) {
      throw PropertyValueNotFoundException(
        subject: subject,
        predicate: predicate,
      );
    }
    return result;
  }

  /// Gets a list of property values
  ///
  /// Convenience method that collects multiple property values into a List.
  Iterable<T> getValues<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) =>
      collect<T, Iterable<T>>(
        subject,
        predicate,
        (it) => it.toList(),
        iriTermDeserializer: iriTermDeserializer,
        globalResourceDeserializer: globalResourceDeserializer,
        literalTermDeserializer: literalTermDeserializer,
        localResourceDeserializer: localResourceDeserializer,
      );

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    GlobalResourceDeserializer<MapEntry<K, V>>? globalResourceDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    LocalResourceDeserializer<MapEntry<K, V>>? localResourceDeserializer,
  }) =>
      collect<MapEntry<K, V>, Map<K, V>>(
        subject,
        predicate,
        (it) => Map<K, V>.fromEntries(it),
        iriTermDeserializer: iriTermDeserializer,
        globalResourceDeserializer: globalResourceDeserializer,
        literalTermDeserializer: literalTermDeserializer,
        localResourceDeserializer: localResourceDeserializer,
      );

  /// Recursively collects blank nodes from triples, maintaining a visited set to prevent cycles
  @visibleForTesting
  static Set<BlankNodeTerm> getBlankNodeObjectsDeep(
      RdfGraph graph, List<Triple> triples, Set<BlankNodeTerm> visited) {
    final blankNodes = triples
        .map((t) => t.object)
        .whereType<BlankNodeTerm>()
        .where((node) => !visited.contains(node))
        .toSet();

    if (blankNodes.isEmpty) {
      return <BlankNodeTerm>{};
    }

    // Add newly discovered blank nodes to visited set
    visited.addAll(blankNodes);

    // Recursively find blank nodes referenced by these blank nodes
    final nestedBlankNodes = blankNodes.expand((term) {
      final subjectTriples = graph.findTriples(subject: term);
      return getBlankNodeObjectsDeep(graph, subjectTriples, visited);
    }).toSet();

    return <BlankNodeTerm>{...blankNodes, ...nestedBlankNodes};
  }

  @override
  List<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true}) {
    final triples = _graph.findTriples(subject: subject);
    if (!includeBlankNodes) {
      return triples;
    }
    final blankNodes =
        getBlankNodeObjectsDeep(_graph, triples, <BlankNodeTerm>{});
    final result = [
      ...triples,
      ...blankNodes.expand((term) => _graph.findTriples(subject: term)),
    ];
    _readTriplesBySubject.putIfAbsent(subject, () => []).addAll(result);
    return result;
  }
}

/// A specialized deserialization context that tracks subject processing order.
///
/// This context extends the standard implementation to maintain a record of when
/// each subject was first processed. This allows determining which subjects were
/// processed as part of other objects' deserialization and which were root objects.
class TrackingDeserializationContext extends DeserializationContextImpl {
  // Maps subjects to their first processing index
  final Set<RdfSubject> _processedSubjects = {};

  TrackingDeserializationContext({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  }) : super(graph: graph, registry: registry);

  @override
  void _onDeserializeResource(RdfTerm term) {
    super._onDeserializeResource(term);
    // Track processing of subject terms
    if (term is RdfSubject) {
      _processedSubjects.add(term);
    }
  }

  /// Returns the map of processed subjects with their first processing index
  Set<RdfSubject> getProcessedSubjects() => _processedSubjects;
}

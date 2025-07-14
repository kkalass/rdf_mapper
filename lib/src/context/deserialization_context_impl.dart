import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
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
        var deser = _registry.getLocalResourceDeserializerByType(typeIri);
        _registerTypeRead(deser, subjectIri, typeIri: typeIri);
        return deser.fromRdfResource(subjectIri, context);
      case IriTerm _:
        var deser = _registry.getGlobalResourceDeserializerByType(typeIri);
        _registerTypeRead(deser, subjectIri, typeIri: typeIri);
        return deser.fromRdfResource(subjectIri, context);
    }
  }

  void _registerTypeRead<T>(ResourceDeserializer<T> deser, RdfSubject subject,
      {IriTerm? typeIri}) {
    if (typeIri == null) {
      typeIri = _graph
          .findTriples(subject: subject, predicate: Rdf.type)
          .singleOrNull
          ?.object as IriTerm?;
    }
    if (typeIri == null) {
      _log.fine('Cannot register type read for $deser without a type IRI.');
      return;
    }

    if (deser.typeIri == typeIri) {
      trackTriplesRead(
        subject,
        [
          Triple(
            subject,
            Rdf.type,
            typeIri,
          )
        ],
      );
    }
  }

  void trackTriplesRead(RdfSubject subject, Iterable<Triple> triples) {
    _readTriplesBySubject.putIfAbsent(subject, () => []).addAll(triples);
    _onTriplesRead(triples);
  }

  // Hook for the Tracking implementation to track deserialized resources.
  /// Called when a resource is deserialized as a Resource instead of IriTerm
  /// within deserialization of another resource,
  /// not when the toplevel deserializeResource is called!
  void _onDeserializeChildResource(RdfTerm term) {}
  void _onTriplesRead(Iterable<Triple> triples) {}

  T deserialize<T>(
    RdfTerm term, {
    Deserializer<T>? deserializer,
  }) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (deserializer is GlobalResourceDeserializer<T> ||
            _registry.hasGlobalResourceDeserializerFor<T>()) {
          var deser = deserializer is GlobalResourceDeserializer<T>
              ? deserializer
              : _registry.getGlobalResourceDeserializer<T>();
          _onDeserializeChildResource(term);
          _registerTypeRead(deser, term);
          return deser.fromRdfResource(term, context);
        }
        return fromIriTerm(term,
            deserializer:
                deserializer is IriTermDeserializer<T> ? deserializer : null);
      case LiteralTerm _:
        return fromLiteralTerm(term,
            deserializer: deserializer is LiteralTermDeserializer<T>
                ? deserializer
                : null);
      case BlankNodeTerm _:
        var deser = deserializer is LocalResourceDeserializer<T>
            ? deserializer
            : _registry.getLocalResourceDeserializer<T>();
        _onDeserializeChildResource(term);
        _registerTypeRead(deser, term);
        return deser.fromRdfResource(term, context);
    }
  }

  T fromLiteralTerm<T>(LiteralTerm term,
      {LiteralTermDeserializer<T>? deserializer,
      bool bypassDatatypeCheck = false}) {
    try {
      deserializer ??= _registry.getLiteralTermDeserializer<T>();
    } on DeserializerNotFoundException catch (_) {
      // could not find a deserializer for the requested target type,
      // lets look for a deserializer by datatype
      deserializer =
          _registry.getLiteralTermDeserializerByType<T>(term.datatype);
    }
    return deserializer.fromRdfTerm(term, this,
        bypassDatatypeCheck: bypassDatatypeCheck);
  }

  T fromIriTerm<T>(IriTerm term, {IriTermDeserializer<T>? deserializer}) {
    try {
      deserializer ??= _registry.getIriTermDeserializer<T>();
    } on DeserializerNotFoundException catch (_) {
      // could not find a deserializer for the requested target type,
      // lets look for a deserializer by datatype
      deserializer = _registry.getFirstIriTermDeserializer<T>();
    }
    return deserializer.fromRdfTerm(term, this);
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
      deserializer: iriTermDeserializer ??
          globalResourceDeserializer ??
          literalTermDeserializer ??
          localResourceDeserializer,
    );
  }

  List<Triple> _findTriplesForReading(
      RdfSubject subject, RdfPredicate predicate) {
    final readTriples =
        _graph.findTriples(subject: subject, predicate: predicate);

    trackTriplesRead(subject, readTriples);
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
      {UnmappedTriplesDeserializer? unmappedTriplesDeserializer}) {
    unmappedTriplesDeserializer ??=
        _registry.getUnmappedTriplesDeserializer<T>();

    final triples = _getRemainingTriplesForSubject(subject,
        includeBlankNodes: unmappedTriplesDeserializer.deep);

    trackTriplesRead(subject, triples);

    return unmappedTriplesDeserializer.fromUnmappedTriples(triples);
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
        deserializer: iriTermDeserializer ??
            globalResourceDeserializer ??
            literalTermDeserializer ??
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
      {bool includeBlankNodes = true, bool trackRead = true}) {
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
    if (trackRead) {
      trackTriplesRead(subject, result);
    }
    return result;
  }

  Set<Triple> getAllProcessedTriples() {
    return _readTriplesBySubject.values.expand((triples) => triples).toSet();
  }

  @override
  Iterable<V> readRdfList<V>(RdfSubject subject,
      {Deserializer<V>? deserializer}) sync* {
    if (subject == Rdf.nil) {
      return; // rdf:nil represents an empty list
    }

    RdfSubject cur = subject;
    final visitedNodes = <RdfSubject>{};

    while (cur != Rdf.nil) {
      // Cycle detection: check if we've seen this node before
      if (visitedNodes.contains(cur)) {
        throw StateError(
            'Circular reference detected in RDF list at node: $cur');
      }
      visitedNodes.add(cur);

      final triples =
          getTriplesForSubject(cur, includeBlankNodes: false, trackRead: false);

      final first = triples.singleWhere(
          (triple) => triple.subject == cur && triple.predicate == Rdf.first);
      final rest = triples.singleWhere(
          (triple) => triple.subject == cur && triple.predicate == Rdf.rest);

      trackTriplesRead(cur, [first, rest]);

      final object = first.object;
      final deserialized = deserialize<V>(object, deserializer: deserializer);
      yield deserialized;

      // Move to next node after successful processing
      cur = rest.object as RdfSubject;
    }
  }
}

class TrackingDeserializationContext extends DeserializationContextImpl {
  final Set<RdfSubject> _processedSubjects = {};
  Set<Triple> _processedTriples = {};

  TrackingDeserializationContext({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  }) : super(graph: graph, registry: registry);

  @override
  void _onDeserializeChildResource(RdfTerm term) {
    super._onDeserializeChildResource(term);
    // Track processing of subject terms
    if (term is RdfSubject) {
      _processedSubjects.add(term);
    }
  }

  @override
  void _onTriplesRead(Iterable<Triple> triples) {
    _processedTriples.addAll(triples);
  }

  void clearProcessedTriples() {
    _processedTriples = {};
  }

  Set<Triple> getProcessedTriples() => _processedTriples;

  /// Returns the set of processed subjects
  Set<RdfSubject> getProcessedSubjects() => _processedSubjects;
}

import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

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
    final Set<IriTerm> typeIris;
    if (typeIri == null) {
      typeIris = _graph
          .findTriples(subject: subject, predicate: Rdf.type)
          .map((e) => e.object)
          .whereType<IriTerm>()
          .toSet();
    } else {
      typeIris = <IriTerm>{typeIri};
    }
    if (typeIris.isEmpty) {
      _log.fine('Cannot register type read for $deser without a type IRI.');
      return;
    }
    final deserTypeIri = deser.typeIri;
    if (deserTypeIri == null) {
      return;
    }
    if (typeIris.contains(deserTypeIri)) {
      trackTriplesRead(
        subject,
        [
          Triple(
            subject,
            Rdf.type,
            deserTypeIri,
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
        if (deserializer is UnifiedResourceDeserializer<T>) {
          _registerTypeRead(deserializer, term);
          _onDeserializeChildResource(term);
          return deserializer.fromRdfResource(term, context);
        }
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
        if (deserializer is UnifiedResourceDeserializer<T>) {
          _registerTypeRead(deserializer, term);
          _onDeserializeChildResource(term);
          return deserializer.fromRdfResource(term, context);
        }
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
    Deserializer<T>? deserializer,
  }) {
    final triples =
        _findTriplesForReading(subject, predicate, trackRead: false);
    //  if we have a matching multi-deserializer, use that one
    MultiObjectsDeserializer<T>? multiDeser = findMultiObjectsDeserializer<T>(
      deserializer,
    );
    if (multiDeser != null) {
      trackTriplesRead(subject, triples);
      return multiDeser.fromRdfObjects(
          triples.map((t) => t.object).toList(), this);
    }

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
    trackTriplesRead(subject, [triples.first]);
    return deserialize<T>(
      rdfObject,
      deserializer: deserializer,
    );
  }

  Iterable<Triple> _findTriplesForReading(
      RdfSubject subject, RdfPredicate predicate,
      {bool trackRead = true}) {
    final readTriples =
        _graph.findTriples(subject: subject, predicate: predicate);

    if (trackRead) {
      trackTriplesRead(subject, readTriples);
    }
    // Hook for tracking deserialization
    return readTriples;
  }

  Iterable<Triple> _getRemainingTriplesForSubject(RdfSubject subject,
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
      {UnmappedTriplesDeserializer? unmappedTriplesDeserializer,
      bool globalUnmapped = false}) {
    unmappedTriplesDeserializer ??=
        _registry.getUnmappedTriplesDeserializer<T>();

    if (!unmappedTriplesDeserializer.deep && globalUnmapped) {
      throw ArgumentError(
        'Global unmapped triples deserialization is not supported for ${unmappedTriplesDeserializer.runtimeType}. '
        'Use a deep deserializer instead.',
      );
    }
    final triples = globalUnmapped
        ? _graph.withoutTriples(getAllProcessedTriples()).triples
        : _getRemainingTriplesForSubject(subject,
            includeBlankNodes: unmappedTriplesDeserializer.deep);

    trackTriplesRead(subject, triples);

    return unmappedTriplesDeserializer.fromUnmappedTriples(triples);
  }

  @override
  R collect<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    Deserializer<T>? deserializer,
  }) {
    return requireCollection(
        subject,
        predicate,
        ({itemDeserializer}) =>
            UnorderedItemsCollectorDeserializer(collector, itemDeserializer),
        itemDeserializer: deserializer);
  }

  @override
  C requireCollection<C, T>(RdfSubject subject, RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer}) {
    final deserializer = itemDeserializer == null
        ? collectionDeserializerFactory()
        : collectionDeserializerFactory(itemDeserializer: itemDeserializer);

    return require<C>(subject, predicate, deserializer: deserializer);
  }

  @override
  C? optionalCollection<C, T>(RdfSubject subject, RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer}) {
    final deserializer = itemDeserializer == null
        ? collectionDeserializerFactory()
        : collectionDeserializerFactory(itemDeserializer: itemDeserializer);

    return optional<C>(subject, predicate, deserializer: deserializer);
  }

  @override
  T require<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    Deserializer<T>? deserializer,
  }) {
    var result = optional<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      deserializer: deserializer,
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
    Deserializer<T>? deserializer,
  }) =>
      requireCollection<Iterable<T>, T>(
          subject, predicate, UnorderedItemsListDeserializer<T>.new,
          itemDeserializer: deserializer);

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    Deserializer<MapEntry<K, V>>? deserializer,
  }) =>
      collect<MapEntry<K, V>, Map<K, V>>(
        subject,
        predicate,
        (it) => Map<K, V>.fromEntries(it),
        deserializer: deserializer,
      );

  /// Recursively collects blank nodes from triples, maintaining a visited set to prevent cycles
  // @visibleForTesting
  static Set<BlankNodeTerm> getBlankNodeObjectsDeep(
      RdfGraph graph, Iterable<Triple> triples, Set<BlankNodeTerm> visited) {
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
  Iterable<Triple> getTriplesForSubject(RdfSubject subject,
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

  MultiObjectsDeserializer<T>? findMultiObjectsDeserializer<T>(
      Deserializer<T>? deserializer) {
    if (deserializer is MultiObjectsDeserializer<T>) {
      return deserializer;
    }
    if (_registry.hasMultiObjectsDeserializerFor<T>()) {
      return _registry.getMultiObjectsDeserializer<T>();
    }
    return null;
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

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserialization_service.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/node_reader.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';

/// Standard implementation of deserialization context
class DeserializationContextImpl extends DeserializationContext
    implements DeserializationService {
  final RdfGraph _graph;
  final RdfMapperRegistry _registry;

  DeserializationContextImpl({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  }) : _graph = graph,
       _registry = registry;

  /// Implementation of the reader method to support fluent API.
  @override
  NodeReader reader(RdfSubject subject) {
    return NodeReader(subject, this);
  }

  Object deserializeNode(RdfSubject subjectIri, IriTerm typeIri) {
    var context = this;
    switch (subjectIri) {
      case BlankNodeTerm _:
        var ser = _registry.getBlankNodeDeserializerByType(typeIri);
        return ser.fromRdfNode(subjectIri, context);
      case IriTerm _:
        var ser = _registry.getIriNodeDeserializerByType(typeIri);
        return ser.fromRdfNode(subjectIri, context);
    }
  }

  // Hook for the Tracking implementation to track deserialized nodes.
  void _onDeserializeNode(RdfTerm term) {}

  T deserialize<T>(
    RdfTerm term,
    IriTermDeserializer<T>? iriTermDeserializer,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  ) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (iriNodeDeserializer != null ||
            _registry.hasIriNodeDeserializerFor<T>()) {
          var deser =
              iriNodeDeserializer ?? _registry.getIriNodeDeserializer<T>();
          _onDeserializeNode(term);
          return deser.fromRdfNode(term, context);
        }
        var deser =
            iriTermDeserializer ?? _registry.getIriTermDeserializer<T>();
        return deser.fromRdfTerm(term, context);
      case LiteralTerm _:
        return fromLiteralTerm(term, deserializer: literalTermDeserializer);
      case BlankNodeTerm _:
        var deser =
            blankNodeDeserializer ?? _registry.getBlankNodeDeserializer<T>();
        _onDeserializeNode(term);
        return deser.fromRdfNode(term, context);
    }
  }

  T fromLiteralTerm<T>(
    LiteralTerm term, {
    LiteralTermDeserializer<T>? deserializer,
  }) {
    var deser = deserializer ?? _registry.getLiteralTermDeserializer<T>();
    return deser.fromRdfTerm(term, this);
  }

  @override
  T? get<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriTermDeserializer,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    final triples = _graph.findTriples(subject: subject, predicate: predicate);
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
      iriNodeDeserializer,
      literalTermDeserializer,
      blankNodeDeserializer,
    );
  }

  @override
  R getMany<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriTermDeserializer<T>? iriTermDeserializer,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    final triples = _graph.findTriples(subject: subject, predicate: predicate);
    final convertedTriples = triples.map(
      (triple) => deserialize(
        triple.object,
        iriTermDeserializer,
        iriNodeDeserializer,
        literalTermDeserializer,
        blankNodeDeserializer,
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
    IriNodeDeserializer<T>? iriNodeDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    var result = get<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriTermDeserializer: iriTermDeserializer,
      iriNodeDeserializer: iriNodeDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
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
  List<T> getList<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<T>? iriTermDeserializer,
    IriNodeDeserializer<T>? nodeDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) => getMany<T, List<T>>(
    subject,
    predicate,
    (it) => it.toList(),
    iriTermDeserializer: iriTermDeserializer,
    iriNodeDeserializer: nodeDeserializer,
    literalTermDeserializer: literalTermDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    IriNodeDeserializer<MapEntry<K, V>>? iriNodeDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    BlankNodeDeserializer<MapEntry<K, V>>? blankNodeDeserializer,
  }) => getMany<MapEntry<K, V>, Map<K, V>>(
    subject,
    predicate,
    (it) => Map<K, V>.fromEntries(it),
    iriTermDeserializer: iriTermDeserializer,
    iriNodeDeserializer: iriNodeDeserializer,
    literalTermDeserializer: literalTermDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );
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
  void _onDeserializeNode(RdfTerm term) {
    super._onDeserializeNode(term);
    // Track processing of subject terms
    if (term is RdfSubject) {
      _processedSubjects.add(term);
    }
  }

  /// Returns the map of processed subjects with their first processing index
  Set<RdfSubject> getProcessedSubjects() => _processedSubjects;
}

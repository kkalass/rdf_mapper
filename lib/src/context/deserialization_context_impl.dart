import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';

/// Standard implementation of deserialization context
class DeserializationContextImpl extends DeserializationContext {
  final RdfGraph _graph;
  final RdfMapperRegistry _registry;

  DeserializationContextImpl({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  }) : _graph = graph,
       _registry = registry;

  Object deserializeSubjectGraph(RdfSubject subjectIri, IriTerm typeIri) {
    var context = this;
    switch (subjectIri) {
      case BlankNodeTerm _:
        var ser = _registry.getBlankNodeSubjectGraphDeserializerByTypeIri(
          typeIri,
        );
        return ser.fromRdfSubjectGraph(subjectIri, context);
      case IriTerm _:
        var ser = _registry.getIriSubjectGraphDeserializerByTypeIri(typeIri);
        return ser.fromRdfSubjectGraph(subjectIri, context);
    }
  }

  // Hook for the Tracking implementation to track deserialized nodes.
  void _deserializeNode(RdfTerm term) {}

  T deserialize<T>(
    RdfTerm term,
    IriTermDeserializer<T>? iriTermDeserializer,
    IriSubjectGraphDeserializer<T>? subjectGraphDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeSubjectGraphDeserializer,
  ) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (subjectGraphDeserializer != null ||
            _registry.hasIriSubjectGraphDeserializerFor<T>()) {
          var deser =
              subjectGraphDeserializer ??
              _registry.getIriSubjectGraphDeserializer<T>();
          _deserializeNode(term);
          return deser.fromRdfSubjectGraph(term, context);
        }
        var deser =
            iriTermDeserializer ?? _registry.getIriTermDeserializer<T>();
        return deser.fromRdfTerm(term, context);
      case LiteralTerm _:
        var deser =
            literalTermDeserializer ??
            _registry.getLiteralTermDeserializer<T>();
        return deser.fromRdfTerm(term, context);
      case BlankNodeTerm _:
        var deser =
            blankNodeSubjectGraphDeserializer ??
            _registry.getBlankNodeSubjectGraphDeserializer<T>();
        _deserializeNode(term);
        return deser.fromRdfSubjectGraph(term, context);
    }
  }

  @override
  T? get<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriTermDeserializer,
    IriSubjectGraphDeserializer<T>? iriSubjectGraphDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeSubjectGraphDeserializer,
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
      iriSubjectGraphDeserializer,
      literalTermDeserializer,
      blankNodeSubjectGraphDeserializer,
    );
  }

  @override
  R getMany<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriTermDeserializer<T>? iriTermDeserializer,
    IriSubjectGraphDeserializer<T>? iriSubjectGraphDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeSubjectGraphDeserializer,
  }) {
    final triples = _graph.findTriples(subject: subject, predicate: predicate);
    final convertedTriples = triples.map(
      (triple) => deserialize(
        triple.object,
        iriTermDeserializer,
        iriSubjectGraphDeserializer,
        literalTermDeserializer,
        blankNodeSubjectGraphDeserializer,
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
    IriSubjectGraphDeserializer<T>? iriSubjectGraphDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeSubjectGraphDeserializer,
  }) {
    var result = get<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriTermDeserializer: iriTermDeserializer,
      iriSubjectGraphDeserializer: iriSubjectGraphDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeSubjectGraphDeserializer: blankNodeSubjectGraphDeserializer,
    );
    if (result == null) {
      throw PropertyValueNotFoundException(
        subject: subject,
        predicate: predicate,
      );
    }
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
  void _deserializeNode(RdfTerm term) {
    super._deserializeNode(term);
    // Track processing of subject terms
    if (term is RdfSubject) {
      _processedSubjects.add(term);
    }
  }

  /// Returns the map of processed subjects with their first processing index
  Set<RdfSubject> getProcessedSubjects() => _processedSubjects;
}

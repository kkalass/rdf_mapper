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

  Object deserializeSubject(RdfSubject subjectIri, IriTerm typeIri) {
    var context = this;
    switch (subjectIri) {
      case BlankNodeTerm _:
        var ser = _registry.getBlankNodeDeserializerByTypeIri(typeIri);
        return ser.fromRdfNode(subjectIri, context);
      case IriTerm _:
        var ser = _registry.getIriNodeDeserializerByTypeIri(typeIri);
        return ser.fromRdfNode(subjectIri, context);
    }
  }

  // Hook for the Tracking implementation to track deserialized nodes.
  void _deserializeNode(RdfTerm term) {}

  T deserialize<T>(
    RdfTerm term,
    IriTermDeserializer<T>? iriDeserializer,
    IriSubjectGraphDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeDeserializer,
  ) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (subjectDeserializer != null ||
            _registry.hasIriNodeDeserializerFor<T>()) {
          var ser =
              subjectDeserializer ?? _registry.getIriNodeDeserializer<T>();
          _deserializeNode(term);
          return ser.fromRdfNode(term, context);
        }
        var ser = iriDeserializer ?? _registry.getIriTermDeserializer<T>();
        return ser.fromRdfTerm(term, context);
      case LiteralTerm _:
        var ser =
            literalDeserializer ?? _registry.getLiteralTermDeserializer<T>();
        return ser.fromRdfTerm(term, context);
      case BlankNodeTerm _:
        var ser =
            blankNodeDeserializer ?? _registry.getBlankNodeDeserializer<T>();
        _deserializeNode(term);
        return ser.fromRdfNode(term, context);
    }
  }

  @override
  T? get<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriDeserializer,
    IriSubjectGraphDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeDeserializer,
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
      iriDeserializer,
      subjectDeserializer,
      literalDeserializer,
      blankNodeDeserializer,
    );
  }

  @override
  R getMany<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriTermDeserializer<T>? iriDeserializer,
    IriSubjectGraphDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeDeserializer,
  }) {
    final triples = _graph.findTriples(subject: subject, predicate: predicate);
    final convertedTriples = triples.map(
      (triple) => deserialize(
        triple.object,
        iriDeserializer,
        subjectDeserializer,
        literalDeserializer,
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
    IriTermDeserializer<T>? iriDeserializer,
    IriSubjectGraphDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeSubjectGraphDeserializer<T>? blankNodeDeserializer,
  }) {
    var result = get<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriDeserializer: iriDeserializer,
      subjectDeserializer: subjectDeserializer,
      literalDeserializer: literalDeserializer,
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

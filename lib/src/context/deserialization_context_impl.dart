import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';

class DeserializationContextImpl extends DeserializationContext {
  final RdfGraph _graph;
  final RdfMapperRegistry _registry;

  DeserializationContextImpl({
    required RdfGraph graph,
    required RdfMapperRegistry registry,
  }) : _graph = graph,
       _registry = registry;

  Object deserializeSubject(IriTerm subjectIri, IriTerm typeIri) {
    var context = this;
    var ser = _registry.getSubjectDeserializerByTypeIri(typeIri);
    return ser.fromRdfTerm(subjectIri, context);
  }

  T deserialize<T>(
    RdfTerm term,
    IriTermDeserializer<T>? iriDeserializer,
    SubjectDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeTermDeserializer<T>? blankNodeDeserializer,
  ) {
    var context = this;
    switch (term) {
      case IriTerm _:
        if (subjectDeserializer != null ||
            _registry.hasSubjectDeserializerFor<T>()) {
          var ser =
              subjectDeserializer ?? _registry.getSubjectDeserializer<T>();
          return ser.fromRdfTerm(term, context);
        }
        var ser = iriDeserializer ?? _registry.getIriTermDeserializer<T>();
        return ser.fromRdfTerm(term, context);
      case LiteralTerm _:
        var ser =
            literalDeserializer ?? _registry.getLiteralTermDeserializer<T>();
        return ser.fromRdfTerm(term, context);
      case BlankNodeTerm _:
        var ser =
            blankNodeDeserializer ??
            _registry.getBlankNodeTermDeserializer<T>();
        return ser.fromRdfTerm(term, context);
    }
  }

  @override
  T? get<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriDeserializer,
    SubjectDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeTermDeserializer<T>? blankNodeDeserializer,
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
    SubjectDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeTermDeserializer<T>? blankNodeDeserializer,
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
    SubjectDeserializer<T>? subjectDeserializer,
    LiteralTermDeserializer<T>? literalDeserializer,
    BlankNodeTermDeserializer<T>? blankNodeDeserializer,
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

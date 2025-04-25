import 'package:logging/logging.dart';
import 'package:rdf_core/constants/rdf_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/rdf_literal_term_serializer.dart';
import 'package:rdf_mapper/rdf_mapper_registry.dart';
import 'package:rdf_mapper/rdf_subject_serializer.dart';
import 'package:rdf_mapper/serialization_context.dart';

final _log = Logger("rdf_orm.serialization");

class SerializationContextImpl extends SerializationContext {
  final RdfMapperRegistry _registry;

  SerializationContextImpl({required RdfMapperRegistry registry})
    : _registry = registry;

  @override
  List<Triple> childSubject<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfSubjectSerializer<T>? serializer,
  }) {
    var ser = (serializer ?? _registry.getSubjectSerializer<T>());

    var (childIri, childTriples) = ser.toRdfSubject(
      instance,
      this,
      parentSubject: subject,
    );

    // Check if a type triple already exists for the child
    final hasTypeTriple = childTriples.any(
      (triple) =>
          triple.subject == childIri &&
          triple.predicate == RdfConstants.typeIri,
    );

    if (hasTypeTriple) {
      _log.fine(
        'Mapper for ${T.toString()} already provided a type triple. '
        'Skipping automatic type triple addition.',
      );
    }

    return [
      // Add rdf:type for the child only if not already present
      if (!hasTypeTriple) constant(childIri, RdfConstants.typeIri, ser.typeIri),
      ...childTriples,
      // connect the parent to the child
      constant(subject, predicate, childIri),
    ];
  }

  @override
  Triple constant(
    RdfSubject subject,
    RdfPredicate predicate,
    RdfObject object,
  ) => Triple(subject, predicate, object);

  @override
  Triple iri<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfIriTermSerializer<T>? serializer,
  }) {
    var term = (serializer ?? _registry.getIriSerializer<T>()).toIriTerm(
      instance,
      this,
    );
    return Triple(subject, predicate, term);
  }

  @override
  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfLiteralTermSerializer<T>? serializer,
  }) {
    var term = (serializer ?? _registry.getLiteralSerializer<T>())
        .toLiteralTerm(instance, this);
    return Triple(subject, predicate, term);
  }

  @override
  (RdfSubject, List<Triple>) subject<T>(
    T instance, {
    RdfSubjectSerializer<T>? serializer,
  }) {
    var ser = (serializer ?? _registry.getSubjectSerializer<T>());
    var (iri, triples) = ser.toRdfSubject(instance, this);

    // Check if a type triple already exists
    final hasTypeTriple = triples.any(
      (triple) =>
          triple.subject == iri && triple.predicate == RdfConstants.typeIri,
    );

    if (hasTypeTriple) {
      // Check if the type is correct
      final typeTriple = triples.firstWhere(
        (triple) =>
            triple.subject == iri && triple.predicate == RdfConstants.typeIri,
      );

      if (typeTriple.object != ser.typeIri) {
        _log.warning(
          'Mapper for ${T.toString()} provided a type triple with different type than '
          'declared in typeIri property. Expected: ${ser.typeIri}, '
          'but found: ${typeTriple.object}',
        );
      } else {
        _log.fine(
          'Mapper for ${T.toString()} already provided a type triple. '
          'Skipping automatic type triple addition.',
        );
      }
    }

    return (
      iri,
      [
        // Add rdf:type only if not already present in triples
        if (!hasTypeTriple) constant(iri, RdfConstants.typeIri, ser.typeIri),
        ...triples,
      ],
    );
  }
}

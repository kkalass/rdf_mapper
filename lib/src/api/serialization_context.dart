import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/src/serializers/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/src/serializers/rdf_literal_term_serializer.dart';
import 'package:rdf_mapper/src/serializers/rdf_subject_serializer.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Used to delegate complex type mapping to the parent service.
abstract class SerializationContext {
  (RdfSubject, List<Triple>) subject<T>(
    T instance, {
    RdfSubjectSerializer<T>? serializer,
  });

  Triple constant(RdfSubject subject, RdfPredicate predicate, RdfObject object);

  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfLiteralTermSerializer<T>? serializer,
  });

  List<Triple> literals<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    RdfLiteralTermSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .map(
            (item) => literal(subject, predicate, item, serializer: serializer),
          )
          .toList();

  List<Triple> literalList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    RdfLiteralTermSerializer<T>? serializer,
  }) => literals<Iterable<T>, T>(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  Triple iri<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfIriTermSerializer<T>? serializer,
  });

  List<Triple> iris<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    RdfIriTermSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .map((item) => iri(subject, predicate, item, serializer: serializer))
          .toList();

  List<Triple> iriList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    RdfIriTermSerializer<T>? serializer,
  }) => iris<Iterable<T>, T>(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  List<Triple> childSubject<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    RdfSubjectSerializer<T>? serializer,
  });

  List<Triple> childSubjects<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A p1) toIterable,
    A instance, {
    RdfSubjectSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .expand<Triple>(
            (item) =>
                childSubject(subject, predicate, item, serializer: serializer),
          )
          .toList();

  List<Triple> childSubjectList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    RdfSubjectSerializer<T>? serializer,
  }) => childSubjects(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  List<Triple> childSubjectMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance,
    RdfSubjectSerializer<MapEntry<K, V>> entrySerializer,
  ) => childSubjects<Map<K, V>, MapEntry<K, V>>(
    subject,
    predicate,
    (it) => it.entries,
    instance,
    serializer: entrySerializer,
  );
}

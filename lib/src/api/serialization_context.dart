import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Used to delegate complex type mapping to the parent service.
abstract class SerializationContext {
  (RdfSubject, List<Triple>) subjectGraph<T>(
    T instance, {
    SubjectGraphSerializer<T>? serializer,
  });

  Triple constant(RdfSubject subject, RdfPredicate predicate, RdfObject object);

  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    LiteralTermSerializer<T>? serializer,
  });

  List<Triple> literals<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? serializer,
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
    LiteralTermSerializer<T>? serializer,
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
    IriTermSerializer<T>? serializer,
  });

  List<Triple> iris<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    IriTermSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .map((item) => iri(subject, predicate, item, serializer: serializer))
          .toList();

  List<Triple> iriList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    IriTermSerializer<T>? serializer,
  }) => iris<Iterable<T>, T>(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  List<Triple> childSubjectGraph<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    SubjectGraphSerializer<T>? serializer,
  });

  List<Triple> childSubjectGraphs<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A p1) toIterable,
    A instance, {
    SubjectGraphSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .expand<Triple>(
            (item) => childSubjectGraph(
              subject,
              predicate,
              item,
              serializer: serializer,
            ),
          )
          .toList();

  List<Triple> childSubjectGraphList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    SubjectGraphSerializer<T>? serializer,
  }) => childSubjectGraphs(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  List<Triple> childSubjectGraphMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance,
    SubjectGraphSerializer<MapEntry<K, V>> entrySerializer,
  ) => childSubjectGraphs<Map<K, V>, MapEntry<K, V>>(
    subject,
    predicate,
    (it) => it.entries,
    instance,
    serializer: entrySerializer,
  );
}

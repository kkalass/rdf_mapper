import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/serializers/iri_term_serializer.dart';
import 'package:rdf_mapper/src/serializers/literal_term_serializer.dart';
import 'package:rdf_mapper/src/serializers/subject_serializer.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Used to delegate complex type mapping to the parent service.
abstract class SerializationContext {
  (RdfSubject, List<Triple>) subject<T>(
    T instance, {
    SubjectSerializer<T>? serializer,
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

  List<Triple> childSubject<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    SubjectSerializer<T>? serializer,
  });

  List<Triple> childSubjects<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A p1) toIterable,
    A instance, {
    SubjectSerializer<T>? serializer,
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
    SubjectSerializer<T>? serializer,
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
    SubjectSerializer<MapEntry<K, V>> entrySerializer,
  ) => childSubjects<Map<K, V>, MapEntry<K, V>>(
    subject,
    predicate,
    (it) => it.entries,
    instance,
    serializer: entrySerializer,
  );
}

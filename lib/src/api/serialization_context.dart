import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Used to delegate complex type mapping to the parent service.
abstract class SerializationContext {
  List<Triple> node<T>(T instance, {NodeSerializer<T>? serializer});

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

  List<Triple> childNode<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    NodeSerializer<T>? serializer,
  });

  List<Triple> childNodes<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A p1) toIterable,
    A instance, {
    NodeSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .expand<Triple>(
            (item) =>
                childNode(subject, predicate, item, serializer: serializer),
          )
          .toList();

  List<Triple> childNodeList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    NodeSerializer<T>? serializer,
  }) => childNodes(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  List<Triple> childNodeMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance,
    NodeSerializer<MapEntry<K, V>> entrySerializer,
  ) => childNodes<Map<K, V>, MapEntry<K, V>>(
    subject,
    predicate,
    (it) => it.entries,
    instance,
    serializer: entrySerializer,
  );
}

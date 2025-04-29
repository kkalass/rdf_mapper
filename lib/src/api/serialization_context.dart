import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/node_builder.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Used to delegate complex type mapping to the parent service.
///
/// FIXME: KK - remove all but nodeBuilder
abstract class SerializationContext {
  /// Creates a builder for fluent RDF node construction.
  ///
  /// @param subject The subject for the node
  /// @param serializer Optional serializer for the node type
  /// @return A NodeBuilder instance for fluent API
  NodeBuilder<S, T> nodeBuilder<S extends RdfSubject, T>(S subject);

  /// Serializes an object to an RDF node.
  ///
  /// @param instance The object to serialize
  /// @param serializer Optional serializer for the object type
  /// @return A tuple with the subject and generated triples
  List<Triple> node<T>(T instance, {NodeSerializer<T>? serializer});

  /// Creates a triple with a constant object.
  Triple constant(RdfSubject subject, RdfPredicate predicate, RdfObject object);

  /// Creates a triple with a literal object.
  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    LiteralTermSerializer<T>? serializer,
  });

  /// Creates triples for multiple literal objects derived from a source object.
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

  /// Creates triples for a collection of literal objects.
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

  /// Creates a triple with an IRI object.
  Triple iri<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    IriTermSerializer<T>? serializer,
  });

  /// Creates triples for multiple IRI objects derived from a source object.
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

  /// Creates triples for a collection of IRI objects.
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

  /// Creates triples for a child node linked to this subject.
  List<Triple> childNode<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    NodeSerializer<T>? serializer,
  });

  /// Creates triples for multiple child nodes derived from a source object.
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

  /// Creates triples for a collection of child nodes.
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

  /// Creates triples for a map of child nodes.
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

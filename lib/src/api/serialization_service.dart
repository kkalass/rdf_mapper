import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Core service for RDF serialization operations.
///
/// This service encapsulates the low-level operations needed during RDF serialization.
/// It provides the foundation for both direct serialization and the Builder API.
abstract class SerializationService {
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
  });

  /// Creates triples for a collection of literal objects.
  List<Triple> literalList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    LiteralTermSerializer<T>? serializer,
  });

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
  });

  /// Creates triples for a collection of IRI objects.
  List<Triple> iriList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    IriTermSerializer<T>? serializer,
  });

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
  });

  /// Creates triples for a collection of child nodes.
  List<Triple> childNodeList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    NodeSerializer<T>? serializer,
  });

  /// Creates triples for a map of child nodes.
  List<Triple> childNodeMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance,
    NodeSerializer<MapEntry<K, V>> entrySerializer,
  );

  /// Serializes an object to an RDF node.
  ///
  /// @param instance The object to serialize
  /// @param serializer Optional serializer for the object type

  List<Triple> node<T>(T instance, {NodeSerializer<T>? serializer});
}

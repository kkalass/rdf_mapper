import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Core service for RDF serialization operations.
///
/// This service encapsulates the low-level operations needed during RDF serialization.
/// It provides the foundation for both direct serialization and the Builder API.
abstract class SerializationService {
  List<Triple> value<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  });

  List<Triple> valuesFromSource<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  });

  List<Triple> values<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  });

  /// Creates triples for a map of child nodes.
  List<Triple> valueMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance, {
    LiteralTermSerializer<MapEntry<K, V>>? literalTermSerializer,
    IriTermSerializer<MapEntry<K, V>>? iriTermSerializer,
    ResourceSerializer<MapEntry<K, V>>? resourceSerializer,
  });

  /// Serializes an object to a RDF resource.
  ///
  /// @param instance The object to serialize
  /// @param serializer Optional serializer for the object type

  List<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer});
}

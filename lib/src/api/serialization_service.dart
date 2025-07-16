import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';

/// Core service for RDF serialization operations.
///
/// This service encapsulates the low-level operations needed during RDF serialization.
/// It provides the foundation for both direct serialization and the Builder API.
abstract class SerializationService {
  Iterable<Triple> value<T>(
      RdfSubject subject, RdfPredicate predicate, T instance,
      {Serializer<T>? serializer});

  Iterable<Triple> valuesFromSource<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    Serializer<T>? serializer,
  });

  Iterable<Triple> values<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    Serializer<T>? serializer,
  });

  /// Creates triples for a map of child nodes.
  Iterable<Triple> valueMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance, {
    Serializer<MapEntry<K, V>>? serializer,
  });

  /// Serializes an object to a RDF resource.
  ///
  /// @param instance The object to serialize
  /// @param serializer Optional serializer for the object type

  Iterable<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer});

  Iterable<Triple> unmappedTriples<T>(RdfSubject subject, T value,
      {UnmappedTriplesSerializer<T>? unmappedTriplesSerializer});

  Iterable<Triple> collection<C, T>(
      RdfSubject subject,
      RdfPredicate predicate,
      C collection,
      CollectionSerializerFactory<C, T> collectionSerializerFactory,
      {Serializer<T>? itemSerializer});
}

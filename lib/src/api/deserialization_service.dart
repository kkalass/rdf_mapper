import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';

/// Core service for RDF deserialization operations.
///
/// This service encapsulates the low-level operations needed during RDF deserialization.
/// It provides the foundation for both direct deserialization and the Reader API.
///
/// The service defines methods to access and convert RDF property values:
/// * [require] for mandatory properties that must exist
/// * [optional] for properties that may not exist
/// * [getValues] for collecting multiple values as a list
/// * [getMap] for collecting values as a map
/// * [collect] for custom processing of multiple values
abstract class DeserializationService {
  /// Gets a required property value from the RDF graph
  ///
  /// In RDF, we have triples of "subject", "predicate", "object".
  /// This method retrieves the object value for the given subject-predicate pair
  /// and throws an exception if the value cannot be found.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [enforceSingleValue] If true, throws an exception when multiple values exist
  /// * [deserializer] Optional custom deserializer
  ///
  /// Returns the property value converted to the requested type.
  ///
  /// Throws [PropertyValueNotFoundException] if the property doesn't exist.
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T require<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    Deserializer<T>? deserializer,
  });

  /// Gets an optional property value from the RDF graph
  ///
  /// Similar to [require], but returns null if the property is not found
  /// instead of throwing an exception.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [enforceSingleValue] If true, throws an exception when multiple values exist
  /// * [deserializer] Optional custom deserializer
  ///
  /// Returns the property value converted to the requested type, or null if not found.
  ///
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T? optional<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    Deserializer<T>? deserializer,
  });

  /// Gets multiple property values and collects them with a custom collector function
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [collector] A function to process the collected values
  /// * [deserializer] Optional custom deserializer
  ///
  /// Returns the result of the collector function.
  R collect<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    Deserializer<T>? deserializer,
  });

  /// Gets a list of property values
  ///
  /// Convenience method that collects multiple property values into a List.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI for the properties to read
  /// * [deserializer] Optional custom deserializer
  ///
  /// Returns a list of property values converted to the requested type.
  Iterable<T> getValues<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    Deserializer<T>? deserializer,
  });

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [deserializer] Optional custom deserializer for MapEntry values
  ///
  /// Returns a map constructed from the property values.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    Deserializer<MapEntry<K, V>>? deserializer,
  });

  T getUnmapped<T>(RdfSubject subject,
      {UnmappedTriplesDeserializer? unmappedTriplesDeserializer,
      bool globalUnmapped = false});

  /// Retrieves values from an RDF collection, using a provided collection deserializer.
  ///
  /// [collectionDeserializerFactory] is a factory function that provides an
  /// instance of [UnifiedResourceDeserializer] for the specific collection type [C] and item type [T].
  ///
  /// For example, to deserialize an `rdf:List` into a `List<Chapter>`:
  /// `reader.requireCollection<List<Chapter>, Chapter>(SchemaBook.hasPart, RdfListCollectionDeserializer.new)`
  C requireCollection<C, T>(RdfSubject subject, RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer});
  C? optionalCollection<C, T>(RdfSubject subject, RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer});
}

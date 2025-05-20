import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

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
  /// * [globalResourceDeserializer] Optional custom deserializer for IRI nodes
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for blank nodes
  ///
  /// Returns the property value converted to the requested type.
  ///
  /// Throws [PropertyValueNotFoundException] if the property doesn't exist.
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T require<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  });

  /// Gets an optional property value from the RDF graph
  ///
  /// Similar to [require], but returns null if the property is not found
  /// instead of throwing an exception.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [enforceSingleValue] If true, throws an exception when multiple values exist
  /// * [globalResourceDeserializer] Optional custom deserializer for IRI nodes
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for blank nodes
  ///
  /// Returns the property value converted to the requested type, or null if not found.
  ///
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T? optional<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  });

  /// Gets multiple property values and collects them with a custom collector function
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [collector] A function to process the collected values
  /// * [globalResourceDeserializer] Optional custom deserializer for IRI nodes
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for blank nodes
  ///
  /// Returns the result of the collector function.
  R collect<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  });

  /// Gets a list of property values
  ///
  /// Convenience method that collects multiple property values into a List.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI for the properties to read
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [globalResourceDeserializer] Optional custom deserializer for IRI nodes (renamed from globalResourceDeserializer for backward compatibility)
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for blank nodes
  ///
  /// Returns a list of property values converted to the requested type.
  Iterable<T> getValues<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<T>? iriTermDeserializer,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  });

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  ///
  /// * [subject] The subject IRI of the object we are working with
  /// * [predicate] The predicate IRI of the property
  /// * [globalResourceDeserializer] Optional custom deserializer for IRI nodes containing MapEntry values
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms containing MapEntry values
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms containing MapEntry values
  /// * [localResourceDeserializer] Optional custom deserializer for blank nodes containing MapEntry values
  ///
  /// Returns a map constructed from the property values.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    GlobalResourceDeserializer<MapEntry<K, V>>? globalResourceDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    LocalResourceDeserializer<MapEntry<K, V>>? localResourceDeserializer,
  });
}

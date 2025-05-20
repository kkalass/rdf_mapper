import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_service.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';

/// Reader for fluent RDF resource deserialization.
///
/// The ResourceReader provides a convenient fluent API for extracting data from RDF resources
/// during deserialization. It simplifies the process of reading properties from a graph
/// by maintaining the current subject context and offering methods to retrieve and
/// convert RDF property values to Dart objects.
///
/// Key features:
/// * Fluent API for accessing properties of RDF subjects
/// * Type-safe conversion of RDF values to Dart objects
/// * Support for required and optional property access
/// * Helper methods for collections and complex structures
/// * Consistent error handling for missing or invalid data
///
/// Basic example:
/// ```dart
/// final reader = context.reader(subject);
/// final title = reader.require<String>(dc.title);
/// final author = reader.require<String>(dc.creator);
/// final description = reader.optional<String>(dc.description); // Optional
/// ```
///
/// More complex example with nested structures:
/// ```dart
/// final reader = context.reader(subject);
/// final name = reader.require<String>(foaf.name);
/// final age = reader.require<int>(foaf.age);
/// final address = reader.require<Address>(foaf.address);
/// final friends = reader.getList<Person>(foaf.knows);
/// ```
class ResourceReader {
  final RdfSubject _subject;
  final DeserializationService _service;

  /// Creates a new ResourceReader for the fluent API.
  ///
  /// This constructor is typically not called directly. Instead, create a
  /// reader through the [DeserializationContext.reader] method.
  ///
  /// * [_subject] The RDF subject to read properties from
  /// * [_service] The deserialization service for converting RDF to objects
  ResourceReader(this._subject, this._service);

  /// Gets a required property value from the RDF graph.
  ///
  /// Use this method when a property must exist for the object to be valid.
  /// If the property cannot be found or if multiple values are found when only
  /// one is expected, an exception will be thrown.
  ///
  /// Example:
  /// ```dart
  /// final title = reader.require<String>(dc.title);
  /// final author = reader.require<Person>(dc.creator);
  /// ```
  ///
  /// * [predicate] The predicate IRI for the property to read
  /// * [enforceSingleValue] If true, throws an exception when multiple values exist
  /// * [globalResourceDeserializer] Optional custom deserializer for global resources (identifiable by [IriTerm])
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for local resources (identifiable by [BlankNodeTerm] only)
  ///
  /// Returns the property value converted to the requested type.
  ///
  /// Throws [PropertyValueNotFoundException] if the property doesn't exist.
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T require<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    return _service.require<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      globalResourceDeserializer: globalResourceDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
  }

  /// Gets an optional property value from the RDF graph.
  ///
  /// Use this method for properties that might not exist in the graph.
  /// If the property is not found, null is returned. If multiple values are found
  /// when only one is expected, an exception will be thrown (if enforceSingleValue is true).
  ///
  /// Example:
  /// ```dart
  /// final description = reader.optional<String>(dc.description);
  /// final publishDate = reader.optional<DateTime>(dc.date);
  /// ```
  ///
  /// * [predicate] The predicate IRI for the property to read
  /// * [enforceSingleValue] If true, throws an exception when multiple values exist
  /// * [globalResourceDeserializer] Optional custom deserializer for global resources (identifiable by [IriTerm])
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for local resources (identifiable by [BlankNodeTerm] only)
  ///
  /// Returns the property value converted to the requested type, or null if not found.
  ///
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T? optional<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    return _service.optional<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      globalResourceDeserializer: globalResourceDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
  }

  /// Gets multiple property values as a list.
  ///
  /// Use this method for properties that may have multiple values, such as
  /// tags, categories, related resources, or other collections. Returns an
  /// empty list if no values are found.
  ///
  /// Example:
  /// ```dart
  /// final tags = reader.getList<String>(dc.subject);
  /// final authors = reader.getList<Person>(dc.creator);
  /// ```
  ///
  /// * [predicate] The predicate IRI for the properties to read
  /// * [globalResourceDeserializer] Optional custom deserializer for global resources (identifiable by [IriTerm])
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for local resources (identifiable by [BlankNodeTerm] only)
  ///
  /// Returns an iterable of property values converted to the requested type.
  Iterable<T> getValues<T>(
    RdfPredicate predicate, {
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    return _service.getValues<T>(
      _subject,
      predicate,
      globalResourceDeserializer: globalResourceDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
  }

  /// Gets multiple property values as a map.
  ///
  /// Use this method to read properties that represent key-value pairs, where
  /// each property value is deserialized into a MapEntry. This is useful for
  /// properties that represent dictionaries or associative data.
  ///
  /// Example:
  /// ```dart
  /// final translations = reader.getMap<String, String>(schema.translation);
  /// final metadata = reader.getMap<String, Object>(dc.metadata);
  /// ```
  ///
  /// * [predicate] The predicate IRI for the properties to read
  /// * [globalResourceDeserializer] Optional custom deserializer for global resources (identifiable by [IriTerm])
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for local resources (identifiable by [BlankNodeTerm] only)
  ///
  /// Returns a map constructed from the property values.
  Map<K, V> getMap<K, V>(
    RdfPredicate predicate, {
    GlobalResourceDeserializer<MapEntry<K, V>>? globalResourceDeserializer,
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    LocalResourceDeserializer<MapEntry<K, V>>? localResourceDeserializer,
  }) {
    return _service.getMap<K, V>(
      _subject,
      predicate,
      globalResourceDeserializer: globalResourceDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
  }

  /// Gets multiple property values and processes them with a custom collector function.
  ///
  /// This advanced method allows customized collection and transformation of multiple
  /// property values. The collector function receives all deserialized values and can
  /// transform them into any result type.
  ///
  /// Example for calculating an average:
  /// ```dart
  /// final avgScore = reader.collect<double, double>(
  ///   schema.rating,
  ///   (scores) => scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length
  /// );
  /// ```
  ///
  /// * [predicate] The predicate IRI for the properties to read
  /// * [collector] A function to process the collected values
  /// * [globalResourceDeserializer] Optional custom deserializer for global resources (identifiable by [IriTerm])
  /// * [iriTermDeserializer] Optional custom deserializer for IRI terms
  /// * [literalTermDeserializer] Optional custom deserializer for literal terms
  /// * [localResourceDeserializer] Optional custom deserializer for local resources (identifiable by [BlankNodeTerm] only)
  ///
  /// Returns the result of the collector function.
  R collect<T, R>(
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    GlobalResourceDeserializer<T>? globalResourceDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    LocalResourceDeserializer<T>? localResourceDeserializer,
  }) {
    return _service.collect<T, R>(
      _subject,
      predicate,
      collector,
      globalResourceDeserializer: globalResourceDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      localResourceDeserializer: localResourceDeserializer,
    );
  }
}

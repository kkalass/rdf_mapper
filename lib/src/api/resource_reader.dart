import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_service.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Reader for fluent RDF node deserialization.
///
/// The ResourceReader provides a convenient fluent API for extracting data from RDF nodes
/// during deserialization. It simplifies the process of reading properties from a graph
/// by maintaining the current subject context and offering methods to retrieve and
/// convert RDF property values to Dart objects.
///
/// Key features:
/// - Fluent API for accessing properties of RDF subjects
/// - Type-safe conversion of RDF values to Dart objects
/// - Support for required and optional property access
/// - Helper methods for collections and complex structures
/// - Consistent error handling for missing or invalid data
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
  /// @param subject The RDF subject to read properties from
  /// @param service The deserialization service for converting RDF to objects
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
  /// @param predicate The predicate IRI for the property to read
  /// @param enforceSingleValue If true, throws an exception when multiple values exist
  /// @param deserializers Optional custom deserializers to use for conversion
  /// @return The property value converted to the requested type
  /// @throws PropertyValueNotFoundException if the property doesn't exist
  /// @throws TooManyPropertyValuesException if multiple values exist and enforceSingleValue is true
  T require<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _service.require<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriNodeDeserializer: iriNodeDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
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
  /// @param predicate The predicate IRI for the property to read
  /// @param enforceSingleValue If true, throws an exception when multiple values exist
  /// @param deserializers Optional custom deserializers to use for conversion
  /// @return The property value converted to the requested type, or null if not found
  /// @throws TooManyPropertyValuesException if multiple values exist and enforceSingleValue is true
  T? optional<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _service.optional<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      iriNodeDeserializer: iriNodeDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
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
  /// @param predicate The predicate IRI for the properties to read
  /// @param deserializers Optional custom deserializers to use for conversion
  /// @return A list of property values converted to the requested type
  List<T> getList<T>(
    RdfPredicate predicate, {
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _service.getList<T>(
      _subject,
      predicate,
      nodeDeserializer: iriNodeDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
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
  /// @param predicate The predicate IRI for the properties to read
  /// @param deserializers Optional custom deserializers to use for conversion
  /// @return A map constructed from the property values
  Map<K, V> getMap<K, V>(
    RdfPredicate predicate, {
    IriNodeDeserializer<MapEntry<K, V>>? iriNodeDeserializer,
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    BlankNodeDeserializer<MapEntry<K, V>>? blankNodeDeserializer,
  }) {
    return _service.getMap<K, V>(
      _subject,
      predicate,
      iriNodeDeserializer: iriNodeDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
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
  /// @param predicate The predicate IRI for the properties to read
  /// @param collector A function to process the collected values
  /// @param deserializers Optional custom deserializers to use for conversion
  /// @return The result of the collector function
  R collect<T, R>(
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _service.collect<T, R>(
      _subject,
      predicate,
      collector,
      iriNodeDeserializer: iriNodeDeserializer,
      iriTermDeserializer: iriTermDeserializer,
      literalTermDeserializer: literalTermDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
    );
  }
}

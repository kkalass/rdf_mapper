import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Reader for fluent RDF node deserialization.
///
/// Simplifies reading values from an RDF graph by maintaining the subject context.
///
/// ```dart
/// final reader = context.reader(subject);
/// final title = reader.require<String>(titlePredicate);
/// final author = reader.require<String>(authorPredicate);
/// final chapters = reader.getList<Chapter>(chapterPredicate);
/// ```
class NodeReader {
  final RdfSubject _subject;
  final DeserializationContext _context;

  /// Creates a new NodeReader for the fluent API.
  ///
  /// @param subject The RDF subject to read properties from
  /// @param context The deserialization context
  NodeReader(this._subject, this._context);

  /// Gets a required property value from the RDF graph.
  ///
  /// Throws an exception if the property cannot be found.
  ///
  /// @param predicate The predicate for the property
  /// @param enforceSingleValue If true, will throw an exception if there is more than one value
  /// @return The property value
  T require<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _context.require<T>(
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
  /// Returns null if the property is not found.
  ///
  /// @param predicate The predicate for the property
  /// @param enforceSingleValue If true, will throw an exception if there is more than one value
  /// @return The property value or null
  T? get<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _context.get<T>(
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
  /// @param predicate The predicate for the properties
  /// @return A list of property values
  List<T> getList<T>(
    RdfPredicate predicate, {
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _context.getList<T>(
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
  /// @param predicate The predicate for the properties
  /// @return A map constructed from the property values
  Map<K, V> getMap<K, V>(
    RdfPredicate predicate, {
    IriNodeDeserializer<MapEntry<K, V>>? iriNodeDeserializer,
    IriTermDeserializer<MapEntry<K, V>>? iriTermDeserializer,
    LiteralTermDeserializer<MapEntry<K, V>>? literalTermDeserializer,
    BlankNodeDeserializer<MapEntry<K, V>>? blankNodeDeserializer,
  }) {
    return _context.getMap<K, V>(
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
  /// @param predicate The predicate for the properties
  /// @param collector A function to process the collected values
  /// @return The result of the collector function
  R getMany<T, R>(
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    IriNodeDeserializer<T>? iriNodeDeserializer,
    IriTermDeserializer<T>? iriTermDeserializer,
    LiteralTermDeserializer<T>? literalTermDeserializer,
    BlankNodeDeserializer<T>? blankNodeDeserializer,
  }) {
    return _context.getMany<T, R>(
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

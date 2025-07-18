import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Mixin providing serialization functionality for unordered collections.
///
/// This mixin encapsulates the common logic for converting collections to RDF objects
/// using the multi-objects approach. It serializes each collection element to RDF
/// terms and collects both the resulting objects and any additional triples.
///
/// **Multi-Objects Approach**: Creates multiple RDF triples with the same predicate:
/// ```turtle
/// <subject> <predicate> "first element" .
/// <subject> <predicate> "second elementgit" .
/// <subject> <predicate> "third element" .
/// ```
///
/// **Performance Benefits**: More efficient than RDF Lists for large collections
/// as it avoids linked-list structures and enables parallel processing.
///
/// **Type Parameters**:
/// - `T`: The element type within the collection
abstract mixin class UnorderedItemsSerializerMixin<T> {
  /// Serializes a collection of items to RDF objects and triples.
  ///
  /// **Parameters**:
  /// - [values]: The collection of items to serialize
  /// - [context]: The serialization context for resolving mappers
  /// - [itemSerializer]: Optional serializer for individual items
  ///
  /// **Returns**: A tuple containing:
  /// - `Iterable<RdfObject>`: The serialized RDF objects (terms)
  /// - `Iterable<Triple>`: Additional triples generated during serialization
  ///
  /// **Process**:
  /// 1. Serializes each item in the collection using the provided serializer or registry
  /// 2. Collects all resulting RDF objects and triples
  /// 3. Returns the flattened results for multi-objects processing
  (Iterable<RdfObject>, Iterable<Triple>) buildRdfObjects(Iterable<T> values,
      SerializationContext context, Serializer<T>? itemSerializer) {
    final rdfObjects = values
        .map((v) => context.serialize(v, serializer: itemSerializer))
        .toList();
    return (
      rdfObjects.expand((r) => r.$1).cast<RdfObject>(),
      rdfObjects.expand((r) => r.$2)
    );
  }
}

/// Mixin providing deserialization functionality for unordered collections.
///
/// This mixin encapsulates the common logic for converting RDF objects back to
/// collections using the multi-objects approach. It deserializes each RDF object
/// and collects the results into a collection.
///
/// **Multi-Objects Deserialization**: Processes multiple RDF objects with the same predicate:
/// ```turtle
/// <subject> <predicate> "first element" .
/// <subject> <predicate> "second element" .
/// <subject> <predicate> "third element" .
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the collection
abstract mixin class UnorderedItemsDeserializerMixin<T> {
  /// Deserializes RDF objects to a collection of items.
  ///
  /// **Parameters**:
  /// - [objects]: The RDF objects to deserialize
  /// - [context]: The deserialization context for resolving mappers
  /// - [itemDeserializer]: Optional deserializer for individual items
  ///
  /// **Returns**: An iterable of deserialized items of type `T`
  ///
  /// **Process**:
  /// 1. Iterates through each RDF object
  /// 2. Deserializes each object using the provided deserializer or registry
  /// 3. Returns the collection of deserialized items
  Iterable<T> readRdfObjects(Iterable<RdfObject> objects,
          DeserializationContext context, Deserializer<T>? itemDeserializer) =>
      objects.map(
          (obj) => context.deserialize<T>(obj, deserializer: itemDeserializer));
}

/// Serializer for unordered collections using the multi-objects approach.
///
/// This serializer converts `Iterable<T>` collections to multiple RDF objects,
/// creating one RDF triple per collection element with the same predicate.
/// It's optimized for performance with large collections and provides flat
/// RDF representation without nested structures.
///
/// **Use Cases**:
/// - Large collections where performance is critical
/// - Unordered collections (sets, bags, lists where order doesn't matter)
/// - Simple collections that don't need complex RDF structure
/// - Collections processed by systems that prefer flat representations
/// - You use `Iterable<T>` in dart directly, not a subclass such as `List<T>` or `Set<T>`.
///
/// **Type Parameters**:
/// - `T`: The element type within the iterable
class UnorderedItemsSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<Iterable<T>> {
  final Serializer<T>? _itemSerializer;

  /// Creates a serializer for unordered item collections.
  ///
  /// **Parameters**:
  /// - [_itemSerializer]: Optional serializer for individual items. If not provided,
  ///   item serialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic serializer using registry
  /// final serializer = UnorderedItemsSerializer<String>();
  ///
  /// // Serializer with custom item handling
  /// final personSerializer = UnorderedItemsSerializer<Person>(PersonSerializer());
  /// ```
  UnorderedItemsSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Iterable<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

/// Deserializer for unordered collections using the multi-objects approach.
///
/// This deserializer converts multiple RDF objects with the same predicate back
/// to `Iterable<T>` collections. It processes flat RDF representations and
/// reconstructs the original collection structure.
///
/// **Processing**: Handles multiple triples with the same predicate:
/// ```turtle
/// <subject> <predicate> "first element" .
/// <subject> <predicate> "second element" .
/// <subject> <predicate> "third element" .
/// # Result: Iterable<String> containing ["first element", "second element", "third element"]
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the iterable
class UnorderedItemsDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<Iterable<T>> {
  final Deserializer<T>? _itemDeserializer;

  /// Creates a deserializer for unordered item collections.
  ///
  /// **Parameters**:
  /// - [_itemDeserializer]: Optional deserializer for individual items. If not provided,
  ///   item deserialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic deserializer using registry
  /// final deserializer = UnorderedItemsDeserializer<String>();
  ///
  /// // Deserializer with custom item handling
  /// final personDeserializer = UnorderedItemsDeserializer<Person>(PersonDeserializer());
  /// ```
  UnorderedItemsDeserializer([this._itemDeserializer]);

  @override
  Iterable<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer);
}

/// Collector-based deserializer for transforming multi-objects into custom collection types.
///
/// This deserializer first deserializes multiple RDF objects to an `Iterable<T>`,
/// then applies a collector function to transform the result into a custom type `R`.
/// It's useful for creating specific collection types or applying transformations
/// during deserialization.
///
/// **Common Use Cases**:
/// - Converting to immutable collections
/// - Applying validation or filtering during deserialization
/// - Creating domain-specific collection types
/// - Transforming to specialized data structures
///
/// **Example Usage**:
/// ```dart
/// // Create a Set from multi-objects
/// final setCollector = UnorderedItemsCollectorDeserializer<String, Set<String>>(
///   (items) => items.toSet(),
/// );
///
/// // Create a filtered list
/// final filteredCollector = UnorderedItemsCollectorDeserializer<String, List<String>>(
///   (items) => items.where((s) => s.isNotEmpty).toList(),
/// );
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the collection
/// - `R`: The resulting collection type after applying the collector
class UnorderedItemsCollectorDeserializer<T, R>
    implements MultiObjectsDeserializer<R> {
  final MultiObjectsDeserializer<Iterable<T>> _deserializer;

  /// Function to transform the deserialized iterable into the target type.
  final R Function(Iterable<T>) collector;

  /// Creates a collector-based deserializer.
  ///
  /// **Parameters**:
  /// - [collector]: Function to transform `Iterable<T>` to the target type `R`
  /// - [itemDeserializer]: Optional deserializer for individual items
  ///
  /// **Example**:
  /// ```dart
  /// // Create a deserializer that produces a Set
  /// final deserializer = UnorderedItemsCollectorDeserializer<String, Set<String>>(
  ///   (items) => items.toSet(),
  ///   StringDeserializer(),
  /// );
  /// ```
  UnorderedItemsCollectorDeserializer(this.collector,
      [Deserializer<T>? itemDeserializer])
      : _deserializer = UnorderedItemsDeserializer(itemDeserializer);

  @override
  R fromRdfObjects(
      Iterable<RdfObject> objects, DeserializationContext context) {
    final it = _deserializer.fromRdfObjects(objects, context);
    return collector(it);
  }
}

/// Bidirectional mapper for unordered collections using the multi-objects approach.
///
/// This mapper provides complete serialization and deserialization for `Iterable<T>`
/// collections using the multi-objects approach. It creates flat RDF representations
/// without nested structures, making it ideal for performance-critical applications
/// with large collections.
///
/// **Multi-Objects Approach**:
/// - **Serialization**: Creates multiple triples with the same predicate
/// - **Deserialization**: Processes multiple objects with the same predicate
/// - **Performance**: More efficient than RDF Lists for large collections
/// - **Simplicity**: Flat structure is easier to query and process
///
/// **RDF Representation**:
/// ```turtle
/// <subject> <predicate> "element1" .
/// <subject> <predicate> "element2" .
/// <subject> <predicate> "element3" .
/// ```
///
/// **Usage Example**:
/// ```dart
/// // Register for automatic collection handling
/// registry.registerMultiObjectsMapper<Iterable<String>>(
///   UnorderedItemsMapper<String>()
/// );
///
/// // Use in resource serialization
/// builder.addValues(Schema.tags, article.tags);
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the iterable
class UnorderedItemsMapper<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<Iterable<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  /// Creates a bidirectional mapper for unordered item collections.
  ///
  /// **Parameters**:
  /// - [itemSerializer]: Optional serializer for individual items
  /// - [itemDeserializer]: Optional deserializer for individual items
  ///
  /// If serializer/deserializer are not provided, item handling will be
  /// resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic mapper using registry
  /// final mapper = UnorderedItemsMapper<String>();
  ///
  /// // Mapper with custom item handling
  /// final personMapper = UnorderedItemsMapper<Person>(
  ///   itemSerializer: PersonSerializer(),
  ///   itemDeserializer: PersonDeserializer(),
  /// );
  /// ```
  UnorderedItemsMapper(
      {Serializer<T>? itemSerializer, Deserializer<T>? itemDeserializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Iterable<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  Iterable<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer);
}

/// Serializer for `List<T>` collections using the multi-objects approach.
///
/// This serializer converts `List<T>` collections to multiple RDF objects,
/// creating one RDF triple per list element with the same predicate.
/// While it processes lists, the order information is not preserved in the
/// RDF representation, making it suitable for lists where order is not significant.
///
/// **Use Cases**:
/// - Lists where order doesn't matter semantically
/// - Performance-critical list serialization
/// - Lists that will be processed as sets
/// - Simple list representations without complex structure
///
/// **Type Parameters**:
/// - `T`: The element type within the list
class UnorderedItemsListSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<List<T>> {
  final Serializer<T>? _itemSerializer;

  /// Creates a serializer for list collections.
  ///
  /// **Parameters**:
  /// - [_itemSerializer]: Optional serializer for individual items. If not provided,
  ///   item serialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic serializer using registry
  /// final serializer = UnorderedItemsListSerializer<String>();
  ///
  /// // Serializer with custom item handling
  /// final personSerializer = UnorderedItemsListSerializer<Person>(PersonSerializer());
  /// ```
  UnorderedItemsListSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          List<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

/// Serializer for `Set<T>` collections using the multi-objects approach.
///
/// This serializer converts `Set<T>` collections to multiple RDF objects,
/// creating one RDF triple per set element with the same predicate.
/// It's particularly well-suited for sets since the multi-objects approach
/// naturally represents unordered, unique collections.
///
/// **Perfect Match**: Sets and multi-objects are conceptually aligned:
/// - Both represent unordered collections
/// - Both naturally handle uniqueness
/// - Both avoid complex nested structures
/// - Both support efficient processing
///
/// **Use Cases**:
/// - Tags, categories, or keywords
/// - Unique identifiers or references
/// - Unordered collections without duplicates
/// - Sets that need efficient RDF representation
///
/// **Type Parameters**:
/// - `T`: The element type within the set
class UnorderedItemsSetSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<Set<T>> {
  final Serializer<T>? _itemSerializer;

  /// Creates a serializer for set collections.
  ///
  /// **Parameters**:
  /// - [_itemSerializer]: Optional serializer for individual items. If not provided,
  ///   item serialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic serializer using registry
  /// final serializer = UnorderedItemsSetSerializer<String>();
  ///
  /// // Serializer with custom item handling
  /// final tagSerializer = UnorderedItemsSetSerializer<Tag>(TagSerializer());
  /// ```
  UnorderedItemsSetSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Set<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

/// Deserializer for `List<T>` collections using the multi-objects approach.
///
/// This deserializer converts multiple RDF objects with the same predicate back
/// to `List<T>` collections. While it produces a list, the original order from
/// the RDF representation is not guaranteed to be preserved since the multi-objects
/// approach doesn't encode order information.
///
/// **Order Considerations**:
/// - The resulting list order depends on RDF processing order
/// - For ordered lists, consider using RDF Lists instead
/// - Suitable when list is used as a collection container rather than ordered sequence
///
/// **Use Cases**:
/// - Lists where order doesn't matter semantically
/// - Converting from unordered RDF representations
/// - Collections that will be sorted or processed regardless of order
/// - Lists used as generic collection containers
///
/// **Type Parameters**:
/// - `T`: The element type within the list
class UnorderedItemsListDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<List<T>> {
  /// Optional deserializer for individual items.
  final Deserializer<T>? itemDeserializer;

  /// Creates a deserializer for list collections.
  ///
  /// **Parameters**:
  /// - [itemDeserializer]: Optional deserializer for individual items. If not provided,
  ///   item deserialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic deserializer using registry
  /// final deserializer = UnorderedItemsListDeserializer<String>();
  ///
  /// // Deserializer with custom item handling
  /// final personDeserializer = UnorderedItemsListDeserializer<Person>(
  ///   itemDeserializer: PersonDeserializer(),
  /// );
  /// ```
  UnorderedItemsListDeserializer({this.itemDeserializer});

  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, itemDeserializer).toList();
}

/// Deserializer for `Set<T>` collections using the multi-objects approach.
///
/// This deserializer converts multiple RDF objects with the same predicate back
/// to `Set<T>` collections. It's ideally suited for the multi-objects approach
/// since both sets and multi-objects represent unordered collections with
/// natural uniqueness handling.
///
/// **Perfect Match**: Sets and multi-objects are conceptually aligned:
/// - Both represent unordered collections
/// - Both naturally handle uniqueness (duplicates are automatically removed)
/// - Both avoid complex nested structures
/// - Both support efficient processing and querying
///
/// **Automatic Deduplication**: The `Set` will automatically remove any duplicate
/// values that might appear in the RDF representation.
///
/// **Use Cases**:
/// - Tags, categories, or keywords
/// - Unique identifiers or references
/// - Unordered collections without duplicates
/// - Collections that need efficient membership testing
///
/// **Type Parameters**:
/// - `T`: The element type within the set
class UnorderedItemsSetDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<Set<T>> {
  final Deserializer<T>? _itemDeserializer;

  /// Creates a deserializer for set collections.
  ///
  /// **Parameters**:
  /// - [_itemDeserializer]: Optional deserializer for individual items. If not provided,
  ///   item deserialization will be resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic deserializer using registry
  /// final deserializer = UnorderedItemsSetDeserializer<String>();
  ///
  /// // Deserializer with custom item handling
  /// final tagDeserializer = UnorderedItemsSetDeserializer<Tag>(TagDeserializer());
  /// ```
  UnorderedItemsSetDeserializer([this._itemDeserializer]);

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer).toSet();
}

/// Bidirectional mapper for `List<T>` collections using the multi-objects approach.
///
/// This mapper provides complete serialization and deserialization for `List<T>`
/// collections using the multi-objects approach. While it works with lists,
/// the order information is not preserved in the RDF representation, making it
/// suitable for lists where order is not semantically significant.
///
/// **Order Considerations**:
/// - Serialization: List order is not encoded in RDF
/// - Deserialization: List order depends on RDF processing order
/// - Use RDF Lists if order preservation is required
/// - Suitable for lists used as collection containers
///
/// **Performance Benefits**:
/// - Flat RDF structure for efficient processing
/// - No linked-list overhead like RDF Lists
/// - Suitable for large collections
/// - Easy to query and filter
///
/// **Usage Example**:
/// ```dart
/// // Register for automatic list handling
/// registry.registerMultiObjectsMapper<List<String>>(
///   UnorderedItemsListMapper<String>()
/// );
///
/// // Use in resource serialization
/// builder.addValues(Schema.keywords, article.keywords);
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the list
class UnorderedItemsListMapper<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<List<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  /// Creates a bidirectional mapper for list collections.
  ///
  /// **Parameters**:
  /// - [itemSerializer]: Optional serializer for individual items
  /// - [itemDeserializer]: Optional deserializer for individual items
  ///
  /// If serializer/deserializer are not provided, item handling will be
  /// resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic mapper using registry
  /// final mapper = UnorderedItemsListMapper<String>();
  ///
  /// // Mapper with custom item handling
  /// final personMapper = UnorderedItemsListMapper<Person>(
  ///   itemSerializer: PersonSerializer(),
  ///   itemDeserializer: PersonDeserializer(),
  /// );
  /// ```
  UnorderedItemsListMapper(
      {Serializer<T>? itemSerializer, Deserializer<T>? itemDeserializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          List<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer).toList();
}

/// Bidirectional mapper for `Set<T>` collections using the multi-objects approach.
///
/// This mapper provides complete serialization and deserialization for `Set<T>`
/// collections using the multi-objects approach. It's the ideal mapper for the
/// multi-objects pattern since both sets and multi-objects represent unordered
/// collections with natural uniqueness handling.
///
/// **Perfect Alignment**: Sets and multi-objects are conceptually matched:
/// - Both represent unordered collections
/// - Both naturally handle uniqueness
/// - Both avoid complex nested structures
/// - Both support efficient processing and querying
/// - Both are ideal for tags, categories, and keywords
///
/// **Automatic Deduplication**: The `Set` will automatically remove any duplicate
/// values that might appear in the RDF representation during deserialization.
///
/// **RDF Representation**:
/// ```turtle
/// <subject> <predicate> "tag1" .
/// <subject> <predicate> "tag2" .
/// <subject> <predicate> "tag3" .
/// ```
///
/// **Usage Example**:
/// ```dart
/// // Register for automatic set handling
/// registry.registerMultiObjectsMapper<Set<String>>(
///   UnorderedItemsSetMapper<String>()
/// );
///
/// // Use in resource serialization
/// builder.addValues(Schema.tags, article.tags);
/// ```
///
/// **Type Parameters**:
/// - `T`: The element type within the set
class UnorderedItemsSetMapper<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<Set<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  /// Creates a bidirectional mapper for set collections.
  ///
  /// **Parameters**:
  /// - [itemSerializer]: Optional serializer for individual items
  /// - [itemDeserializer]: Optional deserializer for individual items
  ///
  /// If serializer/deserializer are not provided, item handling will be
  /// resolved through the registry.
  ///
  /// **Example**:
  /// ```dart
  /// // Basic mapper using registry
  /// final mapper = UnorderedItemsSetMapper<String>();
  ///
  /// // Mapper with custom item handling
  /// final tagMapper = UnorderedItemsSetMapper<Tag>(
  ///   itemSerializer: TagSerializer(),
  ///   itemDeserializer: TagDeserializer(),
  /// );
  /// ```
  UnorderedItemsSetMapper(
      {Serializer<T>? itemSerializer, Deserializer<T>? itemDeserializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Set<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer).toSet();
}

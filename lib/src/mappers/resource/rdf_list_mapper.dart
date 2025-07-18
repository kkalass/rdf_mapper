import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_deserializer.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_serializer.dart';

/// Bidirectional mapper for RDF Lists (rdf:List) and Dart `List<T>` collections.
///
/// RDF Lists are ordered collections that use the `rdf:first`/`rdf:rest` linked-list
/// structure, terminated by `rdf:nil`. They preserve element order and are ideal for
/// representing sequences where order is semantically significant.
///
/// **RDF List Structure**: Creates linked-list structures using blank nodes:
/// ```turtle
/// _:list rdf:first "first element" ;
///        rdf:rest _:list2 .
/// _:list2 rdf:first "second element" ;
///         rdf:rest _:list3 .
/// _:list3 rdf:first "third element" ;
///         rdf:rest rdf:nil .
/// ```
///
/// **Primary Usage**: Used with `ResourceBuilder.addRdfList()` and `ResourceReader.requireRdfList()`:
/// ```dart
/// // Serialization within a resource serializer:
/// builder.addRdfList(Schema.chapters, book.chapters);
///
/// // Deserialization within a resource deserializer:
/// final reader = context.reader(subject);
/// final chapters = reader.requireRdfList<String>(Schema.chapters);
/// ```
///
/// **Advanced Usage**: Can be registered for automatic collection handling:
/// ```dart
/// registry.registerMapper<List<Chapter>>(RdfListMapper<Chapter>());
/// ```
///
/// **Element Handling**: Individual list elements are serialized/deserialized using
/// the provided item mapper or registry-based lookup. Supports complex nested objects
/// and maintains strict order during round-trip operations.
///
/// **Performance Considerations**: RDF Lists use linked structures which can impact
/// performance for large collections. Consider using RDF Sequences for better performance
/// with large ordered collections.
///
/// **Type Parameters**:
/// - `T`: The element type within the list (e.g., `String`, `Person`, `Chapter`)
class RdfListMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  /// Creates an RDF list mapper for `List<T>`.
  ///
  /// **Parameters**:
  /// - [itemDeserializer]: Optional deserializer for list elements. If not provided,
  ///   element deserialization will be resolved through the registry.
  /// - [itemSerializer]: Optional serializer for list elements. If not provided,
  ///   element serialization will be resolved through the registry.
  ///
  /// **Example usage**:
  /// ```dart
  /// // Basic mapper using registry for element handling
  /// final stringListMapper = RdfListMapper<String>();
  ///
  /// // Mapper with custom element handling
  /// final personListMapper = RdfListMapper<Person>(
  ///   itemDeserializer: PersonDeserializer(),
  ///   itemSerializer: PersonSerializer(),
  /// );
  /// ```
  RdfListMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfListSerializer(itemSerializer: itemSerializer),
          RdfListDeserializer(itemDeserializer: itemDeserializer),
        );
}

/// Adapting mapper that transforms between custom collection types and RDF Lists.
///
/// This mapper enables mapping between custom collection types and RDF Lists by
/// providing transformation functions. It wraps an [RdfListMapper] and applies
/// the transformations during serialization and deserialization.
///
/// **Use Cases**:
/// - Custom collection implementations that need RDF List representation
/// - Immutable collection types that wrap standard lists
/// - Domain-specific collection types with additional behavior
/// - Collections that need validation or transformation during mapping
///
/// **Example with Custom Collection**:
/// ```dart
/// class ImmutableList<T> {
///   final List<T> _items;
///   const ImmutableList(this._items);
///   List<T> get items => List.unmodifiable(_items);
/// }
///
/// final mapper = AdaptingRdfListMapper<ImmutableList<String>, String>(
///   (immutable) => immutable.items, // to List<T>
///   (list) => ImmutableList(list),   // from List<T>
/// );
/// ```
///
/// **Type Parameters**:
/// - `C`: The custom collection type to be mapped
/// - `T`: The element type within the collection
class AdaptingRdfListMapper<C, T>
    extends AdaptingUnifiedResourceMapper<C, List<T>> {
  /// Creates an adapting RDF list mapper for custom collection type `C`.
  ///
  /// **Parameters**:
  /// - [toWrappedType]: Function to convert from custom type `C` to `List<T>`
  /// - [fromWrappedType]: Function to convert from `List<T>` to custom type `C`
  /// - [itemDeserializer]: Optional deserializer for list elements
  /// - [itemSerializer]: Optional serializer for list elements
  ///
  /// **Example**:
  /// ```dart
  /// final mapper = AdaptingRdfListMapper<MyCollection<String>, String>(
  ///   (collection) => collection.toList(),     // C -> List<T>
  ///   (list) => MyCollection.fromList(list),   // List<T> -> C
  ///   itemDeserializer: StringDeserializer(),
  /// );
  /// ```
  AdaptingRdfListMapper(
      List<T> Function(C) toWrappedType, C Function(List<T>) fromWrappedType,
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfListMapper<T>(
              itemDeserializer: itemDeserializer,
              itemSerializer: itemSerializer),
          toWrappedType,
          fromWrappedType,
        );
}

/// Specialized mapper for RDF Lists and Dart `Iterable<T>` collections.
///
/// This mapper provides a convenient way to map between `Iterable<T>` and RDF Lists
/// without requiring users to work directly with `List<T>`. It automatically handles
/// the conversion between iterables and lists during serialization/deserialization.
///
/// **Primary Usage**: Ideal for APIs that work with iterables but need RDF List representation:
/// ```dart
/// class Book {
///   final Iterable<String> tags;
///   Book(this.tags);
/// }
///
/// // Register the mapper
/// registry.registerMapper<Iterable<String>>(RdfListIterableMapper<String>());
/// ```
///
/// **Conversion Behavior**:
/// - **Serialization**: Converts `Iterable<T>` to `List<T>` for RDF List structure
/// - **Deserialization**: Returns the deserialized `List<T>` as `Iterable<T>`
/// - **Order Preservation**: Maintains element order through the conversion
///
/// **Performance Notes**: The conversion to list during serialization materializes
/// the iterable, so lazy iterables will be fully evaluated.
///
/// **Type Parameters**:
/// - `T`: The element type within the iterable
class RdfListIterableMapper<T> extends AdaptingRdfListMapper<Iterable<T>, T> {
  /// Creates an RDF list mapper for `Iterable<T>`.
  ///
  /// **Parameters**:
  /// - [itemDeserializer]: Optional deserializer for iterable elements
  /// - [itemSerializer]: Optional serializer for iterable elements
  ///
  /// **Example usage**:
  /// ```dart
  /// // Basic mapper using registry for element handling
  /// final iterableMapper = RdfListIterableMapper<String>();
  ///
  /// // Mapper with custom element handling
  /// final personIterableMapper = RdfListIterableMapper<Person>(
  ///   itemDeserializer: PersonDeserializer(),
  ///   itemSerializer: PersonSerializer(),
  /// );
  /// ```
  RdfListIterableMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          (it) => it.toList(),
          (list) => list,
          itemDeserializer: itemDeserializer,
          itemSerializer: itemSerializer,
        );
}

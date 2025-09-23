import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_deserializer.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_serializer.dart';

/// Bidirectional mapper for RDF Sequence (rdf:Seq) containers and Dart `List<T>` collections.
///
/// RDF Sequences are ordered containers that preserve element order using numbered
/// properties (`rdf:_1`, `rdf:_2`, `rdf:_3`, etc.). They are ideal for representing
/// ordered collections where the sequence of elements is semantically significant.
///
/// **RDF Sequence Structure**: Creates containers with numbered properties:
/// ```turtle
/// _:sequence a rdf:Seq ;
///   rdf:_1 "first element" ;
///   rdf:_2 "second element" ;
///   rdf:_3 "third element" .
/// ```
///
/// **Primary Usage**: Used with `ResourceBuilder.addRdfSeq()` and `ResourceReader.requireRdfSeq()`:
/// ```dart
/// // Serialization within a resource serializer:
/// builder.addRdfSeq(Schema.chapters, book.chapters);
///
/// // Deserialization within a resource deserializer:
/// final reader = context.reader(subject);
/// final chapters = reader.requireRdfSeq<String>(Schema.chapters);
/// ```
///
/// **Advanced Usage**: Can be registered for automatic collection handling:
/// ```dart
/// registry.registerMapper<List<Chapter>>(RdfSeqMapper<Chapter>());
/// ```
///
/// **Element Handling**: Individual list elements are serialized/deserialized using
/// the provided item mapper or registry-based lookup. Supports complex nested objects
/// and maintains order consistency during round-trip operations.
///
/// **Type Parameters**:
/// - `T`: The element type within the list (e.g., `String`, `Person`, `Chapter`)
class RdfSeqMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  /// Creates an RDF sequence mapper for `List<T>`.
  ///
  /// [itemMapper] Optional mapper for list elements. If not provided,
  /// element serialization/deserialization will be resolved through the registry.
  ///
  /// Example usage:
  /// ```dart
  /// // Basic mapper using registry for element handling
  /// final stringListMapper = RdfSeqMapper<String>();
  ///
  /// // Mapper with custom element handling
  /// final personListMapper = RdfSeqMapper<Person>(PersonMapper());
  /// ```
  RdfSeqMapper(
      {Deserializer<T>? itemDeserializer,
      Serializer<T>? itemSerializer,
      Mapper<T>? itemMapper,
      IriTermFactory iriTermFactory = IriTerm.validated})
      : super(
          RdfSeqSerializer(itemSerializer: itemSerializer ?? itemMapper),
          RdfSeqDeserializer(itemDeserializer: itemDeserializer ?? itemMapper),
        );
}

/// Bidirectional mapper for RDF Alternative (rdf:Alt) containers and Dart `List<T>` collections.
///
/// RDF Alternatives represent a set of alternative values where typically only one
/// should be chosen. The numbered properties may indicate preference order, with
/// `rdf:_1` being the most preferred alternative.
///
/// **RDF Alternative Structure**: Creates containers with numbered properties:
/// ```turtle
/// _:alternatives a rdf:Alt ;
///   rdf:_1 "English Title" ;
///   rdf:_2 "German Title" ;
///   rdf:_3 "French Title" .
/// ```
///
/// **Primary Usage**: Used with `ResourceBuilder.addRdfAlt()` and `ResourceReader.requireRdfAlt()`:
/// ```dart
/// // Serialization within a resource serializer:
/// builder.addRdfAlt(Schema.title, book.alternativeTitles);
///
/// // Deserialization within a resource deserializer:
/// final reader = context.reader(subject);
/// final titles = reader.requireRdfAlt<String>(Schema.title);
/// ```
///
/// **Use Cases**:
/// - Multiple language versions of content
/// - Alternative formats or representations
/// - Preference-ordered options
/// - Fallback values
///
/// **Element Handling**: Individual elements are serialized/deserialized using
/// the provided item mapper or registry-based lookup. Order is preserved and
/// typically indicates preference.
///
/// **Type Parameters**:
/// - `T`: The element type within the alternatives list (e.g., `String`, `LocalizedText`)
class RdfAltMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  /// Creates an RDF alternative mapper for `List<T>`.
  ///
  /// [itemMapper] Optional mapper for list elements. If not provided,
  /// element serialization/deserialization will be resolved through the registry.
  ///
  /// Example usage:
  /// ```dart
  /// // Basic mapper for alternative strings
  /// final alternativeMapper = RdfAltMapper<String>();
  ///
  /// // Mapper for complex alternative objects
  /// final imageAltMapper = RdfAltMapper<ImageResource>(ImageResourceMapper());
  /// ```
  RdfAltMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfAltSerializer(itemSerializer: itemSerializer),
          RdfAltDeserializer(itemDeserializer: itemDeserializer),
        );
}

/// Bidirectional mapper for RDF Bag (rdf:Bag) containers and Dart `List<T>` collections.
///
/// RDF Bags represent unordered collections where duplicates may be allowed.
/// While the numbered properties (`rdf:_1`, `rdf:_2`, etc.) provide a way to
/// reference individual elements, the order is not semantically significant
/// unlike RDF Sequences.
///
/// **RDF Bag Structure**: Creates containers with numbered properties:
/// ```turtle
/// _:bag a rdf:Bag ;
///   rdf:_1 "element one" ;
///   rdf:_2 "element two" ;
///   rdf:_3 "element three" .
/// ```
///
/// **Primary Usage**: Used with `ResourceBuilder.addRdfBag()` and `ResourceReader.requireRdfBag()`:
/// ```dart
/// // Serialization within a resource serializer:
/// builder.addRdfBag(Schema.keywords, article.tags);
///
/// // Deserialization within a resource deserializer:
/// final reader = context.reader(subject);
/// final tags = reader.requireRdfBag<String>(Schema.keywords);
/// ```
///
/// **Use Cases**:
/// - Collections where order doesn't matter (tags, keywords, categories)
/// - Sets of values with possible duplicates
/// - Unordered lists of related items
/// - Collections that may be processed in any order
///
/// **Element Handling**: Individual elements are serialized/deserialized using
/// the provided item mapper or registry-based lookup. While order is preserved
/// during serialization, consumers should not rely on element order.
///
/// **Type Parameters**:
/// - `T`: The element type within the bag (e.g., `String`, `Tag`, `Category`)
class RdfBagMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  /// Creates an RDF bag mapper for `List<T>`.
  ///
  /// [itemMapper] Optional mapper for list elements. If not provided,
  /// element serialization/deserialization will be resolved through the registry.
  ///
  /// Example usage:
  /// ```dart
  /// // Basic mapper for unordered string collections
  /// final bagMapper = RdfBagMapper<String>();
  ///
  /// // Mapper for complex unordered objects
  /// final tagBagMapper = RdfBagMapper<Tag>(TagMapper());
  /// ```
  RdfBagMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfBagSerializer(itemSerializer: itemSerializer),
          RdfBagDeserializer(itemDeserializer: itemDeserializer),
        );
}

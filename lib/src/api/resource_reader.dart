import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_service.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_deserializer.dart';

/// Reader for fluent RDF resource deserialization.
///
/// The ResourceReader provides a convenient fluent API for extracting data from RDF resources
/// during deserialization. It simplifies the process of reading properties from an RDF graph
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
/// final title = reader.require<String>(Dc.title);
/// final author = reader.require<String>(Dc.creator);
/// final description = reader.optional<String>(Dc.description); // Optional
/// ```
///
/// More complex example with nested structures:
/// ```dart
/// final reader = context.reader(subject);
/// final name = reader.require<String>(Foaf.name);
/// final age = reader.require<int>(Foaf.age);
/// final address = reader.require<Address>(Foaf.address);
/// final friends = reader.getValues<Person>(Foaf.knows);
/// ```
class ResourceReader {
  final RdfSubject _subject;
  final DeserializationService _service;

  /// Creates a new ResourceReader for the fluent API.
  ///
  /// This constructor is typically not called directly. Instead, create a
  /// reader through the [DeserializationContext.reader] method.
  ///
  /// The [_subject] is the RDF subject to read properties from.
  /// The [_service] is the deserialization service for converting RDF to objects.
  ResourceReader(this._subject, this._service);

  /// Gets a required property value from the RDF graph.
  ///
  /// Use this method when a property must exist for the object to be valid.
  /// If the property cannot be found or if multiple values are found when only
  /// one is expected, an exception will be thrown.
  ///
  /// Example:
  /// ```dart
  /// final title = reader.require<String>(Dc.title);
  /// final author = reader.require<Person>(Dc.creator);
  /// ```
  ///
  /// The [predicate] is the predicate IRI for the property to read.
  /// If [enforceSingleValue] is true, throws an exception when multiple values exist.
  /// The optional [deserializer] can be provided for custom deserialization.
  ///
  /// Returns the property value converted to the requested type.
  ///
  /// Throws [PropertyValueNotFoundException] if the property doesn't exist.
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T require<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    Deserializer<T>? deserializer,
  }) {
    return _service.require<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      deserializer: deserializer,
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
  /// final description = reader.optional<String>(Dc.description);
  /// final publishDate = reader.optional<DateTime>(Dc.date);
  /// ```
  ///
  /// The [predicate] is the predicate IRI for the property to read.
  /// If [enforceSingleValue] is true, throws an exception when multiple values exist.
  /// The optional [deserializer] can be provided for custom deserialization.
  ///
  /// Returns the property value converted to the requested type, or null if not found.
  ///
  /// Throws [TooManyPropertyValuesException] if multiple values exist and [enforceSingleValue] is true.
  T? optional<T>(
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    Deserializer<T>? deserializer,
  }) {
    return _service.optional<T>(
      _subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      deserializer: deserializer,
    );
  }

  /// Gets multiple property values as an iterable.
  ///
  /// Use this method for properties that may have multiple values, such as
  /// tags, categories, related resources, or other collections. Returns an
  /// empty iterable if no values are found.
  ///
  /// Example:
  /// ```dart
  /// final tags = reader.getValues<String>(Dc.subject);
  /// final authors = reader.getValues<Person>(Dc.creator);
  /// ```
  ///
  /// The [predicate] is the predicate IRI for the properties to read.
  /// The optional [deserializer] can be provided for custom deserialization.
  ///
  /// Returns an iterable of property values converted to the requested type.
  Iterable<T> getValues<T>(
    RdfPredicate predicate, {
    Deserializer<T>? deserializer,
  }) {
    return _service.getValues<T>(
      _subject,
      predicate,
      deserializer: deserializer,
    );
  }

  /// Retrieves a required collection from an RDF collection using a specialized collection deserializer factory.
  ///
  /// This is an advanced method for handling complex collection types that require
  /// specialized deserialization logic. Unlike [getValues] which handles simple
  /// multi-value properties, this method can deserialize structured collections like RDF lists,
  /// bags, sequences, or other custom collection representations.
  ///
  /// **Required Semantics**: This method enforces that the collection must exist in the RDF graph.
  /// If the predicate is not found or the collection cannot be deserialized, an exception
  /// will be thrown. Use [optionalCollection] if the collection might not exist.
  ///
  /// The collection deserializer factory determines how to interpret the collection structure
  /// in RDF. For example, RDF lists use a specific linked structure with `rdf:first` and
  /// `rdf:rest` predicates that must be traversed to reconstruct the original sequence.
  ///
  /// **Convenience Methods**: For common collection types, prefer the specialized convenience methods:
  /// - Use [requireRdfList] for ordered sequences (RDF Lists with rdf:first/rdf:rest)
  /// - Use [getValues] for simple multi-value properties without collection structure
  ///
  /// **Advanced Collection Types** that require this method:
  /// - **RDF Structure Control**: RDF Bags (rdf:Bag), RDF Sequences (rdf:Seq) with specific vocabulary
  /// - **Custom Dart Types**: Converting to/from custom collection classes (e.g., `ImmutableList<T>`, `OrderedSet<T>`)
  /// - **Third-Party Libraries**: Integration with popular collection libraries (e.g., `built_collection`, `dartz`, `kt_dart`)
  /// - **Domain-Specific Collections**: Specialized structures like trees, graphs, or business-specific containers
  ///
  /// **Extensibility Pattern**: For frequently used required collections, consider creating extension methods:
  /// ```dart
  /// extension MyRequiredCollectionExtensions on ResourceReader {
  ///   ImmutableList<T> requireImmutableList<T>(RdfPredicate predicate) =>
  ///     requireCollection(predicate, ImmutableListDeserializer<T>.new);
  ///
  ///   BuiltSet<T> requireBuiltSet<T>(RdfPredicate predicate) =>
  ///     requireCollection(predicate, BuiltSetDeserializer<T>.new);
  /// }
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Custom Dart types: Use immutable collections (required - will throw if missing)
  /// final immutableAuthors = reader.requireCollection<ImmutableList<Person>, Person>(
  ///   Schema.author,
  ///   ImmutableListDeserializer<Person>.new,
  /// );
  ///
  /// // Third-party library: Use built_collection (required - will throw if missing)
  /// final builtKeywords = reader.requireCollection<BuiltSet<String>, String>(
  ///   Schema.keywords,
  ///   BuiltSetDeserializer<String>.new,
  /// );
  ///
  /// // Prefer convenience method for standard RDF Lists:
  /// final standardList = reader.requireRdfList<Person>(Schema.author);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the collection.
  /// The [collectionDeserializerFactory] creates the appropriate deserializer for the collection type.
  /// The optional [itemDeserializer] can be provided for custom deserialization of collection items.
  ///
  /// Returns the deserialized collection of type [C] containing items of type [T].
  ///
  /// Throws a [PropertyValueNotFoundException] exception if the collection is not found.
  C requireCollection<C, T>(RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer}) {
    return _service.requireCollection<C, T>(
      _subject,
      predicate,
      collectionDeserializerFactory,
      itemDeserializer: itemDeserializer,
    );
  }

  /// Retrieves an optional collection from an RDF collection using a specialized collection deserializer factory.
  ///
  /// This is an advanced method for handling complex collection types that require
  /// specialized deserialization logic. Unlike [getValues] which handles simple multi-value properties,
  /// this method can deserialize structured collections like RDF lists,
  /// bags, sequences, or other custom collection representations.
  ///
  /// **Optional Semantics**: This method allows the collection to be missing from the RDF graph.
  /// If the predicate is not found, null is returned. If the collection exists but cannot be
  /// deserialized, an exception will be thrown. Use [requireCollection] if the collection
  /// must exist in the graph.
  ///
  /// The collection deserializer factory determines how to interpret the collection structure
  /// in RDF. For example, RDF lists use a specific linked structure with `rdf:first` and
  /// `rdf:rest` predicates that must be traversed to reconstruct the original sequence.
  ///
  /// **Convenience Methods**: For common collection types, prefer the specialized convenience methods:
  /// - Use [optionalRdfList] for ordered sequences (RDF Lists with rdf:first/rdf:rest)
  /// - Use [getValues] for simple multi-value properties without collection structure
  ///
  /// **Advanced Collection Types** that require this method:
  /// - **RDF Structure Control**: RDF Bags (rdf:Bag), RDF Sequences (rdf:Seq) with specific vocabulary
  /// - **Custom Dart Types**: Converting to/from custom collection classes (e.g., `ImmutableList<T>`, `OrderedSet<T>`)
  /// - **Third-Party Libraries**: Integration with popular collection libraries (e.g., `built_collection`, `dartz`, `kt_dart`)
  /// - **Domain-Specific Collections**: Specialized structures like trees, graphs, or business-specific containers
  ///
  /// **Extensibility Pattern**: For frequently used optional collections, consider creating extension methods:
  /// ```dart
  /// extension MyOptionalCollectionExtensions on ResourceReader {
  ///   ImmutableList<T>? optionalImmutableList<T>(RdfPredicate predicate) =>
  ///     optionalCollection(predicate, ImmutableListDeserializer<T>.new);
  ///
  ///   BuiltSet<T>? optionalBuiltSet<T>(RdfPredicate predicate) =>
  ///     optionalCollection(predicate, BuiltSetDeserializer<T>.new);
  /// }
  /// ```
  ///
  /// **Pattern for Default Values**: Commonly used with null-coalescing operator for default values:
  /// ```dart
  /// // Provide empty collection as default
  /// final tags = reader.optionalCollection<Set<String>, String>(
  ///   Schema.keywords,
  ///   RdfBagDeserializer<String>.new,
  /// ) ?? <String>{};
  ///
  /// // Provide default immutable collection
  /// final authors = reader.optionalCollection<ImmutableList<Person>, Person>(
  ///   Schema.author,
  ///   ImmutableListDeserializer<Person>.new,
  /// ) ?? ImmutableList<Person>.empty();
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Optional RDF Bag - returns null if not found
  /// final keywords = reader.optionalCollection<Set<String>, String>(
  ///   Schema.keywords,
  ///   RdfBagDeserializer<String>.new,
  /// );
  ///
  /// // Optional custom Dart type with default value
  /// final categories = reader.optionalCollection<ImmutableSet<String>, String>(
  ///   Schema.category,
  ///   ImmutableSetDeserializer<String>.new,
  /// ) ?? ImmutableSet<String>.empty();
  ///
  /// // Optional third-party library collection
  /// final builtTags = reader.optionalCollection<BuiltSet<String>, String>(
  ///   Schema.tag,
  ///   BuiltSetDeserializer<String>.new,
  /// );
  ///
  /// // Prefer convenience method for standard RDF Lists:
  /// final standardList = reader.optionalRdfList<Person>(Schema.author) ?? const [];
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the collection.
  /// The [collectionDeserializerFactory] creates the appropriate deserializer for the collection type.
  /// The optional [itemDeserializer] can be provided for custom deserialization of collection items.
  ///
  /// Returns the deserialized collection of type [C] containing items of type [T], or null if not found.
  ///
  /// Throws an exception if the collection exists but cannot be deserialized.
  C? optionalCollection<C, T>(RdfPredicate predicate,
      CollectionDeserializerFactory<C, T> collectionDeserializerFactory,
      {Deserializer<T>? itemDeserializer}) {
    return _service.optionalCollection<C, T>(
      _subject,
      predicate,
      collectionDeserializerFactory,
      itemDeserializer: itemDeserializer,
    );
  }

  /// Retrieves a required list from an RDF List structure.
  ///
  /// This convenience method deserializes an RDF List (ordered sequence) using the standard
  /// RDF list vocabulary. RDF Lists are represented using a linked structure with
  /// `rdf:first` and `rdf:rest` predicates, terminated by `rdf:nil`.
  ///
  /// **Required Semantics**: This method enforces that the RDF List must exist in the graph.
  /// If the predicate is not found or the list structure is invalid, an exception will be thrown.
  /// Use [optionalRdfList] if the list might not exist.
  ///
  /// RDF Lists preserve the order of items and are suitable for representing ordered
  /// sequences where the position of elements matters. This is different from [getValues]
  /// which treats each triple separately without regard to ordering.
  ///
  /// The RDF structure being deserialized looks like:
  /// ```turtle
  /// :subject :predicate ( :item1 :item2 :item3 ) .
  /// ```
  ///
  /// Which expands from the full linked structure:
  /// ```turtle
  /// :subject :predicate _:list1 .
  /// _:list1 rdf:first :item1 ;
  ///         rdf:rest _:list2 .
  /// _:list2 rdf:first :item2 ;
  ///         rdf:rest _:list3 .
  /// _:list3 rdf:first :item3 ;
  ///         rdf:rest rdf:nil .
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Deserialize a required ordered list of authors (throws if missing)
  /// final authors = reader.requireRdfList<Person>(Schema.author);
  ///
  /// // Deserialize a required list of chapter titles maintaining order (throws if missing)
  /// final chapterTitles = reader.requireRdfList<String>(Schema.hasPart);
  ///
  /// // For optional lists, use optionalRdfList instead:
  /// final optionalTags = reader.optionalRdfList<String>(Schema.tag) ?? const [];
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the list.
  /// The optional [itemDeserializer] can be provided for custom deserialization of list items.
  ///
  /// Returns a [List] containing the deserialized items in their original order.
  ///
  /// Throws an exception if the list is not found or has an invalid structure.
  List<T> requireRdfList<T>(
    RdfPredicate predicate, {
    Deserializer<T>? itemDeserializer,
  }) {
    return requireCollection<List<T>, T>(
      predicate,
      RdfListDeserializer<T>.new,
      itemDeserializer: itemDeserializer,
    );
  }

  /// Retrieves an optional list from an RDF List structure.
  ///
  /// This convenience method deserializes an RDF List (ordered sequence) using the standard
  /// RDF list vocabulary. RDF Lists are represented using a linked structure with
  /// `rdf:first` and `rdf:rest` predicates, terminated by `rdf:nil`.
  ///
  /// **Optional Semantics**: This method allows the RDF List to be missing from the graph.
  /// If the predicate is not found, null is returned. If the list exists but has an invalid
  /// structure, an exception will be thrown. Use [requireRdfList] if the list must exist.
  ///
  /// RDF Lists preserve the order of items and are suitable for representing ordered
  /// sequences where the position of elements matters. This is different from [getValues]
  /// which treats each triple separately without regard to ordering.
  ///
  /// **Pattern for Default Values**: Commonly used with null-coalescing operator for empty list defaults:
  /// ```dart
  /// // Provide empty list as default
  /// final tags = reader.optionalRdfList<String>(Schema.tag) ?? const <String>[];
  ///
  /// // Provide custom default list
  /// final priorities = reader.optionalRdfList<Priority>(Schema.priority) ?? [Priority.normal];
  /// ```
  ///
  /// The RDF structure being deserialized looks like:
  /// ```turtle
  /// :subject :predicate ( :item1 :item2 :item3 ) .
  /// ```
  ///
  /// Which expands from the full linked structure:
  /// ```turtle
  /// :subject :predicate _:list1 .
  /// _:list1 rdf:first :item1 ;
  ///         rdf:rest _:list2 .
  /// _:list2 rdf:first :item2 ;
  ///         rdf:rest _:list3 .
  /// _:list3 rdf:first :item3 ;
  ///         rdf:rest rdf:nil .
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Optional ordered list of authors (returns null if missing)
  /// final authors = reader.optionalRdfList<Person>(Schema.author);
  ///
  /// // Optional list with default empty list
  /// final chapterTitles = reader.optionalRdfList<String>(Schema.hasPart) ?? const [];
  ///
  /// // Optional list with conditional processing
  /// final categories = reader.optionalRdfList<String>(Schema.category);
  /// if (categories != null && categories.isNotEmpty) {
  ///   // Process categories...
  /// }
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the list.
  /// The optional [itemDeserializer] can be provided for custom deserialization of list items.
  ///
  /// Returns a [List] containing the deserialized items in their original order, or null if not found.
  ///
  /// Throws an exception if the list exists but has an invalid structure.
  List<T>? optionalRdfList<T>(
    RdfPredicate predicate, {
    Deserializer<T>? itemDeserializer,
  }) {
    return optionalCollection<List<T>, T>(
      predicate,
      RdfListDeserializer<T>.new,
      itemDeserializer: itemDeserializer,
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
  /// final translations = reader.getMap<String, String>(Schema.translation);
  /// final metadata = reader.getMap<String, Object>(Dc.metadata);
  /// ```
  ///
  /// The [predicate] is the predicate IRI for the properties to read.
  /// The optional [deserializer] can be provided for custom deserialization.
  ///
  /// Returns a map constructed from the property values.
  Map<K, V> getMap<K, V>(
    RdfPredicate predicate, {
    Deserializer<MapEntry<K, V>>? deserializer,
  }) {
    return _service.getMap<K, V>(
      _subject,
      predicate,
      deserializer: deserializer,
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
  ///   Schema.rating,
  ///   (scores) => scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length
  /// );
  /// ```
  ///
  /// The [predicate] is the predicate IRI for the properties to read.
  /// The [collector] is a function to process the collected values.
  /// The optional [deserializer] can be provided for custom deserialization.
  ///
  /// Returns the result of the collector function.
  R collect<T, R>(
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    Deserializer<T>? deserializer,
  }) {
    return _service.collect<T, R>(
      _subject,
      predicate,
      collector,
      deserializer: deserializer,
    );
  }

  /// Returns unmapped RDF triples associated with this subject that haven't been consumed by other reader methods.
  ///
  /// This method is fundamental to lossless mapping, allowing you to capture triples
  /// for this subject that weren't explicitly handled by [require], [optional], or
  /// [getValues] calls. This ensures no data is lost during deserialization, making
  /// complete round-trip operations possible.
  ///
  /// The method collects all remaining triples for the current subject (and optionally
  /// connected blank nodes if [UnmappedTriplesDeserializer.deep] of the unmappedTriplesDeserializer is true) and converts them into the specified type [T] using an
  /// [UnmappedTriplesDeserializer]. The default implementation supports [RdfGraph].
  ///
  /// **Important**: This method should typically be called last in your mapper's
  /// [fromRdfResource] method, after all explicit property mappings have been performed.
  /// This ensures only truly unmapped triples are captured.
  ///
  /// Usage example:
  /// ```dart
  /// @override
  /// Person fromRdfResource(IriTerm subject, DeserializationContext context) {
  ///   final reader = context.reader(subject);
  ///   final name = reader.require<String>(foafName);
  ///   final age = reader.require<int>(foafAge);
  ///
  ///   // Capture any remaining unmapped triples - call this last
  ///   final unmappedGraph = reader.getUnmapped<RdfGraph>();
  ///
  ///   return Person(id: subject.iri, name: name, age: age, unmappedGraph: unmappedGraph);
  /// }
  /// ```
  ///
  /// The optional [unmappedTriplesDeserializer] can be provided for custom deserialization of the unmapped data type.
  ///
  /// Returns the unmapped triples converted to type [T], typically an [RdfGraph].
  T getUnmapped<T>(
      {UnmappedTriplesDeserializer<T>? unmappedTriplesDeserializer}) {
    return _service.getUnmapped(_subject,
        unmappedTriplesDeserializer: unmappedTriplesDeserializer);
  }
}

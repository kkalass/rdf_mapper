import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_serializer.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_serializer.dart';

/// Builder for fluent RDF resource serialization.
///
/// The ResourceBuilder provides a convenient fluent API for constructing RDF resources
/// with their associated triples. It simplifies the process of building complex
/// RDF structures by maintaining the current subject context and offering methods
/// to add various types of predicates and objects.
///
/// This class implements the Builder pattern to enable method chaining, making
/// the code for creating RDF structures more readable and maintainable.
///
/// Key features:
/// - Fluent API for adding properties to RDF subjects
/// - Support for literals, IRIs, and nested resource structures
/// - Conditional methods for handling null or empty values
/// - Type-safe serialization of Dart objects to RDF
///
/// Basic example:
/// ```dart
/// final (subject, triples) = context
///     .resourceBuilder(const IriTerm('http://example.org/resource'))
///     .addValue(Dc.title, 'The Title')
///     .addValue(Dc.creator, 'The Author')
///     .build();
/// ```
///
/// More complex example with nested objects:
/// ```dart
/// final (person, triples) = context
///     .resourceBuilder(const IriTerm('http://example.org/person/1'))
///     .addValue(Foaf.name, 'John Doe')
///     .addValue(Foaf.age, 30)
///     .addValue(Foaf.address, address)
///     .addValues(Foaf.knows, friends)
///     .build();
/// ```
class ResourceBuilder<S extends RdfSubject> {
  final S _subject;
  final List<Iterable<Triple>> _triples;
  final SerializationService _service;

  /// Creates a new ResourceBuilder for the fluent API.
  ///
  /// This constructor is typically not called directly. Instead, create a
  /// builder through the [SerializationContext.resourceBuilder] method.
  ///
  /// The [_subject] is the RDF subject to build properties for.
  /// The [_service] is the serialization service for converting objects to RDF.
  /// The optional [initialTriples] can provide a list of initial triples to include.
  ResourceBuilder(this._subject, this._service,
      {Iterable<Triple>? initialTriples})
      : _triples = <Iterable<Triple>>[initialTriples ?? []];

  /// Adds a single property value to the resource being built.
  ///
  /// This is the fundamental method for adding properties to RDF resources. It converts
  /// the provided value to the appropriate RDF representation and creates triples linking
  /// the current subject to the value via the specified predicate.
  ///
  /// The method handles various value types automatically:
  /// - **Primitives**: Converted to literal terms (strings, numbers, booleans, dates)
  /// - **Objects**: Serialized as linked resources with their own subject IRIs
  /// - **Collections**: May be handled by specialized serializers
  ///
  /// Example usage:
  /// ```dart
  /// builder
  ///   .addValue(Dc.title, 'The Great Gatsby')
  ///   .addValue(Dc.creator, Person(name: 'F. Scott Fitzgerald'))
  ///   .addValue(Schema.datePublished, DateTime(1925, 4, 10));
  /// ```
  ///
  /// The [predicate] is the RDF predicate that defines the relationship.
  /// The [value] is the Dart object to be serialized and linked to the subject.
  /// The optional [serializer] can be provided for custom serialization of the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addValue<V>(RdfPredicate predicate, V value,
      {Serializer<V>? serializer}) {
    _triples.add(
      _service.value(
        _subject,
        predicate,
        value,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds unmapped RDF triples from a previously captured unmapped data structure.
  ///
  /// This method is essential for lossless mapping, allowing you to restore triples
  /// that were captured using [ResourceReader.getUnmapped] during a previous
  /// deserialization operation. This ensures complete round-trip fidelity when
  /// serializing objects that contain unmapped data.
  ///
  /// The [value] parameter should be a data structure containing RDF triples,
  /// typically an [RdfGraph] or a custom type that implements [UnmappedTriplesMapper].
  /// If no [unmappedTriplesSerializer] is provided, the system will attempt to
  /// find a registered mapper for the type of [value].
  ///
  /// Usage example:
  /// ```dart
  /// return context.resourceBuilder(const IriTerm(person.id))
  ///   .addValue(foafName, person.name)
  ///   .addValue(foafAge, person.age)
  ///   .addUnmapped(person.unmappedGraph)  // Restore previously captured data
  ///   .build();
  /// ```
  ///
  /// The [value] is the unmapped data structure containing RDF triples to add.
  /// The optional [unmappedTriplesSerializer] can be provided for custom serialization of the unmapped data type.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addUnmapped<V>(
    V value, {
    UnmappedTriplesSerializer<V>? unmappedTriplesSerializer,
  }) {
    _triples.add(
      _service.unmappedTriples(_subject, value,
          unmappedTriplesSerializer: unmappedTriplesSerializer),
    );
    return this;
  }

  /// Conditionally adds a property value only if it's not null.
  ///
  /// This convenience method provides null-safe property addition, automatically
  /// skipping the addition if the value is null. This is particularly useful when
  /// working with optional properties or data that may be incomplete.
  ///
  /// The method is equivalent to manually checking for null before calling [addValue],
  /// but provides a more fluent and readable API for conditional property addition.
  ///
  /// Example usage:
  /// ```dart
  /// builder
  ///   .addValue(Dc.title, book.title)              // Always add title
  ///   .addValueIfNotNull(Dc.description, book.description)  // Only if description exists
  ///   .addValueIfNotNull(Dc.publisher, book.publisher);     // Only if publisher exists
  /// ```
  ///
  /// The [predicate] is the RDF predicate that defines the relationship.
  /// The [value] is the potentially null Dart object to be serialized.
  /// The optional [serializer] can be provided for custom serialization of the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addValueIfNotNull<V>(RdfPredicate predicate, V? value,
      {Serializer<V>? serializer}) {
    if (value == null) {
      return this;
    }
    return addValue(predicate, value, serializer: serializer);
  }

  /// Adds multiple property values extracted from a source object using a transformation function.
  ///
  /// This advanced method allows for indirect value extraction, where values are obtained
  /// by applying a transformation function to a source object. This is particularly useful
  /// when the source object contains the values in a different structure than needed for RDF.
  ///
  /// The transformation function receives the source instance and must return an iterable
  /// of values that will be individually serialized and added as separate triples with
  /// the same predicate.
  ///
  /// Common use cases:
  /// - Extracting values from nested collections
  /// - Transforming or filtering data during serialization
  /// - Adapting data structures that don't directly match RDF patterns
  ///
  /// Example usage:
  /// ```dart
  /// // Extract email addresses from a person's contact info
  /// builder.addValuesFromSource(
  ///   Schema.email,
  ///   (person) => person.contactInfo.emailAddresses,
  ///   person
  /// );
  ///
  /// // Transform and filter a list of roles
  /// builder.addValuesFromSource(
  ///   Schema.jobTitle,
  ///   (employee) => employee.roles.where((r) => r.isActive).map((r) => r.title),
  ///   employee
  /// );
  /// ```
  ///
  /// The [predicate] is the RDF predicate that defines the relationship.
  /// The [toIterable] is a function that extracts values from the source instance.
  /// The [instance] is the source object to extract values from.
  /// The optional [serializer] can be provided for custom serialization of each extracted value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addValuesFromSource<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    Serializer<T>? serializer,
  }) {
    _triples.add(
      _service.valuesFromSource(_subject, predicate, toIterable, instance,
          serializer: serializer),
    );
    return this;
  }

  /// Adds multiple property values from an iterable collection.
  ///
  /// This method allows adding multiple values for the same predicate in a single call,
  /// creating separate triples for each value. This is useful for properties that can
  /// have multiple values, such as tags, categories, authors, or related resources.
  ///
  /// Each value in the iterable is individually serialized and added as a separate
  /// triple with the same predicate but different objects. This creates a one-to-many
  /// relationship in the RDF graph.
  ///
  /// Example usage:
  /// ```dart
  /// // Add multiple authors to a book
  /// builder.addValues(Dc.creator, [
  ///   Person(name: 'Jane Austen'),
  ///   Person(name: 'Charlotte Brontë')
  /// ]);
  ///
  /// // Add multiple tags
  /// builder.addValues(Schema.keywords, [
  ///   'fiction', 'classic', 'literature'
  /// ]);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that defines the relationship.
  /// The [values] is an iterable collection of values to be added.
  /// The optional [serializer] can be provided for custom serialization of each value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addValues<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    Serializer<V>? serializer,
  }) {
    _triples.add(
      _service.values(
        _subject,
        predicate,
        values,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds a map of key-value pairs as child resources.
  ///
  /// This method is useful for serializing dictionary-like structures where both
  /// the keys and values need to be serialized as part of the RDF graph.
  /// Map entries can be serialized as literals, IRIs, or resources depending on
  /// the serializer provided.
  ///
  /// Examples:
  /// ```dart
  /// // Serializes a metadata dictionary as linked resources
  /// builder.addMap(
  ///   Schema.additionalProperty,
  ///   metadata,
  ///   serializer: MetadataEntrySerializer(),
  /// );
  ///
  /// // Serializes map entries as IRI terms
  /// builder.addMap(
  ///   Schema.sameAs,
  ///   uriMappings,
  ///   serializer: UriMappingSerializer(),
  /// );
  ///
  /// // Serializes map entries as literal terms
  /// builder.addMap(
  ///   Schema.propertyValue,
  ///   keyValuePairs,
  ///   serializer: KeyValueSerializer(),
  /// );
  /// ```
  ///
  /// The [predicate] is the predicate for the relationships.
  /// The [instance] is the map to serialize.
  /// The optional [serializer] can be provided for custom serialization of map entries.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addMap<K, V>(RdfPredicate predicate, Map<K, V> instance,
      {Serializer<MapEntry<K, V>>? serializer}) {
    _triples.add(
      _service.valueMap(
        _subject,
        predicate,
        instance,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds a collection using a specialized collection serializer factory.
  ///
  /// This is an advanced method for handling complex collection types that require
  /// specialized serialization logic. Unlike [addValues] which creates separate triples
  /// for each item, this method can create structured collections like RDF lists,
  /// sets, or other custom collection representations.
  ///
  /// The collection serializer factory determines how the collection structure itself
  /// is represented in RDF. For example, RDF lists use a specific linked structure
  /// with `rdf:first` and `rdf:rest` predicates.
  ///
  /// **Convenience Methods**: For common collection types, prefer the specialized convenience methods:
  /// - Use [addRdfList] for ordered sequences (RDF Lists with rdf:first/rdf:rest)
  /// - Use [addValues] for simple unordered multi-value properties
  ///
  /// **Advanced Collection Types** that require this method:
  /// - **RDF Structure Control**: RDF Bags (rdf:Bag), RDF Sequences (rdf:Seq) with specific vocabulary
  /// - **Custom Dart Types**: Converting from custom collection classes (e.g., `ImmutableList<T>`, `OrderedSet<T>`)
  /// - **Third-Party Libraries**: Integration with popular collection libraries (e.g., `built_collection`, `dartz`, `kt_dart`)
  /// - **Domain-Specific Collections**: Specialized structures like trees, graphs, or business-specific containers
  ///
  /// **Extensibility Pattern**: For frequently used collections, consider creating extension methods:
  /// ```dart
  /// extension MyCollectionExtensions<S extends RdfSubject> on ResourceBuilder<S> {
  ///   ResourceBuilder<S> addImmutableList<T>(RdfPredicate predicate, ImmutableList<T> items) =>
  ///     addCollection(predicate, items, ImmutableListSerializer<T>.new);
  ///
  ///   ResourceBuilder<S> addBuiltSet<T>(RdfPredicate predicate, BuiltSet<T> items) =>
  ///     addCollection(predicate, items, BuiltSetSerializer<T>.new);
  /// }
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // RDF structure control: Create an RDF Bag for unordered collection
  /// builder.addCollection(
  ///   Schema.keywords,
  ///   keywordSet,
  ///   RdfBagSerializer<String>.new,
  /// );
  ///
  /// // Custom Dart types: Serialize immutable collections
  /// builder.addCollection(
  ///   Schema.author,
  ///   immutableAuthorList,
  ///   ImmutableListSerializer<Person>.new,
  /// );
  ///
  /// // Third-party library: Use built_collection
  /// builder.addCollection(
  ///   Schema.keywords,
  ///   builtKeywordSet,
  ///   BuiltSetSerializer<String>.new,
  /// );
  ///
  /// // Prefer convenience method for standard RDF Lists:
  /// builder.addRdfList(Schema.author, standardList);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the collection.
  /// The [collection] is the collection instance to be serialized.
  /// The [collectionSerializerFactory] creates the appropriate serializer for the collection type.
  /// The optional [itemSerializer] can be provided for custom serialization of collection items.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addCollection<C, T>(
    RdfPredicate predicate,
    C collection,
    CollectionSerializerFactory<C, T> collectionSerializerFactory, {
    Serializer<T>? itemSerializer,
  }) {
    _triples.add(
      _service.collection(
          _subject, predicate, collection, collectionSerializerFactory,
          itemSerializer: itemSerializer),
    );
    return this;
  }

  /// Adds a list as an RDF List structure.
  ///
  /// This convenience method creates an RDF List (ordered sequence) using the standard
  /// RDF list vocabulary. RDF Lists are represented using a linked structure with
  /// `rdf:first` and `rdf:rest` predicates, terminated by `rdf:nil`.
  ///
  /// RDF Lists preserve the order of items and are suitable for representing ordered
  /// sequences where the position of elements matters. This is different from [addValues]
  /// which creates separate, unordered triples for each value.
  ///
  /// The generated RDF structure looks like:
  /// ```turtle
  /// :subject :predicate ( :item1 :item2 :item3 ) .
  /// ```
  ///
  /// Which expands to the full linked structure:
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
  /// // Create an ordered list of authors
  /// builder.addRdfList(Schema.author, [
  ///   Person(name: 'First Author'),
  ///   Person(name: 'Second Author'),
  ///   Person(name: 'Third Author')
  /// ]);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the list.
  /// The [values] is the ordered list of items to be serialized.
  /// The optional [itemSerializer] can be provided for custom serialization of list items.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addRdfList<T>(RdfPredicate predicate, List<T> values,
          {Serializer<T>? itemSerializer}) =>
      addCollection<List<T>, T>(
        predicate,
        values,
        RdfListSerializer<T>.new,
        itemSerializer: itemSerializer,
      );

  /// Adds an RDF Sequence (rdf:Seq) to the current resource.
  ///
  /// Creates an ordered RDF container using numbered properties (rdf:_1, rdf:_2, etc.).
  /// RDF Sequences preserve element order and are ideal for collections where
  /// sequence matters, such as chapters, steps, or ranked items.
  ///
  /// The RDF output structure:
  /// ```turtle
  /// :subject :predicate _:seq .
  /// _:seq a rdf:Seq ;
  ///       rdf:_1 :item1 ;
  ///       rdf:_2 :item2 ;
  ///       rdf:_3 :item3 .
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Create an ordered sequence of chapters
  /// builder.addRdfSeq(Schema.hasPart, [
  ///   Chapter(title: 'Chapter 1', number: 1),
  ///   Chapter(title: 'Chapter 2', number: 2),
  ///   Chapter(title: 'Chapter 3', number: 3)
  /// ]);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the sequence.
  /// The [values] is the ordered list of items to be serialized.
  /// The optional [itemSerializer] can be provided for custom serialization of sequence items.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addRdfSeq<T>(RdfPredicate predicate, List<T> values,
          {Serializer<T>? itemSerializer}) =>
      addCollection<List<T>, T>(
        predicate,
        values,
        ({itemSerializer}) =>
            RdfSeqSerializer<T>(itemSerializer: itemSerializer),
        itemSerializer: itemSerializer,
      );

  /// Adds an RDF Alternative (rdf:Alt) to the current resource.
  ///
  /// Creates an RDF container for alternative values using numbered properties.
  /// RDF Alternatives represent a set of alternative values where typically only
  /// one should be chosen, and the order may indicate preference.
  ///
  /// The RDF output structure:
  /// ```turtle
  /// :subject :predicate _:alt .
  /// _:alt a rdf:Alt ;
  ///       rdf:_1 :preferred ;
  ///       rdf:_2 :alternative1 ;
  ///       rdf:_3 :alternative2 .
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Create alternatives for a book title in different languages
  /// builder.addRdfAlt(Schema.name, [
  ///   'The Hobbit',        // Preferred (English)
  ///   'Der Hobbit',        // German alternative
  ///   'Le Hobbit'          // French alternative
  /// ]);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the alternatives.
  /// The [values] is the list of alternative items, with the first being preferred.
  /// The optional [itemSerializer] can be provided for custom serialization of alternative items.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addRdfAlt<T>(RdfPredicate predicate, List<T> values,
          {Serializer<T>? itemSerializer}) =>
      addCollection<List<T>, T>(
        predicate,
        values,
        RdfAltSerializer<T>.new,
        itemSerializer: itemSerializer,
      );

  /// Adds an RDF Bag (rdf:Bag) to the current resource.
  ///
  /// Creates an unordered RDF container using numbered properties.
  /// RDF Bags represent unordered collections where duplicates are allowed
  /// and the numbered properties don't imply any ordering semantics.
  ///
  /// The RDF output structure:
  /// ```turtle
  /// :subject :predicate _:bag .
  /// _:bag a rdf:Bag ;
  ///       rdf:_1 :item1 ;
  ///       rdf:_2 :item2 ;
  ///       rdf:_3 :item3 .
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// // Create an unordered bag of keywords/tags
  /// builder.addRdfBag(Schema.keywords, [
  ///   'fantasy',
  ///   'adventure',
  ///   'fiction',
  ///   'tolkien'
  /// ]);
  /// ```
  ///
  /// The [predicate] is the RDF predicate that links to the bag.
  /// The [values] is the list of items to be included in the unordered bag.
  /// The optional [itemSerializer] can be provided for custom serialization of bag items.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> addRdfBag<T>(RdfPredicate predicate, List<T> values,
          {Serializer<T>? itemSerializer}) =>
      addCollection<List<T>, T>(
        predicate,
        values,
        RdfBagSerializer<T>.new,
        itemSerializer: itemSerializer,
      );

  /// Conditionally applies a transformation to this builder.
  ///
  /// Useful for complex conditional logic that doesn't fit the other conditional methods.
  /// This method allows applying a function to the builder only when a specified condition is true,
  /// making it powerful for creating conditional RDF structures.
  ///
  /// Example:
  /// ```dart
  /// builder.when(
  ///   person.isActive,
  ///   (b) => b.addValue(Schema.status, 'active')
  ///           .addValue(Foaf.member, organization)
  /// );
  /// ```
  ///
  /// The [condition] is the boolean condition to evaluate.
  /// The [action] is the function to apply to the builder when the condition is true.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> when(
    bool condition,
    void Function(ResourceBuilder<S> builder) action,
  ) {
    if (condition) {
      action(this);
    }
    return this;
  }

  /// Builds the resource and returns the subject and list of triples.
  ///
  /// This finalizes the RDF building process and returns both the subject resource
  /// and an unmodifiable list of all the triples that have been created.
  ///
  /// Example:
  /// ```dart
  /// final (person, triples) = builder
  ///   .addValue(Foaf.name, 'John Doe')
  ///   .build();
  /// ```
  ///
  /// Returns a tuple containing the subject and all generated triples.
  (S, Iterable<Triple>) build() {
    return (_subject, _triples.expand((x) => x));
  }
}

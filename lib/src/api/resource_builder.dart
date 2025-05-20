import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

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
///     .resourceBuilder(IriTerm('http://example.org/resource'))
///     .literal(Dc.title, 'The Title')
///     .literal(Dc.creator, 'The Author')
///     .build();
/// ```
///
/// More complex example with nested objects:
/// ```dart
/// final (person, triples) = context
///     .resourceBuilder(IriTerm('http://example.org/person/1'))
///     .literal(Foaf.name, 'John Doe')
///     .literal(Foaf.age, 30)
///     .childResource(Foaf.address, address)
///     .childResources(Foaf.knows, friends)
///     .build();
/// ```
class ResourceBuilder<S extends RdfSubject> {
  final S _subject;
  final List<Triple> _triples;
  final SerializationService _service;

  /// Creates a new ResourceBuilder for the fluent API.
  ///
  /// This constructor is typically not called directly. Instead, create a
  /// builder through the [SerializationContext.resourceBuilder] method.
  ///
  /// Parameters:
  /// - [_subject]: The RDF subject to build properties for.
  /// - [_service]: The serialization service for converting objects to RDF.
  /// - [initialTriples]: Optional list of initial triples to include.
  ResourceBuilder(this._subject, this._service, {List<Triple>? initialTriples})
      : _triples = initialTriples ?? [];

  /// Adds a constant object property to the resource.
  ///
  /// Use this method to add a property with a pre-created RDF term as an object.
  /// Unlike other methods, this one takes a direct RdfObject instance rather than
  /// a value that needs serialization.
  ///
  /// Example:
  /// ```dart
  /// builder.constant(Rdf.type, Foaf.Person);
  /// builder.constant(Dc.format, LiteralTerm('text/html', datatype: Xsd.string));
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [object]: The RDF object term to add directly.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> constant(RdfPredicate predicate, RdfObject object) {
    _triples.add(_service.constant(_subject, predicate, object));
    return this;
  }

  /// Adds multiple literal properties extracted from a source object.
  ///
  /// This method is useful when you need to extract multiple values from a complex object
  /// and add them as separate literal properties.
  ///
  /// Example:
  /// ```dart
  /// // Extracts all tags from a post and adds them as DC:subject properties
  /// builder.literalsFromInstance(Dc.subject, (post) => post.tags, blogPost);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [toIterable]: Function that extracts the values from the source object.
  /// - [instance]: The source object to extract values from.
  /// - [serializer]: Optional custom serializer for the extracted values.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> literalsFromInstance<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? serializer,
  }) {
    _triples.addAll(
      _service.literalsFromInstance(
        _subject,
        predicate,
        toIterable,
        instance,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds multiple IRI properties extracted from a source object.
  ///
  /// This method is useful when you need to extract multiple values from a complex object
  /// and add them as separate IRI references.
  ///
  /// Example:
  /// ```dart
  /// // Extracts all collaborators from a project and adds them as DC:contributor properties
  /// builder.irisFromInstance(Dc.contributor, (project) => project.collaborators, currentProject);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [toIterable]: Function that extracts the values from the source object.
  /// - [instance]: The source object to extract values from.
  /// - [serializer]: Optional custom serializer for the extracted values.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> irisFromInstance<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    IriTermSerializer<T>? serializer,
  }) {
    _triples.addAll(
      _service.irisFromInstance(
        _subject,
        predicate,
        toIterable,
        instance,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds multiple child resources extracted from a source object.
  ///
  /// This method is useful when you need to extract multiple complex objects from a parent object
  /// and serialize each as a separate linked resource.
  ///
  /// Example:
  /// ```dart
  /// // Extracts all chapters from a book and adds them as structured content
  /// builder.childResourcesFromInstance(Schema.hasPart, (book) => book.chapters, currentBook);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [toIterable]: Function that extracts the values from the source object.
  /// - [instance]: The source object to extract values from.
  /// - [serializer]: Optional custom serializer for the extracted values.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResourcesFromInstance<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    ResourceSerializer<T>? serializer,
  }) {
    _triples.addAll(
      _service.childResourcesFromInstance(
        _subject,
        predicate,
        toIterable,
        instance,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds a literal property to the resource.
  ///
  /// Use this method to add a property with a literal value (strings, numbers,
  /// dates, etc.) to the current subject. The value will be serialized to an
  /// RDF literal term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.literal(Dc.title, 'The Title');
  /// builder.literal(Foaf.age, 30);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The value to be serialized as a literal.
  /// - [serializer]: Optional custom serializer for the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> literal<V>(
    RdfPredicate predicate,
    V value, {
    LiteralTermSerializer<V>? serializer,
  }) {
    _triples.add(
      _service.literal(_subject, predicate, value, serializer: serializer),
    );
    return this;
  }

  /// Adds an IRI property to the resource.
  ///
  /// Use this method to add a property with an IRI value (referring to another
  /// resource) to the current subject. The value will be serialized to an
  /// RDF IRI term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.iri(Rdf.type, Foaf.Person);
  /// builder.iri(Dc.relation, document);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The value to be serialized as an IRI.
  /// - [serializer]: Optional custom serializer for the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> iri<V>(
    RdfPredicate predicate,
    V value, {
    IriTermSerializer<V>? serializer,
  }) {
    _triples.add(
      _service.iri(_subject, predicate, value, serializer: serializer),
    );
    return this;
  }

  /// Adds a child resource to this resource.
  ///
  /// Use this method to add a nested object as a property value. The child object
  /// will be serialized to its own set of RDF triples, and connected to this
  /// subject via the specified predicate.
  ///
  /// This is ideal for complex object structures and relationships between entities.
  ///
  /// Example:
  /// ```dart
  /// builder.childResource(Foaf.address, address);
  /// builder.childResource(Schema.author, person);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The object to be serialized as a linked resource.
  /// - [serializer]: Optional custom serializer for the object.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResource<V>(
    RdfPredicate predicate,
    V value, {
    ResourceSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.childResource(_subject, predicate, value,
          serializer: serializer),
    );
    return this;
  }

  /// Adds multiple child resources to this resource.
  ///
  /// Use this method to add a collection of objects as related resources. Each object
  /// in the collection will be serialized to its own set of RDF triples and linked
  /// to the current subject via the specified predicate. Note that in RDF
  /// terms this corresponds to multi-value properties, not to collections or lists.
  ///
  /// Example:
  /// ```dart
  /// builder.childResources(Foaf.knows, friends);
  /// builder.childResources(Schema.author, authors);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationships.
  /// - [values]: The collection of objects to be serialized as linked resources.
  /// - [serializer]: Optional custom serializer for the objects.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResources<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    ResourceSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.childResources(
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
  ///
  /// Example:
  /// ```dart
  /// // Serializes a metadata dictionary as linked resources
  /// builder.childResourceMap(
  ///   Schema.additionalProperty,
  ///   metadata,
  ///   MetadataEntrySerializer(),
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [instance]: The map to serialize.
  /// - [entrySerializer]: The serializer for map entries.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResourceMap<K, V>(
    RdfPredicate predicate,
    Map<K, V> instance,
    ResourceSerializer<MapEntry<K, V>> entrySerializer,
  ) {
    _triples.addAll(
      _service.childResourceMap(_subject, predicate, instance, entrySerializer),
    );
    return this;
  }

  /// Adds multiple literal properties to this resource.
  ///
  /// Use this method to add a collection of literal values (strings, numbers, dates, etc.)
  /// with the same predicate to the current subject. Each value will be serialized to
  /// an RDF literal term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.literals(Dc.subject, ['Science', 'Physics', 'Quantum Mechanics']);
  /// builder.literals(Schema.keywords, tags);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [values]: The collection of values to be serialized as literals.
  /// - [serializer]: Optional custom serializer for the values.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> literals<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    LiteralTermSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.literals(_subject, predicate, values, serializer: serializer),
    );
    return this;
  }

  /// Adds multiple IRI properties to this resource.
  ///
  /// Use this method to add a collection of IRI values (referring to other resources)
  /// with the same predicate to the current subject. Each value will be serialized to
  /// an RDF IRI term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.iris(Owl.sameAs, [otherResourceId1, otherResourceId2]);
  /// builder.iris(Foaf.interest, interests);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate for the relationships.
  /// - [values]: The collection of values to be serialized as IRIs.
  /// - [serializer]: Optional custom serializer for the values.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> iris<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    IriTermSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.iris(_subject, predicate, values, serializer: serializer),
    );
    return this;
  }

  /// Adds a literal property to the resource if the value is not null.
  ///
  /// This is a convenience method that only adds the property if the value exists.
  /// It's particularly useful when working with optional data.
  ///
  /// Example:
  /// ```dart
  /// builder.literalIfNotNull(Dc.description, description);
  /// builder.literalIfNotNull(Schema.alternateName, nickname);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The optional value to be serialized as a literal.
  /// - [serializer]: Optional custom serializer for the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> literalIfNotNull<V>(
    RdfPredicate predicate,
    V? value, {
    LiteralTermSerializer<V>? serializer,
  }) {
    if (value != null) {
      literal(predicate, value, serializer: serializer);
    }
    return this;
  }

  /// Adds an IRI property to the resource if the value is not null.
  ///
  /// This is a convenience method that only adds the property if the value exists.
  /// It's particularly useful when working with optional references to other resources.
  ///
  /// Example:
  /// ```dart
  /// builder.iriIfNotNull(Foaf.homepage, website);
  /// builder.iriIfNotNull(Dc.isPartOf, parentResource);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The optional value to be serialized as an IRI.
  /// - [serializer]: Optional custom serializer for the value.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> iriIfNotNull<V>(
    RdfPredicate predicate,
    V? value, {
    IriTermSerializer<V>? serializer,
  }) {
    if (value != null) {
      iri(predicate, value, serializer: serializer);
    }
    return this;
  }

  /// Adds a child resource to this resource if the value is not null.
  ///
  /// This is a convenience method that only adds the nested object if it exists.
  /// It's particularly useful when working with optional complex properties.
  ///
  /// Example:
  /// ```dart
  /// builder.childResourceIfNotNull(Foaf.address, optionalAddress);
  /// builder.childResourceIfNotNull(Schema.contactPoint, contactInfo);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationship.
  /// - [value]: The optional object to be serialized as a linked resource.
  /// - [serializer]: Optional custom serializer for the object.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResourceIfNotNull<V>(
    RdfPredicate predicate,
    V? value, {
    ResourceSerializer<V>? serializer,
  }) {
    if (value != null) {
      childResource(predicate, value, serializer: serializer);
    }
    return this;
  }

  /// Adds multiple child resources to this resource if the collection is not null and not empty.
  ///
  /// This is a convenience method that only adds the collection of objects if it exists
  /// and contains at least one element. It's particularly useful when working with
  /// optional collections that should be excluded entirely when empty.
  ///
  /// Example:
  /// ```dart
  /// builder.childResourcesIfNotEmpty(Foaf.knows, optionalFriendsList);
  /// builder.childResourcesIfNotEmpty(Schema.author, articleAuthors);
  /// ```
  ///
  /// Parameters:
  /// - [predicate]: The predicate that defines the relationships.
  /// - [values]: The optional collection of objects to be serialized as linked resources.
  /// - [serializer]: Optional custom serializer for the objects.
  ///
  /// Returns this builder for method chaining.
  ResourceBuilder<S> childResourcesIfNotEmpty<V>(
    RdfPredicate predicate,
    Iterable<V>? values, {
    ResourceSerializer<V>? serializer,
  }) {
    if (values != null && values.isNotEmpty) {
      childResources(predicate, values, serializer: serializer);
    }
    return this;
  }

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
  ///   (b) => b.literal(Schema.status, 'active')
  ///          .iri(Foaf.member, organization)
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [condition]: The boolean condition to evaluate.
  /// - [action]: The function to apply to the builder when the condition is true.
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
  ///   .literal(Foaf.name, 'John Doe')
  ///   .build();
  /// ```
  ///
  /// Returns a tuple containing the subject and all generated triples.
  (S, List<Triple>) build() {
    return (_subject, List.unmodifiable(_triples));
  }
}

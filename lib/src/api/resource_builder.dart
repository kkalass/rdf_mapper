import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Builder for fluent RDF node serialization.
///
/// The ResourceBuilder provides a convenient fluent API for constructing RDF nodes
/// with their associated triples. It simplifies the process of building complex
/// RDF structures by maintaining the current subject context and offering methods
/// to add various types of predicates and objects.
///
/// This class implements the Builder pattern to enable method chaining, making
/// the code for creating RDF structures more readable and maintainable.
///
/// Key features:
/// - Fluent API for adding properties to RDF subjects
/// - Support for literals, IRIs, and nested node structures
/// - Conditional methods for handling null or empty values
/// - Type-safe serialization of Dart objects to RDF
///
/// Basic example:
/// ```dart
/// final (subject, triples) = context
///     .resourceBuilder(IriTerm('http://example.org/resource'))
///     .literal(dc.title, 'The Title')
///     .literal(dc.creator, 'The Author')
///     .build();
/// ```
///
/// More complex example with nested objects:
/// ```dart
/// final (person, triples) = context
///     .resourceBuilder(IriTerm('http://example.org/person/1'))
///     .literal(foaf.name, 'John Doe')
///     .literal(foaf.age, 30)
///     .childNode(foaf.address, address)
///     .childNodes(foaf.knows, friends)
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
  /// @param subject The RDF subject to build properties for
  /// @param service The serialization service for converting objects to RDF
  /// @param initialTriples Optional list of initial triples to include
  ResourceBuilder(this._subject, this._service, {List<Triple>? initialTriples})
      : _triples = initialTriples ?? [];

  /// Adds a constant object property to the node.
  ///
  /// Use this method to add a property with a pre-created RDF term as an object.
  /// Unlike other methods, this one takes a direct RdfObject instance rather than
  /// a value that needs serialization.
  ///
  /// Example:
  /// ```dart
  /// builder.constant(rdf.type, foaf.Person);
  /// builder.constant(dc.format, LiteralTerm('text/html', datatype: xsd.string));
  /// ```
  ///
  /// @param predicate The predicate IRI for the property
  /// @param object The RDF object term to add
  /// @return This builder for method chaining
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
  /// // Extracts all tags from a post and adds them as dc:subject properties
  /// builder.literalsFromInstance(dc.subject, (post) => post.tags, blogPost);
  /// ```
  ///
  /// @param predicate The predicate for the properties
  /// @param toIterable A function that extracts the collection of values from the source object
  /// @param instance The source object to extract values from
  /// @param serializer Optional serializer for the value type
  /// @return This builder for method chaining
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
  /// // Extracts all collaborators from a project and adds them as dc:contributor properties
  /// builder.irisFromInstance(dc.contributor, (project) => project.collaborators, currentProject);
  /// ```
  ///
  /// @param predicate The predicate for the properties
  /// @param toIterable A function that extracts the collection of values from the source object
  /// @param instance The source object to extract values from
  /// @param serializer Optional serializer for the value type
  /// @return This builder for method chaining
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

  /// Adds multiple child nodes extracted from a source object.
  ///
  /// This method is useful when you need to extract multiple complex objects from a parent object
  /// and serialize each as a separate linked node.
  ///
  /// Example:
  /// ```dart
  /// // Extracts all chapters from a book and adds them as structured content
  /// builder.childNodesFromInstance(schema.hasPart, (book) => book.chapters, currentBook);
  /// ```
  ///
  /// @param predicate The predicate for the relationships
  /// @param toIterable A function that extracts the collection of objects from the source
  /// @param instance The source object to extract values from
  /// @param serializer Optional serializer for the child node type
  /// @return This builder for method chaining
  ResourceBuilder<S> childNodesFromInstance<A, T>(
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    NodeSerializer<T>? serializer,
  }) {
    _triples.addAll(
      _service.childNodesFromInstance(
        _subject,
        predicate,
        toIterable,
        instance,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds a literal property to the node.
  ///
  /// Use this method to add a property with a literal value (strings, numbers,
  /// dates, etc.) to the current subject. The value will be serialized to an
  /// RDF literal term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.literal(dc.title, 'The Title');
  /// builder.literal(foaf.age, 30);
  /// ```
  ///
  /// @param predicate The predicate IRI for the property
  /// @param value The literal value to add
  /// @param serializer Optional custom serializer for the value type
  /// @return This builder for method chaining
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

  /// Adds an IRI property to the node.
  ///
  /// Use this method to add a property with an IRI value (referring to another
  /// resource) to the current subject. The value will be serialized to an
  /// RDF IRI term using the appropriate serializer.
  ///
  /// Example:
  /// ```dart
  /// builder.iri(rdf.type, foaf.Person);
  /// builder.iri(dc.relation, document);
  /// ```
  ///
  /// @param predicate The predicate IRI for the property
  /// @param value The value to be serialized as an IRI
  /// @param serializer Optional custom serializer for the value type
  /// @return This builder for method chaining
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

  /// Adds a child node to this node.
  ///
  /// Use this method to add a nested object as a property value. The child object
  /// will be serialized to its own set of RDF triples, and connected to this
  /// subject via the specified predicate.
  ///
  /// This is ideal for complex object structures and relationships between entities.
  ///
  /// Example:
  /// ```dart
  /// builder.childNode(foaf.address, address);
  /// builder.childNode(schema.author, person);
  /// ```
  ///
  /// @param predicate The predicate IRI for the relationship
  /// @param value The child node object to serialize
  /// @param serializer Optional custom serializer for the child object type
  /// @return This builder for method chaining
  ResourceBuilder<S> childNode<V>(
    RdfPredicate predicate,
    V value, {
    NodeSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.childNode(_subject, predicate, value, serializer: serializer),
    );
    return this;
  }

  /// Adds multiple child nodes to this node.
  ///
  /// Use this method to add a collection of objects as related nodes. Each object
  /// in the collection will be serialized to its own set of RDF triples and linked
  /// to the current subject via the specified predicate. Note that in RDF
  /// terms this corresponds to multi-value properties, not to collections or lists.
  ///
  /// Example:
  /// ```dart
  /// builder.childNodes(foaf.knows, friends);
  /// builder.childNodes(schema.author, authors);
  /// ```
  ///
  /// @param predicate The predicate for the relationships
  /// @param values The collection of child node values
  /// @param serializer Optional serializer for the child node type
  /// @return This builder for method chaining
  ResourceBuilder<S> childNodes<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    NodeSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.childNodes(
        _subject,
        predicate,
        values,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds a map of key-value pairs as child nodes.
  ///
  /// This method is useful for serializing dictionary-like structures where both
  /// the keys and values need to be serialized as part of the RDF graph.
  ///
  /// Example:
  /// ```dart
  /// // Serializes a metadata dictionary as linked nodes
  /// builder.childNodeMap(
  ///   schema.additionalProperty,
  ///   metadata,
  ///   MetadataEntrySerializer(),
  /// );
  /// ```
  ///
  /// @param predicate The predicate for the relationships
  /// @param instance The map to serialize
  /// @param entrySerializer The serializer for map entries
  /// @return This builder for method chaining
  ResourceBuilder<S> childNodeMap<K, V>(
    RdfPredicate predicate,
    Map<K, V> instance,
    NodeSerializer<MapEntry<K, V>> entrySerializer,
  ) {
    _triples.addAll(
      _service.childNodeMap(_subject, predicate, instance, entrySerializer),
    );
    return this;
  }

  /// Adds multiple literal properties to this node.
  ///
  /// @param predicate The predicate for the properties
  /// @param values The collection of literal values
  /// @param serializer Optional serializer for the value type
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

  /// Adds multiple IRI properties to this node.
  ///
  /// @param predicate The predicate for the properties
  /// @param values The collection of values to be serialized as IRIs
  /// @param serializer Optional serializer for the value type
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

  /// Adds a literal property to the node if the value is not null.
  ///
  /// @param predicate The predicate for the property
  /// @param value The optional literal value
  /// @param serializer Optional serializer for the value type
  /// @return This builder instance for method chaining
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

  /// Adds an IRI property to the node if the value is not null.
  ///
  /// @param predicate The predicate for the property
  /// @param value The optional value to be serialized as an IRI
  /// @param serializer Optional serializer for the value type
  /// @return This builder instance for method chaining
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

  /// Adds a child node to this node if the value is not null.
  ///
  /// @param predicate The predicate for the relationship
  /// @param value The optional child node value
  /// @param serializer Optional serializer for the child node type
  /// @return This builder instance for method chaining
  ResourceBuilder<S> childNodeIfNotNull<V>(
    RdfPredicate predicate,
    V? value, {
    NodeSerializer<V>? serializer,
  }) {
    if (value != null) {
      childNode(predicate, value, serializer: serializer);
    }
    return this;
  }

  /// Adds multiple child nodes to this node if the collection is not null and not empty.
  ///
  /// @param predicate The predicate for the relationships
  /// @param values The optional collection of child node values
  /// @param serializer Optional serializer for the child node type
  /// @return This builder instance for method chaining
  ResourceBuilder<S> childNodesIfNotEmpty<V>(
    RdfPredicate predicate,
    Iterable<V>? values, {
    NodeSerializer<V>? serializer,
  }) {
    if (values != null && values.isNotEmpty) {
      childNodes(predicate, values, serializer: serializer);
    }
    return this;
  }

  /// Conditionally applies a transformation to this builder.
  ///
  /// Useful for complex conditional logic that doesn't fit the other conditional methods.
  ///
  /// @param condition The condition that determines if the action should be applied
  /// @param action The action to apply to the builder if the condition is true
  /// @return This builder instance for method chaining
  ResourceBuilder<S> when(
    bool condition,
    void Function(ResourceBuilder<S> builder) action,
  ) {
    if (condition) {
      action(this);
    }
    return this;
  }

  /// Builds the node and returns the subject and list of triples.
  ///
  /// @return A tuple containing the subject and all generated triples
  (S, List<Triple>) build() {
    return (_subject, List.unmodifiable(_triples));
  }
}

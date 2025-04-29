import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Builder for fluent RDF node serialization.
///
/// Enables creating RDF graphs in a chained API pattern.
///
/// ```dart
/// final (subject, triples) = context
///     .nodeBuilder(IriTerm('http://example.org/resource'))
///     .literal(titlePredicate, 'The Title')
///     .literal(authorPredicate, 'The Author')
///     .build();
/// ```
class NodeBuilder<S extends RdfSubject, T> {
  final S _subject;
  final List<Triple> _triples;
  final SerializationService _service;

  /// Creates a new NodeBuilder for the fluent API.
  ///
  /// @param subject The RDF subject to build properties for
  /// @param context The serialization context
  /// @param initialTriples Optional list of initial triples
  /// @param serializer Optional serializer for the node type
  NodeBuilder(this._subject, this._service, {List<Triple>? initialTriples})
    : _triples = initialTriples ?? [];

  /// Adds a literal property to the node.
  ///
  /// @param predicate The predicate for the property
  /// @param value The literal value
  /// @param serializer Optional serializer for the value type
  NodeBuilder<S, T> literal<V>(
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
  /// @param predicate The predicate for the property
  /// @param value The value to be serialized as an IRI
  /// @param serializer Optional serializer for the value type
  NodeBuilder<S, T> iri<V>(
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
  /// @param predicate The predicate for the relationship
  /// @param value The child node value
  /// @param serializer Optional serializer for the child node type
  NodeBuilder<S, T> childNode<V>(
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
  /// @param predicate The predicate for the relationships
  /// @param values The collection of child node values
  /// @param serializer Optional serializer for the child node type
  NodeBuilder<S, T> childNodeList<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    NodeSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.childNodeList(
        _subject,
        predicate,
        values,
        serializer: serializer,
      ),
    );
    return this;
  }

  /// Adds multiple literal properties to this node.
  ///
  /// @param predicate The predicate for the properties
  /// @param values The collection of literal values
  /// @param serializer Optional serializer for the value type
  NodeBuilder<S, T> literalList<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    LiteralTermSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.literalList(_subject, predicate, values, serializer: serializer),
    );
    return this;
  }

  /// Adds multiple IRI properties to this node.
  ///
  /// @param predicate The predicate for the properties
  /// @param values The collection of values to be serialized as IRIs
  /// @param serializer Optional serializer for the value type
  NodeBuilder<S, T> iriList<V>(
    RdfPredicate predicate,
    Iterable<V> values, {
    IriTermSerializer<V>? serializer,
  }) {
    _triples.addAll(
      _service.iriList(_subject, predicate, values, serializer: serializer),
    );
    return this;
  }

  /// Adds a literal property to the node if the value is not null.
  ///
  /// @param predicate The predicate for the property
  /// @param value The optional literal value
  /// @param serializer Optional serializer for the value type
  /// @return This builder instance for method chaining
  NodeBuilder<S, T> literalIfNotNull<V>(
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
  NodeBuilder<S, T> iriIfNotNull<V>(
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
  NodeBuilder<S, T> childNodeIfNotNull<V>(
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
  NodeBuilder<S, T> childNodeListIfNotEmpty<V>(
    RdfPredicate predicate,
    Iterable<V>? values, {
    NodeSerializer<V>? serializer,
  }) {
    if (values != null && values.isNotEmpty) {
      childNodeList(predicate, values, serializer: serializer);
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
  NodeBuilder<S, T> when(
    bool condition,
    void Function(NodeBuilder<S, T> builder) action,
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

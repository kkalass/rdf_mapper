import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Builder für fluent RDF node serialization.
///
/// Ermöglicht das Erstellen von RDF-Graphen in einer verketteten API.
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
  final SerializationContext _context;

  /// Creates a new NodeBuilder für die fluent API.
  ///
  /// @param subject The RDF subject to build properties for
  /// @param context The serialization context
  /// @param initialTriples Optional list of initial triples
  /// @param serializer Optional serializer for the node type
  NodeBuilder(this._subject, this._context, {List<Triple>? initialTriples})
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
      _context.literal(_subject, predicate, value, serializer: serializer),
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
      _context.iri(_subject, predicate, value, serializer: serializer),
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
      _context.childNode(_subject, predicate, value, serializer: serializer),
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
      _context.childNodeList(
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
      _context.literalList(_subject, predicate, values, serializer: serializer),
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
      _context.iriList(_subject, predicate, values, serializer: serializer),
    );
    return this;
  }

  /// Builds the node and returns the subject and list of triples.
  ///
  /// @return A tuple containing the subject and all generated triples
  (S, List<Triple>) build() {
    return (_subject, List.unmodifiable(_triples));
  }
}

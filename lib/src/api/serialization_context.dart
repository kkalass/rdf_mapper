import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/node_builder.dart';

/// Context for serialization operations in the RDF mapping process.
///
/// The serialization context provides a unified access point to all services and state
/// needed during the conversion of Dart objects to RDF representations. It maintains
/// references to the current graph being built and offers utility methods for serializing
/// complex object structures.
///
/// Key responsibilities:
/// - Track the current state of the serialization process
/// - Prevent infinite recursion by tracking already serialized objects
/// - Provide access to utility methods for creating and manipulating nodes
/// - Enable a consistent environment for serializer implementations
///
/// The context follows the Ambient Context pattern, providing relevant services
/// to serializers without requiring explicit passing of dependencies through
/// deep call hierarchies.
///
/// This abstraction is particularly valuable when serializing complex object graphs
/// that may contain circular references or shared objects.
abstract class SerializationContext {
  /// Creates a builder for fluent RDF node construction.
  ///
  /// The node builder provides a convenient fluent API for constructing RDF nodes
  /// with their associated triples. This is the primary method for creating
  /// structured RDF representations during serialization.
  ///
  /// The builder pattern simplifies the process of adding multiple properties
  /// to a subject, especially when handling complex nested structures.
  ///
  /// Example usage:
  /// ```dart
  /// final builder = context.nodeBuilder(subject);
  /// builder
  ///   .literal(foaf.name, "John Doe")
  ///   .literal(foaf.age, 30)
  ///   .iri(foaf.knows, otherPerson);
  /// ```
  ///
  /// @param subject The subject term (IRI or blank node) for the node
  /// @return A NodeBuilder instance for fluent API construction
  NodeBuilder<S> nodeBuilder<S extends RdfSubject>(S subject);
}

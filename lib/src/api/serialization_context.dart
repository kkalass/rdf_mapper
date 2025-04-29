import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/node_builder.dart';

/// Context for serialization operations
///
/// Provides access to services and state needed during RDF serialization.
/// Acts as a facade for the SerializationService and facilitates the builder pattern.
abstract class SerializationContext {
  /// Creates a builder for fluent RDF node construction.
  ///
  /// @param subject The subject for the node
  /// @param serializer Optional serializer for the node type
  /// @return A NodeBuilder instance for fluent API
  NodeBuilder<S, T> nodeBuilder<S extends RdfSubject, T>(S subject);
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/node_reader.dart';

/// Context for deserialization operations
///
/// Provides access to services and state needed during RDF deserialization.
/// Acts as a facade for the DeserializationService and facilitates the reader pattern.
abstract class DeserializationContext {
  /// Creates a reader for fluent node property access.
  ///
  /// @param subject The subject to read properties from
  /// @return A NodeReader instance for fluent API
  NodeReader reader(RdfSubject subject);
}

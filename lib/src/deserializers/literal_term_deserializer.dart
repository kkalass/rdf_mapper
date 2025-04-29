import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Deserializes an RDF literal term to a Dart object.
///
/// Implementations convert literal terms to specific Dart types,
/// enabling the transformation of RDF literal values into domain objects.
abstract interface class LiteralTermDeserializer<T> implements Deserializer<T> {
  /// Converts a literal term to a value.
  ///
  /// @param term The literal term to convert
  /// @return The resulting value
  T fromRdfTerm(LiteralTerm term, DeserializationContext context);
}

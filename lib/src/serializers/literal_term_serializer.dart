import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Serializes a Dart object to an RDF literal term.
///
/// Implementations convert specific Dart types to literal terms,
/// which are used to represent literal values in RDF graphs.
abstract interface class LiteralTermSerializer<T> implements Serializer<T> {
  /// Converts a value to a literal term.
  ///
  /// @param value The value to convert
  /// @return The resulting literal term
  LiteralTerm toRdfTerm(T value, SerializationContext context);
}

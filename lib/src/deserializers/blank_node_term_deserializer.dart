import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Deserializes an RDF blank node term to a Dart object.
///
/// Implementations convert blank node terms to specific Dart types,
/// enabling the transformation of anonymous RDF resources into domain objects.
abstract interface class BlankNodeTermDeserializer<T>
    implements Deserializer<T> {
  /// Converts a blank node term to a value.
  ///
  /// @param term The blank node term to convert
  /// @param context The deserialization context, providing access to the graph
  /// @return The resulting value
  T fromRdfTerm(BlankNodeTerm term, DeserializationContext context);
}

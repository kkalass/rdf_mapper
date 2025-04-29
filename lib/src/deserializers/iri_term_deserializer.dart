import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Deserializes an RDF IRI term to a Dart object.
///
/// Implementations convert IRI terms to specific Dart types,
/// enabling the transformation of RDF resources into domain objects.
abstract interface class IriTermDeserializer<T> implements Deserializer<T> {
  /// Converts an IRI term to a value.
  ///
  /// @param term The IRI term to convert
  /// @return The resulting value
  T fromRdfTerm(IriTerm term, DeserializationContext context);
}

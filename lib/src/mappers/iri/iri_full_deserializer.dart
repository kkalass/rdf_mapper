import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';

/// Standard deserializer that extracts the full IRI string from an IRI term.
///
/// This is a core deserializer used for converting RDF IRI terms directly to string
/// values containing the complete IRI. This deserializer is pre-registered in the
/// default registry and is used whenever an IRI term needs to be deserialized to a string.
///
/// Example:
/// An IRI term `http://example.org/resource/1` will be deserialized to the string
/// `"http://example.org/resource/1"`.
final class IriFullDeserializer implements IriTermDeserializer<String> {
  const IriFullDeserializer();

  /// Converts an IRI term to its full string representation.
  ///
  /// @param term The IRI term to convert
  /// @param context The deserialization context (unused in this implementation)
  /// @return The complete IRI string
  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.value;
  }
}

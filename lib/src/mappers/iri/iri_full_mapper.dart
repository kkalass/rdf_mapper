import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Standard mapper that converts a string to an IRI term (and back).
///
/// This is a core mapper used for converting string values directly to RDF IRI terms.
/// It treats the input string as a complete IRI. This serializer is pre-registered in the
/// default registry and is used whenever a string needs to be serialized to an IRI term.
///
/// Example:
/// The string `"http://example.org/resource/1"` will be serialized to an IRI term
/// with the same value.
///
/// Note: This serializer assumes that the input string is already a properly formatted IRI.
/// It does not perform any validation or normalization of the IRI.
final class IriFullMapper implements IriTermMapper<String> {
  const IriFullMapper();

  /// Converts a string to an IRI term.
  ///
  /// @param iri The string containing the complete IRI
  /// @param context The serialization context (unused in this implementation)
  /// @return An IRI term with the specified IRI
  @override
  toRdfTerm(String iri, SerializationContext context) {
    return context.createIriTerm(iri);
  }

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

final class UriIriMapper implements IriTermMapper<Uri> {
  const UriIriMapper();

  /// Converts a URI to an IRI term.
  ///
  /// @param uri The URI to convert
  /// @param context The serialization context (unused in this implementation)
  /// @return An IRI term with the specified URI
  @override
  IriTerm toRdfTerm(Uri uri, SerializationContext context) {
    return context.createIriTerm(uri.toString());
  }

  /// Converts an IRI term to its full URI representation.
  ///
  /// @param term The IRI term to convert
  /// @param context The deserialization context (unused in this implementation)
  /// @return The complete URI
  @override
  Uri fromRdfTerm(IriTerm term, DeserializationContext context) {
    return Uri.parse(term.value);
  }
}

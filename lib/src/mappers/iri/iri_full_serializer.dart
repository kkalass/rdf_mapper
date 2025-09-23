import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

/// Standard serializer that converts a string to an IRI term.
///
/// This is a core serializer used for converting string values directly to RDF IRI terms.
/// It treats the input string as a complete IRI. This serializer is pre-registered in the
/// default registry and is used whenever a string needs to be serialized to an IRI term.
///
/// Example:
/// The string `"http://example.org/resource/1"` will be serialized to an IRI term
/// with the same value.
///
/// Note: This serializer assumes that the input string is already a properly formatted IRI.
/// It does not perform any validation or normalization of the IRI.
final class IriFullSerializer implements IriTermSerializer<String> {
  const IriFullSerializer();

  /// Converts a string to an IRI term.
  ///
  /// @param iri The string containing the complete IRI
  /// @param context The serialization context (unused in this implementation)
  /// @return An IRI term with the specified IRI
  @override
  toRdfTerm(String iri, SerializationContext context) {
    return context.createIriTerm(iri);
  }
}

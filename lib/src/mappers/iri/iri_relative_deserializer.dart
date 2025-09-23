import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_core/rdf_core_extend.dart';

/// Deserializer that converts absolute IRI terms to relative IRI strings.
///
/// This deserializer relativizes absolute IRIs against a configured base URI to create
/// relative IRI strings. It's useful when working with documents where IRIs should be
/// expressed relative to a base URI for more compact representation.
///
/// **Important**: This affects only the Dart object representation of IRIs, not the
/// RDF serialization format. RDF always contains absolute IRIs. This deserializer is
/// useful when the same Dart classes are used for both RDF mapping and other formats
/// (JSON, databases, etc.) where compact relative IRIs are preferred.
///
/// Example:
/// With base URI `"http://example.org/base/"`, an IRI term with value
/// `"http://example.org/base/resource/1"` will be deserialized to the relative string
/// `"resource/1"`. An IRI that cannot be relativized (different authority/scheme)
/// will be returned as an absolute IRI string.
///
/// The deserializer uses standard IRI relativization rules.
final class IriRelativeDeserializer implements IriTermDeserializer<String> {
  /// The base URI used for relativizing absolute IRIs.
  final String baseUri;

  const IriRelativeDeserializer(this.baseUri);

  /// Converts an absolute IRI term to a potentially relative IRI string.
  ///
  /// Relativizes the [term]'s IRI against the configured base URI. If the IRI
  /// can be expressed relative to the base URI, returns a relative string;
  /// otherwise returns the absolute IRI string.
  ///
  /// Parameters:
  /// - [term]: The IRI term to convert
  /// - [context]: The deserialization context (unused in this implementation)
  ///
  /// Returns a string containing either a relative or absolute IRI.
  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    return relativizeIri(term.value, baseUri);
  }
}

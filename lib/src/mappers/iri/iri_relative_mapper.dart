import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/rdf_core_extend.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Bidirectional mapper for relative IRI handling between strings and IRI terms.
///
/// This mapper provides both serialization and deserialization for IRIs relative to
/// a configured base URI. During serialization, it resolves relative IRI strings to
/// absolute IRI terms. During deserialization, it relativizes absolute IRI terms
/// back to relative strings when possible.
///
/// **Important**: This affects only the Dart object representation of IRIs, not the
/// RDF serialization format. RDF always contains absolute IRIs. This mapper is useful
/// when the same Dart classes are used for both RDF mapping and other formats
/// (JSON, databases, etc.) where compact relative IRIs are preferred.
///
/// Examples:
/// With base URI `"http://example.org/base/"`:
/// - Serialization: `"resource/1"` → `const IriTerm("http://example.org/base/resource/1")`
/// - Deserialization: `const IriTerm("http://example.org/base/resource/1")` → `"resource/1"`
///
/// This is particularly useful for document-relative IRI references where maintaining
/// the relative structure is important for readability and portability in non-RDF formats.
final class IriRelativeMapper implements IriTermMapper<String> {
  /// The base URI used for resolving relative IRIs and relativizing absolute IRIs.
  final String baseUri;

  const IriRelativeMapper(this.baseUri);

  /// Converts a potentially relative IRI string to an absolute IRI term.
  ///
  /// Resolves the [iri] against the configured base URI to create an absolute
  /// IRI term. If [iri] is already absolute, it remains unchanged.
  ///
  /// Parameters:
  /// - [iri]: The IRI string (relative or absolute) to convert
  /// - [context]: The serialization context (unused in this implementation)
  ///
  /// Returns an [IriTerm] with the resolved absolute IRI.
  @override
  toRdfTerm(String iri, SerializationContext context) {
    return context.createIriTerm(resolveIri(iri, baseUri));
  }

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

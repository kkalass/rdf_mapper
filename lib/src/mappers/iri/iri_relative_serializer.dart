import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/rdf_core_extend.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

/// Serializer that converts relative IRI strings to absolute IRI terms.
///
/// This serializer resolves relative IRIs against a configured base URI to create
/// absolute IRI terms. It's useful when working with documents that contain relative
/// references that need to be resolved to absolute IRIs for RDF serialization.
///
/// **Important**: This affects only the Dart object representation of IRIs, not the
/// RDF serialization format. RDF always contains absolute IRIs. This serializer is
/// useful when the same Dart classes are used for both RDF mapping and other formats
/// (JSON, databases, etc.) where compact relative IRIs are preferred.
///
/// Example:
/// With base URI `"http://example.org/base/"`, the relative string `"resource/1"`
/// will be serialized to an IRI term with value `"http://example.org/base/resource/1"`.
/// An absolute IRI like `"http://other.org/resource"` will remain unchanged.
///
/// The serializer uses standard IRI resolution rules as defined in RFC 3986.
final class IriRelativeSerializer implements IriTermSerializer<String> {
  /// The base URI used for resolving relative IRIs to absolute ones.
  final String baseUri;

  const IriRelativeSerializer(
    this.baseUri,
  );

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
}

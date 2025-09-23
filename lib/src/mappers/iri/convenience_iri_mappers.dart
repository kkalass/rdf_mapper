import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Bidirectional mapper for IRI fragments (the part after #).
///
/// This mapper extracts the fragment from absolute IRIs during deserialization
/// and appends fragments to a base IRI during serialization. Useful for
/// document-relative references, anchor links, or identifier systems based
/// on fragments.
///
/// Examples:
/// With base IRI `"http://example.org/document"`:
/// - Serialization: `"section1"` → `const IriTerm("http://example.org/document#section1")`
/// - Deserialization: `const IriTerm("http://example.org/document#section1")` → `"section1"`
///
/// For IRIs without fragments, deserialization returns an empty string.
final class FragmentIriTermMapper implements IriTermMapper<String> {
  /// The base IRI to which fragments are appended during serialization.
  final String baseIri;

  /// Creates a mapper for IRI fragments with the specified base IRI.
  ///
  /// [baseIri] The base IRI used for fragment resolution (should not end with #)
  const FragmentIriTermMapper(this.baseIri);

  @override
  IriTerm toRdfTerm(String fragment, SerializationContext context) {
    final cleanBase = baseIri.endsWith('#')
        ? baseIri.substring(0, baseIri.length - 1)
        : baseIri;
    return context.createIriTerm('$cleanBase#$fragment');
  }

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    final iri = term.value;
    final fragmentIndex = iri.lastIndexOf('#');

    if (fragmentIndex == -1) {
      return ''; // No fragment found
    }

    return iri.substring(fragmentIndex + 1);
  }
}

/// Bidirectional mapper for the last path element of an IRI.
///
/// This mapper extracts the last path segment from absolute IRIs during
/// deserialization and appends path elements to a base IRI during serialization.
/// Useful for RESTful resource patterns or file-like IRI structures.
///
/// Examples:
/// With base IRI `"http://example.org/api/resources/"`:
/// - Serialization: `"item123"` → `const IriTerm("http://example.org/api/resources/item123")`
/// - Deserialization: `const IriTerm("http://example.org/api/resources/item123")` → `"item123"`
///
/// For IRIs ending with a slash, deserialization returns an empty string.
final class LastPathElementIriTermMapper implements IriTermMapper<String> {
  /// The base IRI to which path elements are appended during serialization.
  final String baseIri;

  /// Creates a mapper for last path elements with the specified base IRI.
  ///
  /// [baseIri] The base IRI used for path resolution (should typically end with /)
  const LastPathElementIriTermMapper(this.baseIri);

  @override
  IriTerm toRdfTerm(String pathElement, SerializationContext context) {
    final cleanBase = baseIri.endsWith('/') ? baseIri : '$baseIri/';
    return context.createIriTerm('$cleanBase$pathElement');
  }

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    final iri = term.value;

    // If IRI ends with slash, return empty string (directory-like structure)
    if (iri.endsWith('/')) {
      return '';
    }

    final lastSlashIndex = iri.lastIndexOf('/');

    if (lastSlashIndex == -1) {
      return iri; // No slash found, return entire IRI
    }

    return iri.substring(lastSlashIndex + 1);
  }
}

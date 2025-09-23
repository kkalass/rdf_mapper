import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating the use of IRI relative mappers for working with
/// document-relative IRIs in RDF. This is useful for creating more compact
/// RDF representations where IRIs can be expressed relative to a base URI.
///
/// The example shows three main use cases:
/// 1. Using IriRelativeSerializer for serialization only
/// 2. Using IriRelativeDeserializer for deserialization only
/// 3. Using IriRelativeMapper for bidirectional mapping

void main() {
  // Base URI for relative resolution
  const baseUri = 'http://example.org/documents/manual/';

  print('=== IRI Relative Mappers Example ===');
  print('');
  print('Base URI: $baseUri');
  print('');

  // Example 1: IriRelativeSerializer - Converting relative IRIs to absolute
  print('1. IriRelativeSerializer (Relative → Absolute)');
  const serializer = IriRelativeSerializer(baseUri);

  final relativeIris = [
    'introduction.html', // Same directory
    'chapter1/overview.html', // Subdirectory
    '../images/logo.png', // Parent directory
    '../../css/styles.css', // Two levels up
    '#conclusion', // Fragment only
    'search.html?q=dart', // With query parameters
    '', // Empty = base URI
  ];

  for (final relativeIri in relativeIris) {
    final iriTerm =
        serializer.toRdfTerm(relativeIri, MockSerializationContext());
    print('  "$relativeIri" → "${iriTerm.value}"');
  }

  print('');

  // Example 2: IriRelativeDeserializer - Converting absolute IRIs to relative
  print('2. IriRelativeDeserializer (Absolute → Relative)');
  const deserializer = IriRelativeDeserializer(baseUri);

  final absoluteIris = [
    'http://example.org/documents/manual/introduction.html', // Same directory
    'http://example.org/documents/manual/chapter1/overview.html', // Subdirectory
    'http://example.org/documents/images/logo.png', // Parent directory
    'http://example.org/css/styles.css', // Two levels up
    'http://example.org/documents/manual/#conclusion', // Fragment only
    'http://example.org/documents/manual/', // Exact base = empty
    'https://other.org/resource', // Cannot be relativized
    'urn:isbn:123456789', // URN scheme
  ];

  for (final absoluteIri in absoluteIris) {
    final iriTerm = IriTerm.validated(absoluteIri);
    final result =
        deserializer.fromRdfTerm(iriTerm, MockDeserializationContext());
    final status = result == absoluteIri ? '(unchanged)' : '(relativized)';
    print('  "$absoluteIri" → "$result" $status');
  }

  print('');

  // Example 3: IriRelativeMapper - Bidirectional mapping
  print('3. IriRelativeMapper (Bidirectional Roundtrip)');
  const mapper = IriRelativeMapper(baseUri);

  final testIris = [
    'section2/details.html',
    '../shared/common.js',
    '#section1',
    'api.html?version=v1#methods',
    '../../external/lib.js',
  ];

  print('Testing roundtrip consistency:');
  for (final relativeIri in testIris) {
    // Forward: relative → absolute
    final iriTerm = mapper.toRdfTerm(relativeIri, MockSerializationContext());

    // Backward: absolute → relative
    final backToRelative =
        mapper.fromRdfTerm(iriTerm, MockDeserializationContext());

    final consistent = relativeIri == backToRelative;
    final status = consistent ? '✓' : '✗';

    print('  $status "$relativeIri" → "${iriTerm.value}" → "$backToRelative"');
  }

  print('');

  // Example 4: Working with different base URI styles
  print('4. Different Base URI Formats');

  final baseUris = [
    'http://example.org/docs/', // With trailing slash
    'http://example.org/docs', // Without trailing slash
    'https://secure.site/api/v1/', // HTTPS with path
    'http://localhost:8080/app/', // With port
  ];

  const testRelativeIri = 'resource.html';

  for (final base in baseUris) {
    final mapper = IriRelativeMapper(base);
    final result =
        mapper.toRdfTerm(testRelativeIri, MockSerializationContext());
    print('  Base: $base');
    print('    "$testRelativeIri" → "${result.value}"');
  }

  print('');

  // Example 5: Practical usage patterns
  print('5. Practical Usage Patterns');
  print('');

  // Pattern A: Document linking system
  print('A. Document Linking System:');
  const docBaseUri = 'http://docs.example.org/v2/';
  const docMapper = IriRelativeMapper(docBaseUri);

  final documentLinks = [
    'getting-started.html',
    'advanced/concepts.html',
    '../v1/migration.html',
    'api/reference.html#methods',
  ];

  print('  Converting relative doc links to absolute IRIs:');
  for (final link in documentLinks) {
    final iri = docMapper.toRdfTerm(link, MockSerializationContext());
    print('    $link → ${iri.value}');
  }

  print('');

  // Pattern B: API endpoint mapping
  print('B. API Endpoint Mapping:');
  const apiBaseUri = 'https://api.example.org/v1/';
  const apiMapper = IriRelativeMapper(apiBaseUri);

  final apiEndpoints = [
    'users',
    'users/123',
    'users/123/posts',
    'admin/reports?format=json',
  ];

  print('  Converting relative API paths to absolute IRIs:');
  for (final endpoint in apiEndpoints) {
    final iri = apiMapper.toRdfTerm(endpoint, MockSerializationContext());
    print('    $endpoint → ${iri.value}');
  }

  print('');

  // Pattern C: Content management
  print('C. Content Management System:');
  const cmsBaseUri = 'http://cms.example.org/content/';
  const cmsMapper = IriRelativeMapper(cmsBaseUri);

  // Simulate converting absolute URIs back to relative for storage
  final absoluteContentUris = [
    'http://cms.example.org/content/articles/intro.html',
    'http://cms.example.org/content/images/header.jpg',
    'http://cms.example.org/assets/styles.css',
    'https://external.org/widget.js', // External resource
  ];

  print('  Converting absolute URIs to relative for compact storage:');
  for (final uri in absoluteContentUris) {
    final iriTerm = IriTerm.validated(uri);
    final relative =
        cmsMapper.fromRdfTerm(iriTerm, MockDeserializationContext());
    final isRelative = relative != uri;
    final status = isRelative ? '(relative)' : '(external)';
    print('    $uri → $relative $status');
  }

  print('');
  print('=== Example Complete ===');
  print('');
  print('Use cases for IRI Relative Mappers:');
  print('• Documentation systems with cross-references');
  print('• API systems with endpoint hierarchies');
  print('• Content management with relative asset links');
  print('• Any scenario requiring compact IRI representation');
}

/// Mock contexts for the example (in real use, these come from RdfMapper)
class MockSerializationContext implements SerializationContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockDeserializationContext implements DeserializationContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

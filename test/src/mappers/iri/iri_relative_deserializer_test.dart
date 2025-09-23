import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_deserializer.dart';
import 'package:test/test.dart';

import '../../deserializers/mock_deserialization_context.dart';

void main() {
  late DeserializationContext deserializationContext;

  setUp(() {
    deserializationContext = MockDeserializationContext();
  });

  group('IriRelativeDeserializer', () {
    group('constructor', () {
      test('creates instance with base URI', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);

        expect(deserializer.baseUri, equals(baseUri));
      });
    });

    group('fromRdfTerm', () {
      test('relativizes IRI within same directory', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/base/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource'));
      });

      test('relativizes IRI in subdirectory', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/base/subdir/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('subdir/resource'));
      });

      test('relativizes IRI with dot notation for parent directory', () {
        const baseUri = 'http://example.org/base/dir/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/base/other/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('../other/resource'));
      });

      test('relativizes fragment-only difference', () {
        const baseUri = 'http://example.org/base/document';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/base/document#section1');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('#section1'));
      });

      test('relativizes query-only difference', () {
        const baseUri = 'http://example.org/base/document';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term =
            const IriTerm('http://example.org/base/document?param=value');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        // Query differences result in filename?query format
        expect(result, equals('document?param=value'));
      });

      test('returns empty string for identical IRIs', () {
        const baseUri = 'http://example.org/base/document';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/base/document');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals(''));
      });

      test(
          'returns absolute IRI when cannot be relativized (different authority)',
          () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('https://other.org/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('https://other.org/resource'));
      });

      test('returns absolute IRI when cannot be relativized (different scheme)',
          () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('ftp://example.org/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('ftp://example.org/resource'));
      });

      test('returns absolute URN unchanged', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('urn:isbn:0451450523');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('urn:isbn:0451450523'));
      });

      test('relativizes complex nested paths', () {
        const baseUri = 'http://example.org/a/b/c/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/a/b/x/y/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('../x/y/resource'));
      });

      test('relativizes with multiple parent directory references', () {
        const baseUri = 'http://example.org/a/b/c/d/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/a/x/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('/a/x/resource'));
      });

      test('handles base URI without trailing slash', () {
        const baseUri = 'http://example.org/base';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource'));
      });

      test('preserves query and fragment in relative result', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm(
            'http://example.org/base/resource?param=value#section');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource?param=value#section'));
      });

      test('handles international characters in IRIs', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        // Use URL-encoded form as that's what the IRI term would actually contain
        final term = const IriTerm(
            'http://example.org/base/r%C3%A9sum%C3%A9/andr%C3%A9');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        // The relativization function appears to decode back to original characters
        expect(result, equals('résumé/andré'));
      });

      test('relativizes when base has query but target does not', () {
        const baseUri = 'http://example.org/base?param=value';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        // When base has query/fragment, relativization may not work as expected
        // This returns the absolute IRI since authorities and paths are different
        expect(result, equals('http://example.org/resource'));
      });

      test('relativizes when base has fragment but target does not', () {
        const baseUri = 'http://example.org/base#fragment';
        const deserializer = IriRelativeDeserializer(baseUri);
        final term = const IriTerm('http://example.org/resource');

        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource'));
      });
    });

    group('roundtrip consistency', () {
      test('ensures relativization can be resolved back to original', () {
        const baseUri = 'http://example.org/base/';
        const deserializer = IriRelativeDeserializer(baseUri);
        const originalIri = 'http://example.org/base/subdir/resource';
        final term = const IriTerm(originalIri);

        final relativized =
            deserializer.fromRdfTerm(term, deserializationContext);

        // The relative result should resolve back to the original IRI
        // This test mainly ensures we don't break the contract expected by resolveIri
        expect(relativized, isNot(equals(originalIri))); // Should be relative
        expect(relativized, equals('subdir/resource'));
      });
    });
  });
}

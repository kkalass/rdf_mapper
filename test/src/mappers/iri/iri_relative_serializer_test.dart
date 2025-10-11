import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_serializer.dart';
import 'package:test/test.dart';

import '../../serializers/mock_serialization_context.dart';

void main() {
  late SerializationContext serializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
  });

  group('IriRelativeSerializer', () {
    group('constructor', () {
      test('creates instance with base URI', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        expect(serializer.baseUri, equals(baseUri));
      });
    });

    group('toRdfTerm', () {
      test('resolves relative IRI against base URI', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('resource/1', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/resource/1'));
      });

      test('resolves relative path with dot notation', () {
        const baseUri = 'http://example.org/base/dir/';
        const serializer = IriRelativeSerializer(baseUri);

        final result =
            serializer.toRdfTerm('../other/resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/other/resource'));
      });

      test('resolves current directory reference', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('./resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/resource'));
      });

      test('resolves fragment-only reference', () {
        const baseUri = 'http://example.org/base/document';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('#section1', serializationContext);

        expect(result, isA<IriTerm>());
        expect(
            result.value, equals('http://example.org/base/document#section1'));
      });

      test('resolves query-only reference', () {
        const baseUri = 'http://example.org/base/document';
        const serializer = IriRelativeSerializer(baseUri);

        final result =
            serializer.toRdfTerm('?param=value', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value,
            equals('http://example.org/base/document?param=value'));
      });

      test('resolves empty string to base URI', () {
        const baseUri = 'http://example.org/base/document';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/document'));
      });

      test('leaves absolute IRI unchanged', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);
        const absoluteIri = 'https://other.org/resource/1';

        final result = serializer.toRdfTerm(absoluteIri, serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals(absoluteIri));
      });

      test('handles absolute IRI with same scheme but different authority', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);
        const absoluteIri = 'http://other.org/resource/1';

        final result = serializer.toRdfTerm(absoluteIri, serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals(absoluteIri));
      });

      test('handles URN schemes correctly', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);
        const urnIri = 'urn:isbn:0451450523';

        final result = serializer.toRdfTerm(urnIri, serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals(urnIri));
      });

      test('resolves complex relative paths', () {
        const baseUri = 'http://example.org/a/b/c/d/';
        const serializer = IriRelativeSerializer(baseUri);

        final result =
            serializer.toRdfTerm('../../x/y/resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/a/b/x/y/resource'));
      });

      test('handles base URI without trailing slash', () {
        const baseUri = 'http://example.org/base';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/resource'));
      });

      test('preserves query and fragment in relative IRIs', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm(
            'resource?param=value#section', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value,
            equals('http://example.org/base/resource?param=value#section'));
      });

      test('handles international characters in relative IRIs', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        final result =
            serializer.toRdfTerm('résumé/andré', serializationContext);

        expect(result, isA<IriTerm>());
        // International characters get URL-encoded in IRIs
        expect(result.value,
            equals('http://example.org/base/r%C3%A9sum%C3%A9/andr%C3%A9'));
      });
    });

    group('edge cases', () {
      test('handles base URI with query parameters', () {
        const baseUri = 'http://example.org/base?existing=param';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/resource'));
      });

      test('handles base URI with fragment', () {
        const baseUri = 'http://example.org/base#existing';
        const serializer = IriRelativeSerializer(baseUri);

        final result = serializer.toRdfTerm('resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/resource'));
      });

      test('handles malformed relative IRI gracefully', () {
        const baseUri = 'http://example.org/base/';
        const serializer = IriRelativeSerializer(baseUri);

        // This should not throw, but behavior depends on underlying URI parsing
        expect(
            () => serializer.toRdfTerm(
                'resource with spaces', serializationContext),
            returnsNormally);
      });
    });
  });
}

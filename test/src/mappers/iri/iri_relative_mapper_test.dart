import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_mapper.dart';
import 'package:test/test.dart';

import '../../deserializers/mock_deserialization_context.dart';
import '../../serializers/mock_serialization_context.dart';

void main() {
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
    deserializationContext = MockDeserializationContext();
  });

  group('IriRelativeMapper', () {
    group('constructor', () {
      test('creates instance with base URI', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);

        expect(mapper.baseUri, equals(baseUri));
      });
    });

    group('toRdfTerm (serialization)', () {
      test('resolves relative IRI against base URI', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);

        final result = mapper.toRdfTerm('resource/1', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/resource/1'));
      });

      test('resolves relative path with dot notation', () {
        const baseUri = 'http://example.org/base/dir/';
        const mapper = IriRelativeMapper(baseUri);

        final result =
            mapper.toRdfTerm('../other/resource', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/other/resource'));
      });

      test('leaves absolute IRI unchanged', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const absoluteIri = 'https://other.org/resource/1';

        final result = mapper.toRdfTerm(absoluteIri, serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals(absoluteIri));
      });

      test('resolves fragment-only reference', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);

        final result = mapper.toRdfTerm('#section1', serializationContext);

        expect(result, isA<IriTerm>());
        expect(
            result.value, equals('http://example.org/base/document#section1'));
      });

      test('resolves empty string to base URI', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);

        final result = mapper.toRdfTerm('', serializationContext);

        expect(result, isA<IriTerm>());
        expect(result.value, equals('http://example.org/base/document'));
      });
    });

    group('fromRdfTerm (deserialization)', () {
      test('relativizes IRI within same directory', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        final term = const IriTerm('http://example.org/base/resource');

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource'));
      });

      test('relativizes IRI with dot notation for parent directory', () {
        const baseUri = 'http://example.org/base/dir/';
        const mapper = IriRelativeMapper(baseUri);
        final term = const IriTerm('http://example.org/base/other/resource');

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('../other/resource'));
      });

      test('returns absolute IRI when cannot be relativized', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        final term = const IriTerm('https://other.org/resource');

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('https://other.org/resource'));
      });

      test('relativizes fragment-only difference', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);
        final term = const IriTerm('http://example.org/base/document#section1');

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('#section1'));
      });

      test('returns empty string for identical IRIs', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);
        final term = const IriTerm('http://example.org/base/document');

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(''));
      });
    });

    group('bidirectional roundtrip consistency', () {
      test(
          'serialization and deserialization are inverse operations for relative IRIs',
          () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const relativeIri = 'subdir/resource';

        // Serialize: relative string -> absolute IRI term
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);

        // Deserialize: absolute IRI term -> relative string
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(relativeIri));
      });

      test(
          'serialization and deserialization handle parent directory navigation',
          () {
        const baseUri = 'http://example.org/base/subdir/';
        const mapper = IriRelativeMapper(baseUri);
        const relativeIri = '../other/resource';

        // Serialize: relative string -> absolute IRI term
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        expect(
            serialized.value, equals('http://example.org/base/other/resource'));

        // Deserialize: absolute IRI term -> relative string
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(relativeIri));
      });

      test('serialization and deserialization handle fragment references', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);
        const fragmentIri = '#section1';

        // Serialize: fragment reference -> absolute IRI term
        final serialized = mapper.toRdfTerm(fragmentIri, serializationContext);
        expect(serialized.value,
            equals('http://example.org/base/document#section1'));

        // Deserialize: absolute IRI term -> fragment reference
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(fragmentIri));
      });

      test('serialization and deserialization handle empty string', () {
        const baseUri = 'http://example.org/base/document';
        const mapper = IriRelativeMapper(baseUri);
        const emptyIri = '';

        // Serialize: empty string -> base URI as IRI term
        final serialized = mapper.toRdfTerm(emptyIri, serializationContext);
        expect(serialized.value, equals(baseUri));

        // Deserialize: base URI IRI term -> empty string
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(emptyIri));
      });

      test('absolute IRIs pass through unchanged in both directions', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const absoluteIri = 'https://other.org/resource';

        // Serialize: absolute IRI string -> absolute IRI term (unchanged)
        final serialized = mapper.toRdfTerm(absoluteIri, serializationContext);
        expect(serialized.value, equals(absoluteIri));

        // Deserialize: absolute IRI term -> absolute IRI string (unchanged)
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(absoluteIri));
      });

      test('complex nested paths maintain consistency', () {
        const baseUri = 'http://example.org/a/b/c/';
        const mapper = IriRelativeMapper(baseUri);
        const relativeIri = '../../x/y/resource';

        // Serialize
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        expect(serialized.value, equals('http://example.org/a/x/y/resource'));

        // Deserialize
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals('/a/x/y/resource'));
      });

      test('query and fragment components are preserved', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const relativeIri = 'resource?param=value#section';

        // Serialize
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        expect(serialized.value,
            equals('http://example.org/base/resource?param=value#section'));

        // Deserialize
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(relativeIri));
      });

      test('international characters are handled correctly', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const relativeIri = 'résumé/andré';

        // Serialize
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        // International characters get URL-encoded in IRIs
        expect(serialized.value,
            equals('http://example.org/base/r%C3%A9sum%C3%A9/andr%C3%A9'));

        // Deserialize back to original form (relativization decodes back)
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals('résumé/andré'));
      });
    });

    group('edge cases', () {
      test('handles different base URI formats consistently', () {
        const mapper1 = IriRelativeMapper('http://example.org/base/');
        const mapper2 = IriRelativeMapper('http://example.org/base');

        final serialized1 = mapper1.toRdfTerm('resource', serializationContext);
        final serialized2 = mapper2.toRdfTerm('resource', serializationContext);

        // Both should produce valid IRI terms, though possibly different
        expect(serialized1, isA<IriTerm>());
        expect(serialized2, isA<IriTerm>());
      });

      test('handles URN schemes in serialization context', () {
        const baseUri = 'http://example.org/base/';
        const mapper = IriRelativeMapper(baseUri);
        const urnIri = 'urn:isbn:0451450523';

        // URN should pass through unchanged
        final serialized = mapper.toRdfTerm(urnIri, serializationContext);
        expect(serialized.value, equals(urnIri));

        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);
        expect(deserialized, equals(urnIri));
      });
    });
  });
}

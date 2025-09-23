import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_mapper.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

void main() {
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
    deserializationContext = MockDeserializationContext();
  });

  group('IriFullMapper', () {
    test('should be instantiable as const', () {
      const mapper = IriFullMapper();
      expect(mapper, isA<IriFullMapper>());
    });

    group('toRdfTerm', () {
      test('correctly serializes complete IRI string to IRI term', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/resource/123';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });

      test('correctly handles HTTPS URLs', () {
        const mapper = IriFullMapper();
        const testIri = 'https://secure.example.org/api/v1/resource';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });

      test('correctly handles URNs', () {
        const mapper = IriFullMapper();
        const testIri = 'urn:uuid:12345678-1234-5678-9abc-123456789abc';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });

      test('correctly handles IRIs with fragments', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/document#section1';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });

      test('correctly handles IRIs with query parameters', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/search?q=test&format=json';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });

      test('preserves special characters in IRI', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/resource/with%20spaces';

        final iriTerm = mapper.toRdfTerm(testIri, serializationContext);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals(testIri));
      });
    });

    group('fromRdfTerm', () {
      test('correctly deserializes IRI term to complete IRI string', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/resource/456';
        final iriTerm = const IriTerm(testIri);

        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(testIri));
      });

      test('correctly handles HTTPS URLs in deserialization', () {
        const mapper = IriFullMapper();
        const testIri = 'https://secure.example.org/api/v2/data';
        final iriTerm = const IriTerm(testIri);

        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(testIri));
      });

      test('correctly handles URNs in deserialization', () {
        const mapper = IriFullMapper();
        const testIri = 'urn:isbn:9780134685991';
        final iriTerm = const IriTerm(testIri);

        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(testIri));
      });

      test('correctly handles IRIs with fragments in deserialization', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/ontology#Person';
        final iriTerm = const IriTerm(testIri);

        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(testIri));
      });

      test('preserves special characters during deserialization', () {
        const mapper = IriFullMapper();
        const testIri = 'http://example.org/resource/with%20encoded%20chars';
        final iriTerm = const IriTerm(testIri);

        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(testIri));
      });
    });

    group('roundtrip consistency', () {
      test('maintains consistency for HTTP URLs', () {
        const mapper = IriFullMapper();
        const originalIri = 'http://example.org/resource/test';

        final iriTerm = mapper.toRdfTerm(originalIri, serializationContext);
        final roundtripIri =
            mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtripIri, equals(originalIri));
      });

      test('maintains consistency for HTTPS URLs', () {
        const mapper = IriFullMapper();
        const originalIri = 'https://secure.example.org/protected/resource';

        final iriTerm = mapper.toRdfTerm(originalIri, serializationContext);
        final roundtripIri =
            mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtripIri, equals(originalIri));
      });

      test('maintains consistency for URNs', () {
        const mapper = IriFullMapper();
        const originalIri = 'urn:example:namespace:identifier';

        final iriTerm = mapper.toRdfTerm(originalIri, serializationContext);
        final roundtripIri =
            mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtripIri, equals(originalIri));
      });

      test('maintains consistency for complex IRIs', () {
        const mapper = IriFullMapper();
        const originalIri =
            'https://api.example.org/v1/search?q=term&limit=10#results';

        final iriTerm = mapper.toRdfTerm(originalIri, serializationContext);
        final roundtripIri =
            mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtripIri, equals(originalIri));
      });

      test('maintains consistency for IRIs with encoded characters', () {
        const mapper = IriFullMapper();
        const originalIri =
            'http://example.org/path/with%20spaces%20and%20special%20chars';

        final iriTerm = mapper.toRdfTerm(originalIri, serializationContext);
        final roundtripIri =
            mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtripIri, equals(originalIri));
      });
    });

    group('edge cases', () {
      test('rejects empty string (invalid IRI)', () {
        const mapper = IriFullMapper();
        const emptyIri = '';

        // Empty string should throw an exception as it's not a valid IRI
        expect(
          () => mapper.toRdfTerm(emptyIri, serializationContext),
          throwsA(isA<Exception>()),
        );
      });

      test('handles minimal valid IRI', () {
        const mapper = IriFullMapper();
        const minimalIri = 'a:b';

        final iriTerm = mapper.toRdfTerm(minimalIri, serializationContext);
        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(minimalIri));
      });

      test('handles very long IRI', () {
        const mapper = IriFullMapper();
        final longIri = 'http://example.org/' + 'a' * 1000;

        final iriTerm = mapper.toRdfTerm(longIri, serializationContext);
        final result = mapper.fromRdfTerm(iriTerm, deserializationContext);

        expect(result, equals(longIri));
      });
    });

    group('type conformance', () {
      test('implements IriTermMapper interface correctly', () {
        const mapper = IriFullMapper();
        expect(mapper, isA<IriTermMapper<String>>());
      });

      test('has correct generic type parameter', () {
        const mapper = IriFullMapper();

        // Test that the mapper works with String type
        const testString = 'http://example.org/test';
        final term = mapper.toRdfTerm(testString, serializationContext);
        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, isA<String>());
        expect(result, equals(testString));
      });
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

import '../../deserializers/mock_deserialization_context.dart';
import '../../serializers/mock_serialization_context.dart';

void main() {
  group('FragmentIriTermMapper', () {
    const baseIri = 'http://example.org/document';
    const mapper = FragmentIriTermMapper(baseIri);
    late SerializationContext serializationContext;
    late DeserializationContext deserializationContext;

    setUp(() {
      serializationContext = MockSerializationContext();
      deserializationContext = MockDeserializationContext();
    });

    group('toRdfTerm', () {
      test('appends fragment to base IRI', () {
        final result = mapper.toRdfTerm('section1', serializationContext);
        expect(result.value, equals('http://example.org/document#section1'));
      });

      test('handles empty fragment', () {
        final result = mapper.toRdfTerm('', serializationContext);
        expect(result.value, equals('http://example.org/document#'));
      });

      test('handles base IRI with trailing hash', () {
        const mapperWithHash =
            FragmentIriTermMapper('http://example.org/document#');
        final result =
            mapperWithHash.toRdfTerm('section1', serializationContext);
        expect(result.value, equals('http://example.org/document#section1'));
      });
    });

    group('fromRdfTerm', () {
      test('extracts fragment from IRI', () {
        final term = const IriTerm('http://example.org/document#section1');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('section1'));
      });

      test('returns empty string for IRI without fragment', () {
        final term = const IriTerm('http://example.org/document');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals(''));
      });

      test('extracts last fragment for multiple hash symbols', () {
        final term = const IriTerm('http://example.org/doc#ument#section1');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('section1'));
      });

      test('handles empty fragment in IRI', () {
        final term = const IriTerm('http://example.org/document#');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals(''));
      });
    });

    group('roundtrip consistency', () {
      test('basic fragment roundtrip', () {
        const fragment = 'section1';
        final iriTerm = mapper.toRdfTerm(fragment, serializationContext);
        final extractedFragment =
            mapper.fromRdfTerm(iriTerm, deserializationContext);
        expect(extractedFragment, equals(fragment));
      });

      test('empty fragment roundtrip', () {
        const fragment = '';
        final iriTerm = mapper.toRdfTerm(fragment, serializationContext);
        final extractedFragment =
            mapper.fromRdfTerm(iriTerm, deserializationContext);
        expect(extractedFragment, equals(fragment));
      });
    });
  });

  group('LastPathElementIriTermMapper', () {
    const baseIri = 'http://example.org/api/resources/';
    const mapper = LastPathElementIriTermMapper(baseIri);
    late SerializationContext serializationContext;
    late DeserializationContext deserializationContext;

    setUp(() {
      serializationContext = MockSerializationContext();
      deserializationContext = MockDeserializationContext();
    });

    group('toRdfTerm', () {
      test('appends path element to base IRI', () {
        final result = mapper.toRdfTerm('item123', serializationContext);
        expect(
            result.value, equals('http://example.org/api/resources/item123'));
      });

      test('handles base IRI without trailing slash', () {
        const mapperNoSlash =
            LastPathElementIriTermMapper('http://example.org/api/resources');
        final result = mapperNoSlash.toRdfTerm('item123', serializationContext);
        expect(
            result.value, equals('http://example.org/api/resources/item123'));
      });

      test('handles empty path element', () {
        final result = mapper.toRdfTerm('', serializationContext);
        expect(result.value, equals('http://example.org/api/resources/'));
      });
    });

    group('fromRdfTerm', () {
      test('extracts last path element from IRI', () {
        final term = const IriTerm('http://example.org/api/resources/item123');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('item123'));
      });

      test('returns empty string for IRI ending with slash', () {
        final term = const IriTerm('http://example.org/api/resources/');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals(''));
      });

      test('handles IRI without slashes', () {
        final term = const IriTerm('http:item123');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('http:item123'));
      });

      test('extracts from nested path', () {
        final term =
            const IriTerm('http://example.org/api/resources/category/item123');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('item123'));
      });

      test('handles multiple consecutive slashes', () {
        final term =
            const IriTerm('http://example.org//api///resources//item123');
        final result = mapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('item123'));
      });
    });

    group('roundtrip consistency', () {
      test('basic path element roundtrip', () {
        const pathElement = 'item123';
        final iriTerm = mapper.toRdfTerm(pathElement, serializationContext);
        final extractedElement =
            mapper.fromRdfTerm(iriTerm, deserializationContext);
        expect(extractedElement, equals(pathElement));
      });

      test('empty path element roundtrip', () {
        const pathElement = '';
        final iriTerm = mapper.toRdfTerm(pathElement, serializationContext);
        final extractedElement =
            mapper.fromRdfTerm(iriTerm, deserializationContext);
        expect(extractedElement, equals(pathElement));
      });

      test('complex path element roundtrip', () {
        const pathElement = 'complex-item-name_with.special.chars';
        final iriTerm = mapper.toRdfTerm(pathElement, serializationContext);
        final extractedElement =
            mapper.fromRdfTerm(iriTerm, deserializationContext);
        expect(extractedElement, equals(pathElement));
      });
    });
  });
}

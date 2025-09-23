import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/src/mappers/iri/extracting_iri_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_serializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_id_serializer.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

// Definition for a simple test resource class
class Resource {
  final String host;
  final String path;

  Resource({required this.host, required this.path});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          path == other.path;

  @override
  int get hashCode => host.hashCode ^ path.hashCode;
}

void main() {
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
    deserializationContext = MockDeserializationContext();
  });

  group('IRI Mappers', () {
    group('IriFullSerializer', () {
      test('correctly serializes strings to IRI terms', () {
        final serializer = IriFullSerializer();

        final validIris = [
          'http://example.org/resource/1',
          'https://schema.org/name',
          'urn:isbn:0451450523',
          'file:///path/to/file.txt',
        ];

        for (final iri in validIris) {
          final term = serializer.toRdfTerm(iri, serializationContext);

          expect(term, isA<IriTerm>());
          expect(term.value, equals(iri));
        }
      });

      test('handles special characters in IRIs', () {
        final serializer = IriFullSerializer();

        final iri = 'http://example.org/resource#fragment?query=value&param=2';
        final term = serializer.toRdfTerm(iri, serializationContext);

        expect(term.value, equals(iri));
      });
    });

    group('IriIdSerializer', () {
      test('properly prefixes IDs with base URL', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm.validated('$baseUrl$id'),
        );

        final ids = ['123', 'abc-456', 'item_789'];

        for (final id in ids) {
          final term = serializer.toRdfTerm(id, serializationContext);

          expect(term, isA<IriTerm>());
          expect(term.value, equals('$baseUrl$id'));
        }
      });

      test('handles empty IDs', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm.validated('$baseUrl$id'),
        );

        final term = serializer.toRdfTerm('', serializationContext);

        expect(term.value, equals(baseUrl));
      });

      test('throws assertion error when ID contains slashes', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm.validated('$baseUrl$id'),
        );

        expect(
          () => serializer.toRdfTerm('invalid/id', serializationContext),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('IriFullDeserializer', () {
      test('correctly deserializes IRI terms to strings', () {
        final deserializer = IriFullDeserializer();

        final validIris = [
          'http://example.org/resource/1',
          'https://schema.org/name',
          'urn:isbn:0451450523',
          'file:///path/to/file.txt',
        ];

        for (final iri in validIris) {
          final term = IriTerm.validated(iri);
          final result = deserializer.fromRdfTerm(term, deserializationContext);

          expect(result, isA<String>());
          expect(result, equals(iri));
        }
      });

      test('handles special characters in IRIs during deserialization', () {
        final deserializer = IriFullDeserializer();

        final iri = 'http://example.org/resource#fragment?query=value&param=2';
        final term = IriTerm.validated(iri);
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals(iri));
      });
    });

    group('ExtractingIriTermDeserializer', () {
      test('extracts data using custom extractor function', () {
        // Create a deserializer that extracts the last path segment of a URL
        final deserializer = ExtractingIriTermDeserializer<String>(
          extract: (term, _) => term.value.split('/').last,
        );

        final term = const IriTerm('http://example.org/resources/resource-123');
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource-123'));
      });

      test('works with Uri objects', () {
        final deserializer = ExtractingIriTermDeserializer<Uri>(
          extract: (term, _) => Uri.parse(term.value),
        );

        final term = const IriTerm(
          'http://example.org/resources/resource-123?param=value',
        );
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, isA<Uri>());
        expect(result.scheme, equals('http'));
        expect(result.host, equals('example.org'));
        expect(result.path, equals('/resources/resource-123'));
        expect(result.query, equals('param=value'));
      });

      test('works with custom objects', () {
        // Create a deserializer for our Resource type
        final deserializer = ExtractingIriTermDeserializer<Resource>(
          extract: (term, _) {
            final uri = Uri.parse(term.value);
            return Resource(host: uri.host, path: uri.path);
          },
        );

        final term = const IriTerm('http://example.org/resources/resource-123');
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, isA<Resource>());
        expect(
          result,
          equals(
            Resource(host: 'example.org', path: '/resources/resource-123'),
          ),
        );
      });

      test('handles errors in custom extractor', () {
        // Create a deserializer with an extractor that throws for invalid IRIs
        final deserializer = ExtractingIriTermDeserializer<Uri>(
          extract: (term, _) {
            if (!term.value.startsWith('http')) {
              throw FormatException('Not a valid HTTP URI: ${term.value}');
            }
            return Uri.parse(term.value);
          },
        );

        // Valid HTTP URI should work
        final validTerm = const IriTerm('http://example.org/resources/123');
        final validResult = deserializer.fromRdfTerm(
          validTerm,
          deserializationContext,
        );
        expect(validResult, isA<Uri>());

        // Invalid URI should throw DeserializationException
        final invalidTerm = const IriTerm('ftp://example.org/file.txt');
        expect(
          () => deserializer.fromRdfTerm(invalidTerm, deserializationContext),
          throwsA(isA<DeserializationException>()),
        );
      });
    });
  });
}

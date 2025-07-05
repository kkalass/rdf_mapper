import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/resource_reader.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/src/mappers/iri/extracting_iri_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_serializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_id_serializer.dart';
import 'package:test/test.dart';

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

// Mock implementations for testing
class MockSerializationContext extends SerializationContext {
  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    throw UnimplementedError();
  }

  @override
  List<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer}) {
    throw UnimplementedError();
  }

  @override
  LiteralTerm toLiteralTerm<T>(
    T value, {
    LiteralTermSerializer<T>? serializer,
  }) {
    throw UnimplementedError();
  }
}

class MockDeserializationContext extends DeserializationContext {
  @override
  ResourceReader reader(RdfSubject subject) {
    throw UnimplementedError();
  }

  @override
  T fromLiteralTerm<T>(
    LiteralTerm term, {
    LiteralTermDeserializer<T>? deserializer,
    bool bypassDatatypeCheck = false,
  }) {
    throw UnimplementedError();
  }
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
          expect(term.iri, equals(iri));
        }
      });

      test('handles special characters in IRIs', () {
        final serializer = IriFullSerializer();

        final iri = 'http://example.org/resource#fragment?query=value&param=2';
        final term = serializer.toRdfTerm(iri, serializationContext);

        expect(term.iri, equals(iri));
      });
    });

    group('IriIdSerializer', () {
      test('properly prefixes IDs with base URL', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm('$baseUrl$id'),
        );

        final ids = ['123', 'abc-456', 'item_789'];

        for (final id in ids) {
          final term = serializer.toRdfTerm(id, serializationContext);

          expect(term, isA<IriTerm>());
          expect(term.iri, equals('$baseUrl$id'));
        }
      });

      test('handles empty IDs', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm('$baseUrl$id'),
        );

        final term = serializer.toRdfTerm('', serializationContext);

        expect(term.iri, equals(baseUrl));
      });

      test('throws assertion error when ID contains slashes', () {
        const baseUrl = 'http://example.org/resources/';
        final serializer = IriIdSerializer(
          expand: (id, _) => IriTerm('$baseUrl$id'),
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
          final term = IriTerm(iri);
          final result = deserializer.fromRdfTerm(term, deserializationContext);

          expect(result, isA<String>());
          expect(result, equals(iri));
        }
      });

      test('handles special characters in IRIs during deserialization', () {
        final deserializer = IriFullDeserializer();

        final iri = 'http://example.org/resource#fragment?query=value&param=2';
        final term = IriTerm(iri);
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals(iri));
      });
    });

    group('ExtractingIriTermDeserializer', () {
      test('extracts data using custom extractor function', () {
        // Create a deserializer that extracts the last path segment of a URL
        final deserializer = ExtractingIriTermDeserializer<String>(
          extract: (term, _) => term.iri.split('/').last,
        );

        final term = IriTerm('http://example.org/resources/resource-123');
        final result = deserializer.fromRdfTerm(term, deserializationContext);

        expect(result, equals('resource-123'));
      });

      test('works with Uri objects', () {
        final deserializer = ExtractingIriTermDeserializer<Uri>(
          extract: (term, _) => Uri.parse(term.iri),
        );

        final term = IriTerm(
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
            final uri = Uri.parse(term.iri);
            return Resource(host: uri.host, path: uri.path);
          },
        );

        final term = IriTerm('http://example.org/resources/resource-123');
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
            if (!term.iri.startsWith('http')) {
              throw FormatException('Not a valid HTTP URI: ${term.iri}');
            }
            return Uri.parse(term.iri);
          },
        );

        // Valid HTTP URI should work
        final validTerm = IriTerm('http://example.org/resources/123');
        final validResult = deserializer.fromRdfTerm(
          validTerm,
          deserializationContext,
        );
        expect(validResult, isA<Uri>());

        // Invalid URI should throw DeserializationException
        final invalidTerm = IriTerm('ftp://example.org/file.txt');
        expect(
          () => deserializer.fromRdfTerm(invalidTerm, deserializationContext),
          throwsA(isA<DeserializationException>()),
        );
      });
    });
  });
}

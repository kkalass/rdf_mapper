import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_mapper.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_serializer.dart';
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

  group('IRI Relative Mappers Integration', () {
    test('all three classes handle the same base URI consistently', () {
      const baseUri = 'http://example.org/documents/';

      const serializer = IriRelativeSerializer(baseUri);
      const deserializer = IriRelativeDeserializer(baseUri);
      const mapper = IriRelativeMapper(baseUri);

      expect(serializer.baseUri, equals(baseUri));
      expect(deserializer.baseUri, equals(baseUri));
      expect(mapper.baseUri, equals(baseUri));
    });

    test('serializer and deserializer work together as inverse operations', () {
      const baseUri = 'http://example.org/documents/';
      const serializer = IriRelativeSerializer(baseUri);
      const deserializer = IriRelativeDeserializer(baseUri);

      const relativeIri = 'chapter1/section2';

      // Serialize: relative string -> absolute IRI term
      final iriTerm = serializer.toRdfTerm(relativeIri, serializationContext);
      expect(iriTerm.value,
          equals('http://example.org/documents/chapter1/section2'));

      // Deserialize: absolute IRI term -> relative string
      final backToRelative =
          deserializer.fromRdfTerm(iriTerm, deserializationContext);
      expect(backToRelative, equals(relativeIri));
    });

    test(
        'mapper provides same functionality as separate serializer/deserializer',
        () {
      const baseUri = 'http://example.org/api/';
      const serializer = IriRelativeSerializer(baseUri);
      const deserializer = IriRelativeDeserializer(baseUri);
      const mapper = IriRelativeMapper(baseUri);

      const relativeIri = 'users/123';

      // Compare serialization
      final serializerResult =
          serializer.toRdfTerm(relativeIri, serializationContext);
      final mapperSerializeResult =
          mapper.toRdfTerm(relativeIri, serializationContext);
      expect(mapperSerializeResult.value, equals(serializerResult.value));

      // Compare deserialization
      final iriTerm = const IriTerm('http://example.org/api/users/456');
      final deserializerResult =
          deserializer.fromRdfTerm(iriTerm, deserializationContext);
      final mapperDeserializeResult =
          mapper.fromRdfTerm(iriTerm, deserializationContext);
      expect(mapperDeserializeResult, equals(deserializerResult));
    });

    test('complex document structure with various relative references', () {
      const baseUri = 'http://example.org/docs/manual/';
      const mapper = IriRelativeMapper(baseUri);

      final testCases = [
        // Simple relative paths
        'introduction.html',
        'chapter1/overview.html',
        'chapter2/advanced/concepts.html',

        // Parent directory navigation
        '../index.html',
        '../images/logo.png',
        '/css/styles.css',

        // Fragment references
        '#conclusion',
        'chapter1.html#section2',

        // Query parameters
        'search.html?q=dart',
        'api.html?version=latest#methods',

        // Complex combinations
        '../shared/utils.html?ref=manual#usage',
      ];

      for (final relativeIri in testCases) {
        // Test roundtrip consistency
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);

        expect(deserialized, equals(relativeIri),
            reason: 'Roundtrip failed for: $relativeIri');
      }
    });

    test('handles absolute IRIs that cannot be relativized', () {
      const baseUri = 'http://example.org/docs/';
      const mapper = IriRelativeMapper(baseUri);

      final absoluteIris = [
        'https://other.org/resource', // Different scheme
        'http://other.org/resource', // Different authority
        'ftp://example.org/file', // Different scheme, same authority
        'urn:isbn:0123456789', // URN scheme
      ];

      for (final absoluteIri in absoluteIris) {
        // Serialize: should pass through unchanged
        final serialized = mapper.toRdfTerm(absoluteIri, serializationContext);
        expect(serialized.value, equals(absoluteIri));

        // Deserialize: should also pass through unchanged
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);
        expect(deserialized, equals(absoluteIri));
      }
    });

    test('edge cases with different base URI formats', () {
      final baseCases = [
        'http://example.org/base/', // With trailing slash
        'http://example.org/base', // Without trailing slash
        'http://example.org/path/to/base/', // Nested path with slash
        'http://example.org/path/to/base', // Nested path without slash
      ];

      for (final baseUri in baseCases) {
        final mapper = IriRelativeMapper(baseUri);

        // Test that construction works
        expect(mapper.baseUri, equals(baseUri));

        // Test basic functionality
        final result = mapper.toRdfTerm('resource', serializationContext);
        expect(result, isA<IriTerm>());
        expect(result.value, contains('resource'));
      }
    });

    test('performance characteristics with large batch of operations', () {
      const baseUri = 'http://example.org/data/';
      const mapper = IriRelativeMapper(baseUri);

      // Generate a batch of test IRIs
      final relativeIris = List.generate(100, (i) => 'item$i/details');

      final stopwatch = Stopwatch()..start();

      // Perform batch serialization and deserialization
      for (final relativeIri in relativeIris) {
        final serialized = mapper.toRdfTerm(relativeIri, serializationContext);
        final deserialized =
            mapper.fromRdfTerm(serialized, deserializationContext);
        expect(deserialized, equals(relativeIri));
      }

      stopwatch.stop();

      // Ensure operations complete in reasonable time (less than 100ms for 100 operations)
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason:
              'Batch operations took too long: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('thread safety - mappers are stateless and const', () {
      const baseUri = 'http://example.org/test/';

      // All instances with same base URI should be equal
      const mapper1 = IriRelativeMapper(baseUri);
      const mapper2 = IriRelativeMapper(baseUri);
      const serializer1 = IriRelativeSerializer(baseUri);
      const serializer2 = IriRelativeSerializer(baseUri);
      const deserializer1 = IriRelativeDeserializer(baseUri);
      const deserializer2 = IriRelativeDeserializer(baseUri);

      // Test that they're const constructors (compile-time check)
      expect(mapper1.baseUri, equals(mapper2.baseUri));
      expect(serializer1.baseUri, equals(serializer2.baseUri));
      expect(deserializer1.baseUri, equals(deserializer2.baseUri));

      // Test that operations are consistent across instances
      const testIri = 'test/resource';
      final result1 = mapper1.toRdfTerm(testIri, serializationContext);
      final result2 = mapper2.toRdfTerm(testIri, serializationContext);
      expect(result1.value, equals(result2.value));
    });
  });
}

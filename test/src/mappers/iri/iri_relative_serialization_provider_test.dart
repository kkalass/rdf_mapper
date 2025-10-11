import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_serialization_provider.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_relative_deserializer.dart';
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

  group('IriRelativeSerializationProvider', () {
    group('Basic Functionality', () {
      test('creates serializer with subject IRI as base', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/doc/');

        final serializer =
            provider.serializer('parent', subject, serializationContext);

        expect(serializer, isA<IriRelativeSerializer>());
        // Test that it uses the subject IRI as base by serializing a relative IRI
        final result = (serializer as IriRelativeSerializer)
            .toRdfTerm('photos/avatar.jpg', serializationContext);
        expect(
            result.value, equals('https://example.org/doc/photos/avatar.jpg'));
      });

      test('creates deserializer with subject IRI as base', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/doc/');

        final deserializer =
            provider.deserializer(subject, deserializationContext);

        expect(deserializer, isA<IriRelativeDeserializer>());
        // Test that it uses the subject IRI as base by deserializing an absolute IRI
        final absoluteIri =
            const IriTerm('https://example.org/doc/photos/avatar.jpg');
        final result = (deserializer as IriRelativeDeserializer)
            .fromRdfTerm(absoluteIri, deserializationContext);
        expect(result, equals('photos/avatar.jpg'));
      });
    });

    group('Contextual Base URI Resolution', () {
      test('different subjects produce different base URIs for serializers',
          () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject1 = const IriTerm('https://alice.example/');
        final subject2 = const IriTerm('https://bob.example/');

        final serializer1 = provider.serializer(
            'parent', subject1, serializationContext) as IriRelativeSerializer;
        final serializer2 = provider.serializer(
            'parent', subject2, serializationContext) as IriRelativeSerializer;

        // Same relative IRI should resolve differently based on subject context
        final result1 =
            serializer1.toRdfTerm('photos/pic.jpg', serializationContext);
        final result2 =
            serializer2.toRdfTerm('photos/pic.jpg', serializationContext);

        expect(result1.value, equals('https://alice.example/photos/pic.jpg'));
        expect(result2.value, equals('https://bob.example/photos/pic.jpg'));
      });

      test('different subjects produce different base URIs for deserializers',
          () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject1 = const IriTerm('https://alice.example/');
        final subject2 = const IriTerm('https://bob.example/');

        final deserializer1 = provider.deserializer(
            subject1, deserializationContext) as IriRelativeDeserializer;
        final deserializer2 = provider.deserializer(
            subject2, deserializationContext) as IriRelativeDeserializer;

        // Same absolute IRI should relativize differently based on subject context
        final absoluteIri1 =
            const IriTerm('https://alice.example/photos/pic.jpg');
        final absoluteIri2 =
            const IriTerm('https://bob.example/photos/pic.jpg');

        final result1 =
            deserializer1.fromRdfTerm(absoluteIri1, deserializationContext);
        final result2 =
            deserializer2.fromRdfTerm(absoluteIri2, deserializationContext);

        expect(result1, equals('photos/pic.jpg'));
        expect(result2, equals('photos/pic.jpg'));
      });
    });

    group('Person Use Cases', () {
      test('handles person with relative photo URLs', () {
        const provider = IriRelativeSerializationProvider<String>();
        final personIri = const IriTerm('https://alice.example/');

        final serializer = provider.serializer(
            'person', personIri, serializationContext) as IriRelativeSerializer;
        final deserializer = provider.deserializer(
            personIri, deserializationContext) as IriRelativeDeserializer;

        // Test person-relative photo path
        final photoIri =
            serializer.toRdfTerm('photos/avatar.jpg', serializationContext);
        expect(
            photoIri.value, equals('https://alice.example/photos/avatar.jpg'));

        // Test relativization back to person IRI
        final absolutePhoto =
            const IriTerm('https://alice.example/photos/avatar.jpg');
        final relativized =
            deserializer.fromRdfTerm(absolutePhoto, deserializationContext);
        expect(relativized, equals('photos/avatar.jpg'));
      });

      test('handles multiple people with different contexts', () {
        const provider = IriRelativeSerializationProvider<String>();
        final alice = const IriTerm('https://alice.example/');
        final bob = const IriTerm('https://bob.example/');

        final aliceSerializer = provider.serializer(
            'alice', alice, serializationContext) as IriRelativeSerializer;
        final bobSerializer = provider.serializer(
            'bob', bob, serializationContext) as IriRelativeSerializer;

        // Same relative path should resolve to different absolute IRIs
        final alicePhoto =
            aliceSerializer.toRdfTerm('img/me.jpg', serializationContext);
        final bobPhoto =
            bobSerializer.toRdfTerm('img/me.jpg', serializationContext);

        expect(alicePhoto.value, equals('https://alice.example/img/me.jpg'));
        expect(bobPhoto.value, equals('https://bob.example/img/me.jpg'));
      });
    });

    group('Edge Cases', () {
      test('handles absolute IRIs in serialization', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/doc');

        final serializer = provider.serializer(
            'parent', subject, serializationContext) as IriRelativeSerializer;

        // Absolute IRI should remain absolute
        final result = serializer.toRdfTerm(
            'https://other.example/resource', serializationContext);
        expect(result.value, equals('https://other.example/resource'));
      });

      test('handles non-relativizable IRIs in deserialization', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/doc');

        final deserializer = provider.deserializer(
            subject, deserializationContext) as IriRelativeDeserializer;

        // IRI from different domain should remain absolute
        final absoluteIri = const IriTerm('https://other.example/resource');
        final result =
            deserializer.fromRdfTerm(absoluteIri, deserializationContext);
        expect(result, equals('https://other.example/resource'));
      });

      test('handles complex base URIs with paths and fragments', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/path/to/');

        final serializer = provider.serializer(
            'parent', subject, serializationContext) as IriRelativeSerializer;
        final deserializer = provider.deserializer(
            subject, deserializationContext) as IriRelativeDeserializer;

        // Test relative resolution from complex base
        final result =
            serializer.toRdfTerm('../other.html', serializationContext);
        expect(result.value, equals('https://example.org/path/other.html'));

        // Test relativization back to complex base
        final absoluteIri =
            const IriTerm('https://example.org/path/other.html');
        final relativized =
            deserializer.fromRdfTerm(absoluteIri, deserializationContext);
        expect(relativized, equals('../other.html'));
      });
    });

    group('Type Safety', () {
      test('works with different parent types', () {
        // Test with String parent type
        const stringProvider = IriRelativeSerializationProvider<String>();

        // Test with Map parent type
        const mapProvider =
            IriRelativeSerializationProvider<Map<String, dynamic>>();

        // Test with custom class parent type
        const customProvider = IriRelativeSerializationProvider<Person>();

        final subject = const IriTerm('https://example.org/doc');

        // All should work with their respective parent types
        expect(
          () => stringProvider.serializer(
              'string-parent', subject, serializationContext),
          returnsNormally,
        );

        expect(
          () => mapProvider
              .serializer({'key': 'value'}, subject, serializationContext),
          returnsNormally,
        );

        expect(
          () => customProvider.serializer(
              Person('test', 'Test Person'), subject, serializationContext),
          returnsNormally,
        );
      });
    });

    group('Roundtrip Tests', () {
      test('serialization and deserialization are consistent', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/base/doc');

        final serializer = provider.serializer(
            'parent', subject, serializationContext) as IriRelativeSerializer;
        final deserializer = provider.deserializer(
            subject, deserializationContext) as IriRelativeDeserializer;

        const originalRelativeIri = 'resources/item.html';

        // Serialize to absolute IRI term
        final iriTerm =
            serializer.toRdfTerm(originalRelativeIri, serializationContext);

        // Deserialize back to relative string
        final roundtrippedIri =
            deserializer.fromRdfTerm(iriTerm, deserializationContext);

        expect(roundtrippedIri, equals(originalRelativeIri));
      });

      test('works with various relative IRI patterns', () {
        const provider = IriRelativeSerializationProvider<String>();
        final subject = const IriTerm('https://example.org/docs/');

        final serializer = provider.serializer(
            'parent', subject, serializationContext) as IriRelativeSerializer;
        final deserializer = provider.deserializer(
            subject, deserializationContext) as IriRelativeDeserializer;

        final testCases = [
          'resource.html', // Same directory
          '/other.html', // Parent directory
          'subdir/file.html', // Subdirectory
        ];

        for (final testIri in testCases) {
          final iriTerm = serializer.toRdfTerm(testIri, serializationContext);
          final roundtripped =
              deserializer.fromRdfTerm(iriTerm, deserializationContext);

          expect(
            roundtripped,
            equals(testIri),
            reason: 'Failed roundtrip for IRI: $testIri',
          );
        }
      });
    });
  });
}

/// Test person class for type safety testing
class Person {
  final String id;
  final String name;
  const Person(this.id, this.name);
}

/// Test document class for type safety testing
class TestDocument {
  final String name;
  const TestDocument(this.name);
}

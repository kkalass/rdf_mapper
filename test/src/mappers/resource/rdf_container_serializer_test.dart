import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_serializer.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

/// Custom serializer for testing purposes
class UpperCaseStringSerializer implements LiteralTermSerializer<String> {
  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm.string(value.toUpperCase());
  }
}

/// Test class for resource serialization
class TestPerson {
  final String iri;

  TestPerson(this.iri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          iri == other.iri;

  @override
  int get hashCode => iri.hashCode;

  @override
  String toString() => 'TestPerson($iri)';
}

class TestPersonSerializer implements GlobalResourceSerializer<TestPerson> {
  @override
  IriTerm get typeIri => const IriTerm('http://test.org/Person');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(
        'http://test.org/person/${instance.iri.split('/').last}');
    final triples = [
      Triple(subject, Rdf.type, typeIri),
    ];
    return (subject, triples);
  }
}

void main() {
  late RdfMapperRegistry registry;
  late SerializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
    context = SerializationContextImpl(registry: registry);
  });

  /// Helper to find triples by predicate
  Iterable<Triple> findTriplesByPredicate(
      Iterable<Triple> triples, RdfObject predicate) {
    return triples.where((t) => t.predicate == predicate).toList();
  }

  /// Helper to find triples with numbered properties
  Map<int, Triple> findNumberedTriples(Iterable<Triple> triples) {
    final numberedTriples = <int, Triple>{};
    final rdfNamespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

    for (final triple in triples) {
      if (triple.predicate is IriTerm) {
        final predicateIri = (triple.predicate as IriTerm).value;
        if (predicateIri.startsWith('${rdfNamespace}_')) {
          final numberStr = predicateIri.substring('${rdfNamespace}_'.length);
          final number = int.tryParse(numberStr);
          if (number != null && number > 0) {
            numberedTriples[number] = triple;
          }
        }
      }
    }
    return numberedTriples;
  }

  group('RDF Container Serializers', () {
    group('RdfSeqSerializer', () {
      test('serializes ordered sequence', () {
        final items = ['Chapter 1', 'Chapter 2', 'Chapter 3'];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Check container type
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Seq));

        // Check numbered properties
        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));

        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('Chapter 1'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('Chapter 2'));
        expect((numberedTriples[3]!.object as LiteralTerm).value,
            equals('Chapter 3'));
      });

      test('serializes empty list', () {
        final items = <String>[];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Should only have type declaration
        expect(triples, hasLength(1));
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Seq));
      });

      test('serializes with custom item serializer', () {
        final items = ['hello', 'world'];

        final serializer = RdfSeqSerializer<String>(
            itemSerializer: UpperCaseStringSerializer());
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);
        expect(
            (numberedTriples[1]!.object as LiteralTerm).value, equals('HELLO'));
        expect(
            (numberedTriples[2]!.object as LiteralTerm).value, equals('WORLD'));
      });

      test('serializes resource items', () {
        final items = [
          TestPerson('http://test.org/person1'),
          TestPerson('http://test.org/person2')
        ];

        registry.registerSerializer(TestPersonSerializer());

        final serializer = RdfSeqSerializer<TestPerson>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2]));

        // Items should be serialized as IRIs pointing to the person resources
        expect(numberedTriples[1]!.object, isA<IriTerm>());
        expect(numberedTriples[2]!.object, isA<IriTerm>());
      });

      test('handles large collections', () {
        final items = List.generate(100, (i) => 'Item ${i + 1}');

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Should have type + 100 numbered properties
        expect(triples, hasLength(101));

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.length, equals(100));
        expect(numberedTriples.keys.toList()..sort(),
            equals(List.generate(100, (i) => i + 1)));
      });

      test('preserves order in serialization', () {
        final items = ['Z', 'A', 'M', 'B'];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);

        // Should maintain the original order Z, A, M, B
        expect((numberedTriples[1]!.object as LiteralTerm).value, equals('Z'));
        expect((numberedTriples[2]!.object as LiteralTerm).value, equals('A'));
        expect((numberedTriples[3]!.object as LiteralTerm).value, equals('M'));
        expect((numberedTriples[4]!.object as LiteralTerm).value, equals('B'));
      });
    });

    group('RdfBagSerializer', () {
      test('serializes unordered bag', () {
        final items = ['Apple', 'Banana', 'Cherry'];

        final serializer = RdfBagSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Check container type
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Bag));

        // Check numbered properties
        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));

        // Extract values in numerical order
        final values = numberedTriples.keys.toList()..sort();
        final actualValues = values
            .map((key) => (numberedTriples[key]!.object as LiteralTerm).value)
            .toList();
        expect(actualValues, equals(['Apple', 'Banana', 'Cherry']));
      });

      test('allows duplicate values', () {
        final items = ['Apple', 'Apple', 'Banana'];

        final serializer = RdfBagSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));

        expect(
            (numberedTriples[1]!.object as LiteralTerm).value, equals('Apple'));
        expect(
            (numberedTriples[2]!.object as LiteralTerm).value, equals('Apple'));
        expect((numberedTriples[3]!.object as LiteralTerm).value,
            equals('Banana'));
      });

      test('serializes with custom item serializer', () {
        final items = ['test', 'data'];

        final serializer = RdfBagSerializer<String>(
            itemSerializer: UpperCaseStringSerializer());
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);
        expect(
            (numberedTriples[1]!.object as LiteralTerm).value, equals('TEST'));
        expect(
            (numberedTriples[2]!.object as LiteralTerm).value, equals('DATA'));
      });

      test('serializes empty bag', () {
        final items = <String>[];

        final serializer = RdfBagSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Should only have type declaration
        expect(triples, hasLength(1));
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Bag));
      });
    });

    group('RdfAltSerializer', () {
      test('serializes alternative values', () {
        final items = ['Primary choice', 'Secondary choice', 'Fallback choice'];

        final serializer = RdfAltSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Check container type
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Alt));

        // Check numbered properties
        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));

        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('Primary choice'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('Secondary choice'));
        expect((numberedTriples[3]!.object as LiteralTerm).value,
            equals('Fallback choice'));
      });

      test('preserves preference order', () {
        final items = ['High priority', 'Medium priority', 'Low priority'];

        final serializer = RdfAltSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);

        // Should preserve order indicating preference
        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('High priority'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('Medium priority'));
        expect((numberedTriples[3]!.object as LiteralTerm).value,
            equals('Low priority'));
      });

      test('handles single alternative', () {
        final items = ['Only choice'];

        final serializer = RdfAltSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Check type and single item
        expect(triples, hasLength(2));
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples.first.object, equals(Rdf.Alt));

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys, equals([1]));
        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('Only choice'));
      });

      test('serializes empty alternatives', () {
        final items = <String>[];

        final serializer = RdfAltSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Should only have type declaration
        expect(triples, hasLength(1));
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Alt));
      });
    });

    group('Common Container Serialization Features', () {
      test('all container types produce consistent structure', () {
        final items = ['Test item'];

        final seqResult =
            RdfSeqSerializer<String>().toRdfResource(items, context);
        final bagResult =
            RdfBagSerializer<String>().toRdfResource(items, context);
        final altResult =
            RdfAltSerializer<String>().toRdfResource(items, context);

        // All should have same structure: one type triple + one numbered property
        expect(seqResult.$2, hasLength(2));
        expect(bagResult.$2, hasLength(2));
        expect(altResult.$2, hasLength(2));

        // All should have _1 property with same value
        final seqNumbered = findNumberedTriples(seqResult.$2);
        final bagNumbered = findNumberedTriples(bagResult.$2);
        final altNumbered = findNumberedTriples(altResult.$2);

        expect(seqNumbered[1]!.object, equals(bagNumbered[1]!.object));
        expect(bagNumbered[1]!.object, equals(altNumbered[1]!.object));
      });

      test('handles non-null items correctly', () {
        final items = <String>['Valid', 'Also valid'];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Should serialize all items
        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2]));

        expect(
            (numberedTriples[1]!.object as LiteralTerm).value, equals('Valid'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('Also valid'));
      });

      test('uses consistent subject across calls', () {
        final items = ['Test'];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // All triples should use the same subject
        for (final triple in triples) {
          expect(triple.subject, equals(subject));
        }
      });

      test('integrates with serialization context correctly', () {
        final items = ['Context test'];

        final serializer = RdfSeqSerializer<String>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        // Verify context is passed through (this tests the integration)
        expect(triples, isNotEmpty);
        expect(findTriplesByPredicate(triples, Rdf.type), hasLength(1));
      });
    });

    group('Performance and Edge Cases', () {
      test('handles very large containers efficiently', () {
        final items = List.generate(1000, (i) => 'Item $i');

        final serializer = RdfSeqSerializer<String>();
        final stopwatch = Stopwatch()..start();
        final (subject, triples) = serializer.toRdfResource(items, context);
        stopwatch.stop();

        // Should complete in reasonable time and produce correct count
        expect(triples, hasLength(1001)); // Type + 1000 items
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.length, equals(1000));
      });

      test('handles mixed data types in generic containers', () {
        final items = <Object>['String', 42, true];

        final serializer = RdfSeqSerializer<Object>();
        final (subject, triples) = serializer.toRdfResource(items, context);

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));

        // Should serialize different types appropriately
        expect(numberedTriples[1]!.object, isA<LiteralTerm>());
        expect(numberedTriples[2]!.object, isA<LiteralTerm>());
        expect(numberedTriples[3]!.object, isA<LiteralTerm>());
      });
    });
  });
}

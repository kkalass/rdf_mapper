import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

/// Test vocabulary for consistent property naming
class TestVocab {
  static final chapters = const IriTerm('http://test.org/chapters');
  static final titles = const IriTerm('http://test.org/titles');
  static final tags = const IriTerm('http://test.org/tags');
  static final contributors = const IriTerm('http://test.org/contributors');
}

/// Test class for complex object serialization/deserialization
class TestAuthor {
  final String name;
  final String email;

  TestAuthor(this.name, this.email);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestAuthor && name == other.name && email == other.email;

  @override
  int get hashCode => Object.hash(name, email);

  @override
  String toString() => 'TestAuthor(name: $name, email: $email)';
}

class TestAuthorMapper implements GlobalResourceMapper<TestAuthor> {
  @override
  final IriTerm typeIri = const IriTerm('http://test.org/Author');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      TestAuthor value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(
        'http://test.org/author/${value.name.replaceAll(' ', '_')}');
    final triples = [
      Triple(subject, const IriTerm('http://test.org/name'),
          LiteralTerm.string(value.name)),
      Triple(subject, const IriTerm('http://test.org/email'),
          LiteralTerm.string(value.email)),
    ];
    return (subject, triples);
  }

  @override
  TestAuthor fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name = reader.require<String>(const IriTerm('http://test.org/name'));
    final email =
        reader.require<String>(const IriTerm('http://test.org/email'));
    return TestAuthor(name, email);
  }
}

/// Custom serializer/deserializer for testing
class UpperCaseStringMapper implements LiteralTermMapper<String> {
  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm.string(value.toUpperCase());
  }

  @override
  IriTerm get datatype => Xsd.string;

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toLowerCase(); // Convert back to lowercase for testing
  }
}

void main() {
  late RdfMapperRegistry registry;
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;
  late RdfGraph graph;

  setUp(() {
    registry = RdfMapperRegistry();
    registry.registerMapper(TestAuthorMapper());
    serializationContext = SerializationContextImpl(registry: registry);
    graph = RdfGraph(triples: []);
    deserializationContext = DeserializationContextImpl(
      graph: graph,
      registry: registry,
    );
  });

  /// Helper to create RDF numbered property IRIs (rdf:_1, rdf:_2, etc.)
  IriTerm rdfLi(int number) =>
      IriTerm.validated('http://www.w3.org/1999/02/22-rdf-syntax-ns#_$number');

  /// Helper to find triples by predicate
  Iterable<Triple> findTriplesByPredicate(
      Iterable<Triple> triples, RdfPredicate predicate) {
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

  group('RdfSeqMapper', () {
    group('Constructor and Type Tests', () {
      test('RdfSeqMapper.new is a valid CollectionMapperFactory', () {
        // The default constructor should be assignable to CollectionMapperFactory
        CollectionMapperFactory<List<String>, String> factory =
            RdfSeqMapper.new;

        // Should be able to call it as a factory function
        final mapper = factory();
        expect(mapper, isA<RdfSeqMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test('creates mapper with correct type constraints', () {
        final stringMapper = RdfSeqMapper<String>();
        final authorMapper =
            RdfSeqMapper<TestAuthor>(itemMapper: TestAuthorMapper());

        expect(stringMapper, isA<RdfSeqMapper<String>>());
        expect(stringMapper, isA<UnifiedResourceMapper<List<String>>>());
        expect(authorMapper, isA<RdfSeqMapper<TestAuthor>>());
        expect(authorMapper, isA<UnifiedResourceMapper<List<TestAuthor>>>());
      });

      test('type IRI should be rdf:Seq', () {
        final mapper = RdfSeqMapper<String>();
        expect(mapper.typeIri, equals(Rdf.Seq));
      });
    });

    group('Serialization Tests', () {
      test('serializes empty list correctly', () {
        final mapper = RdfSeqMapper<String>();
        final (subject, triples) = mapper.toRdfResource(
          [],
          serializationContext,
        );

        // Empty lists should result in minimal structure
        expect(triples, hasLength(1)); // Only type triple
        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Seq));
      });

      test('serializes string list with numbered properties', () {
        final mapper = RdfSeqMapper<String>();
        final values = ['first', 'second', 'third'];

        final (subject, triples) = mapper.toRdfResource(
          values,
          serializationContext,
        );

        // Should have type triple + numbered property triples
        expect(triples.length, greaterThan(3));

        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Seq));

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples, hasLength(3));
        expect(numberedTriples[1]?.object, equals(LiteralTerm.string('first')));
        expect(
            numberedTriples[2]?.object, equals(LiteralTerm.string('second')));
        expect(numberedTriples[3]?.object, equals(LiteralTerm.string('third')));
      });

      test('serializes complex objects with custom mapper', () {
        final authors = [
          TestAuthor('Alice Smith', 'alice@example.com'),
          TestAuthor('Bob Jones', 'bob@example.com'),
        ];
        final mapper = RdfSeqMapper<TestAuthor>(itemMapper: TestAuthorMapper());

        final (subject, triples) = mapper.toRdfResource(
          authors,
          serializationContext,
        );

        // Should include triples for the authors themselves
        expect(
            triples.length, greaterThan(6)); // Type + 2 numbered + author data

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples, hasLength(2));

        // Verify author data is included
        final authorTriples = triples
            .where((t) =>
                t.predicate.toString().contains('name') ||
                t.predicate.toString().contains('email'))
            .toList();
        expect(authorTriples, hasLength(4)); // 2 authors × 2 properties each
      });

      test('uses custom item serializer when provided', () {
        final values = ['test', 'example'];
        final mapper =
            RdfSeqMapper<String>(itemMapper: UpperCaseStringMapper());

        final (subject, triples) = mapper.toRdfResource(
          values,
          serializationContext,
        );

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples[1]?.object, equals(LiteralTerm.string('TEST')));
        expect(
            numberedTriples[2]?.object, equals(LiteralTerm.string('EXAMPLE')));
      });
    });

    group('Deserialization Tests', () {
      test('deserializes empty sequence correctly', () {
        final subject = BlankNodeTerm();
        graph = RdfGraph(triples: [
          Triple(subject, Rdf.type, Rdf.Seq),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfSeqMapper<String>();
        final result = mapper.fromRdfResource(subject, deserializationContext);

        expect(result, equals(<String>[]));
      });

      test('deserializes string sequence with order preservation', () {
        final subject = BlankNodeTerm();
        graph = RdfGraph(triples: [
          Triple(subject, Rdf.type, Rdf.Seq),
          Triple(subject, rdfLi(1), LiteralTerm.string('first')),
          Triple(subject, rdfLi(2), LiteralTerm.string('second')),
          Triple(subject, rdfLi(3), LiteralTerm.string('third')),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfSeqMapper<String>();
        final result = mapper.fromRdfResource(subject, deserializationContext);

        expect(result, equals(['first', 'second', 'third']));
      });

      test('deserializes complex objects with custom mapper', () {
        final seqSubject = BlankNodeTerm();
        final author1Subject =
            const IriTerm('http://test.org/author/Alice_Smith');
        final author2Subject =
            const IriTerm('http://test.org/author/Bob_Jones');

        graph = RdfGraph(triples: [
          // Setup sequence structure
          Triple(seqSubject, Rdf.type, Rdf.Seq),
          Triple(seqSubject, rdfLi(1), author1Subject),
          Triple(seqSubject, rdfLi(2), author2Subject),

          // Setup author data
          Triple(author1Subject, const IriTerm('http://test.org/name'),
              LiteralTerm.string('Alice Smith')),
          Triple(author1Subject, const IriTerm('http://test.org/email'),
              LiteralTerm.string('alice@example.com')),
          Triple(author2Subject, const IriTerm('http://test.org/name'),
              LiteralTerm.string('Bob Jones')),
          Triple(author2Subject, const IriTerm('http://test.org/email'),
              LiteralTerm.string('bob@example.com')),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfSeqMapper<TestAuthor>(itemMapper: TestAuthorMapper());
        final result =
            mapper.fromRdfResource(seqSubject, deserializationContext);

        expect(result, hasLength(2));
        expect(
            result[0], equals(TestAuthor('Alice Smith', 'alice@example.com')));
        expect(result[1], equals(TestAuthor('Bob Jones', 'bob@example.com')));
      });

      test('handles non-sequential numbering gracefully', () {
        final subject = BlankNodeTerm();
        graph = RdfGraph(triples: [
          Triple(subject, Rdf.type, Rdf.Seq),
          // Intentionally skip rdf:_2
          Triple(subject, rdfLi(1), LiteralTerm.string('first')),
          Triple(subject, rdfLi(3), LiteralTerm.string('third')),
          Triple(subject, rdfLi(5), LiteralTerm.string('fifth')),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfSeqMapper<String>();
        final result = mapper.fromRdfResource(subject, deserializationContext);

        // Should handle gaps in numbering
        expect(result, equals(['first', 'third', 'fifth']));
      });
    });

    group('Round-trip Tests', () {
      test('preserves order through serialization and deserialization', () {
        final original = ['alpha', 'beta', 'gamma', 'delta'];
        final mapper = RdfSeqMapper<String>();

        // Serialize
        final (subject, triples) =
            mapper.toRdfResource(original, serializationContext);

        // Add to graph
        final testGraph = RdfGraph.fromTriples(triples);
        final testContext = DeserializationContextImpl(
          graph: testGraph,
          registry: registry,
        );

        // Deserialize
        final result = mapper.fromRdfResource(subject, testContext);

        expect(result, equals(original));
      });

      test('works with complex objects through round-trip', () {
        final original = [
          TestAuthor('Alice Smith', 'alice@example.com'),
          TestAuthor('Bob Jones', 'bob@example.com'),
          TestAuthor('Carol Davis', 'carol@example.com'),
        ];
        final mapper = RdfSeqMapper<TestAuthor>(itemMapper: TestAuthorMapper());

        // Serialize
        final (subject, triples) =
            mapper.toRdfResource(original, serializationContext);

        // Add to graph
        final testGraph = RdfGraph.fromTriples(triples);
        final testContext = DeserializationContextImpl(
          graph: testGraph,
          registry: registry,
        );

        // Deserialize
        final result = mapper.fromRdfResource(subject, testContext);

        expect(result, equals(original));
      });
    });
  });

  group('RdfAltMapper', () {
    group('Constructor and Type Tests', () {
      test('RdfAltMapper.new is a valid CollectionMapperFactory', () {
        CollectionMapperFactory<List<String>, String> factory =
            RdfAltMapper.new;

        final mapper = factory();
        expect(mapper, isA<RdfAltMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test('type IRI should be rdf:Alt', () {
        final mapper = RdfAltMapper<String>();
        expect(mapper.typeIri, equals(Rdf.Alt));
      });
    });

    group('Serialization Tests', () {
      test('serializes alternative titles correctly', () {
        final alternatives = ['English Title', 'German Title', 'French Title'];
        final mapper = RdfAltMapper<String>();

        final (subject, triples) = mapper.toRdfResource(
          alternatives,
          serializationContext,
        );

        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples.first.object, equals(Rdf.Alt));

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples, hasLength(3));
        expect(numberedTriples[1]?.object,
            equals(LiteralTerm.string('English Title')));
        expect(numberedTriples[2]?.object,
            equals(LiteralTerm.string('German Title')));
        expect(numberedTriples[3]?.object,
            equals(LiteralTerm.string('French Title')));
      });
    });

    group('Deserialization Tests', () {
      test('deserializes alternatives maintaining preference order', () {
        final subject = BlankNodeTerm();
        graph = RdfGraph(triples: [
          Triple(subject, Rdf.type, Rdf.Alt),
          Triple(subject, rdfLi(1), LiteralTerm.string('Preferred Title')),
          Triple(subject, rdfLi(2), LiteralTerm.string('Secondary Title')),
          Triple(subject, rdfLi(3), LiteralTerm.string('Fallback Title')),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfAltMapper<String>();
        final result = mapper.fromRdfResource(subject, deserializationContext);

        expect(result,
            equals(['Preferred Title', 'Secondary Title', 'Fallback Title']));
      });
    });

    group('Round-trip Tests', () {
      test('preserves preference order through round-trip', () {
        final original = ['Primary', 'Secondary', 'Tertiary'];
        final mapper = RdfAltMapper<String>();

        final (subject, triples) =
            mapper.toRdfResource(original, serializationContext);

        final testGraph = RdfGraph.fromTriples(triples);
        final testContext = DeserializationContextImpl(
          graph: testGraph,
          registry: registry,
        );

        final result = mapper.fromRdfResource(subject, testContext);
        expect(result, equals(original));
      });
    });
  });

  group('RdfBagMapper', () {
    group('Constructor and Type Tests', () {
      test('RdfBagMapper.new is a valid CollectionMapperFactory', () {
        CollectionMapperFactory<List<String>, String> factory =
            RdfBagMapper.new;

        final mapper = factory();
        expect(mapper, isA<RdfBagMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test('type IRI should be rdf:Bag', () {
        final mapper = RdfBagMapper<String>();
        expect(mapper.typeIri, equals(Rdf.Bag));
      });
    });

    group('Serialization Tests', () {
      test('serializes unordered collections correctly', () {
        final tags = ['science', 'technology', 'programming', 'dart'];
        final mapper = RdfBagMapper<String>();

        final (subject, triples) = mapper.toRdfResource(
          tags,
          serializationContext,
        );

        final typeTriples = findTriplesByPredicate(triples, Rdf.type);
        expect(typeTriples.first.object, equals(Rdf.Bag));

        final numberedTriples = findNumberedTriples(triples);
        expect(numberedTriples, hasLength(4));

        // Verify all elements are present (order may vary in concept but is preserved in implementation)
        final values = numberedTriples.values
            .map((t) => (t.object as LiteralTerm).value)
            .toSet();
        expect(values,
            containsAll(['science', 'technology', 'programming', 'dart']));
      });

      test('handles duplicate values in bag', () {
        final duplicates = ['tag1', 'tag2', 'tag1', 'tag3', 'tag2'];
        final mapper = RdfBagMapper<String>();

        final (subject, triples) = mapper.toRdfResource(
          duplicates,
          serializationContext,
        );

        final numberedTriples = findNumberedTriples(triples);
        expect(
            numberedTriples, hasLength(5)); // All elements including duplicates
      });
    });

    group('Deserialization Tests', () {
      test('deserializes bag maintaining all elements', () {
        final subject = BlankNodeTerm();
        graph = RdfGraph(triples: [
          Triple(subject, Rdf.type, Rdf.Bag),
          Triple(subject, rdfLi(1), LiteralTerm.string('keyword1')),
          Triple(subject, rdfLi(2), LiteralTerm.string('keyword2')),
          Triple(subject, rdfLi(3), LiteralTerm.string('keyword3')),
        ]);
        deserializationContext = DeserializationContextImpl(
          graph: graph,
          registry: registry,
        );

        final mapper = RdfBagMapper<String>();
        final result = mapper.fromRdfResource(subject, deserializationContext);

        expect(result, hasLength(3));
        expect(result, containsAll(['keyword1', 'keyword2', 'keyword3']));
      });
    });

    group('Round-trip Tests', () {
      test('preserves all elements through round-trip', () {
        final original = [
          'alpha',
          'beta',
          'gamma',
          'alpha'
        ]; // Including duplicate
        final mapper = RdfBagMapper<String>();

        final (subject, triples) =
            mapper.toRdfResource(original, serializationContext);

        final testGraph = RdfGraph.fromTriples(triples);
        final testContext = DeserializationContextImpl(
          graph: testGraph,
          registry: registry,
        );

        final result = mapper.fromRdfResource(subject, testContext);
        expect(result, equals(original));
      });
    });
  });

  group('Factory Pattern Compatibility', () {
    test('all mappers work with CollectionMapperFactory pattern', () {
      final factories = <String, CollectionMapperFactory<List<String>, String>>{
        'seq': RdfSeqMapper.new,
        'alt': RdfAltMapper.new,
        'bag': RdfBagMapper.new,
      };

      for (final entry in factories.entries) {
        final factory = entry.value;
        final mapper = factory();

        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());

        // Test basic serialization works
        final (_, triples) = (mapper as UnifiedResourceMapper<List<String>>)
            .toRdfResource(['test'], serializationContext);
        expect(triples, isNotEmpty);
      }
    });

    test('factory functions support custom item mappers', () {
      final authorFactory = (Mapper<TestAuthor>? mapper) =>
          RdfSeqMapper<TestAuthor>(itemMapper: mapper);

      final defaultMapper = authorFactory(null);
      final customMapper = authorFactory(TestAuthorMapper());

      expect(defaultMapper, isA<RdfSeqMapper<TestAuthor>>());
      expect(customMapper, isA<RdfSeqMapper<TestAuthor>>());
    });
  });

  group('Error Handling', () {
    test('throws error for malformed RDF container without type', () {
      final subject = BlankNodeTerm();
      // Missing type declaration
      graph = RdfGraph(triples: [
        Triple(subject, rdfLi(1), LiteralTerm.string('orphaned')),
      ]);
      deserializationContext = DeserializationContextImpl(
        graph: graph,
        registry: registry,
      );

      final mapper = RdfSeqMapper<String>();

      // Should throw error for missing rdf:type declaration
      expect(() => mapper.fromRdfResource(subject, deserializationContext),
          throwsArgumentError);
    });
  });
}

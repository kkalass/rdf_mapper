import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/resource_reader.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

/// Test vocabulary for consistent property naming
class TestVocab {
  static final chapters = const IriTerm('http://test.org/chapters');
  static final keywords = const IriTerm('http://test.org/keywords');
  static final alternatives = const IriTerm('http://test.org/alternatives');
  static final contributors = const IriTerm('http://test.org/contributors');
  static final priorities = const IriTerm('http://test.org/priorities');
  static final formats = const IriTerm('http://test.org/formats');
}

/// Custom serializer/deserializer for testing
class UpperCaseStringSerializer implements LiteralTermSerializer<String> {
  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm.string(value.toUpperCase());
  }
}

class UpperCaseStringDeserializer implements LiteralTermDeserializer<String> {
  @override
  IriTerm get datatype => Xsd.string;

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toUpperCase();
  }
}

/// Test class for complex object serialization/deserialization
class TestAuthor {
  final String name;
  final String email;

  TestAuthor(this.name, this.email);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestAuthor &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(name, email);

  @override
  String toString() => 'TestAuthor($name, $email)';
}

class TestAuthorSerializer implements GlobalResourceSerializer<TestAuthor> {
  @override
  IriTerm get typeIri => const IriTerm('http://test.org/Author');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      TestAuthor instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(
        'http://test.org/author/${Uri.encodeComponent(instance.name)}');
    final triples = [
      Triple(subject, Rdf.type, typeIri),
      Triple(subject, const IriTerm('http://test.org/name'),
          LiteralTerm.string(instance.name)),
      Triple(subject, const IriTerm('http://test.org/email'),
          LiteralTerm.string(instance.email)),
    ];
    return (subject, triples);
  }
}

class TestAuthorDeserializer implements GlobalResourceDeserializer<TestAuthor> {
  @override
  final IriTerm typeIri = const IriTerm('http://test.org/Author');

  @override
  TestAuthor fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    final name = reader.require<String>(const IriTerm('http://test.org/name'));
    final email =
        reader.require<String>(const IriTerm('http://test.org/email'));
    return TestAuthor(name, email);
  }
}

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl deserializationContext;
  late SerializationContextImpl serializationContext;

  setUp(() {
    registry = RdfMapperRegistry();
    registry.registerSerializer(TestAuthorSerializer());
    registry.registerDeserializer(TestAuthorDeserializer());
  });

  /// Helper to create RDF numbered property IRIs (rdf:_1, rdf:_2, etc.)
  IriTerm rdfLi(int number) =>
      IriTerm.validated('http://www.w3.org/1999/02/22-rdf-syntax-ns#_$number');

  group('ResourceReader RDF Container Methods', () {
    group('requireRdfSeq', () {
      test('reads ordered sequence successfully', () {
        final subject = const IriTerm('http://test.org/book');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.chapters, container),
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('Introduction')),
          Triple(container, rdfLi(2), LiteralTerm.string('Methods')),
          Triple(container, rdfLi(3), LiteralTerm.string('Results')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final chapters = reader.requireRdfSeq<String>(TestVocab.chapters);

        expect(chapters, equals(['Introduction', 'Methods', 'Results']));
      });

      test('reads sequence with custom item deserializer', () {
        final subject = const IriTerm('http://test.org/document');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.keywords, container),
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('important')),
          Triple(container, rdfLi(2), LiteralTerm.string('research')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final keywords = reader.requireRdfSeq<String>(TestVocab.keywords,
            itemDeserializer: UpperCaseStringDeserializer());

        expect(keywords, equals(['IMPORTANT', 'RESEARCH']));
      });

      test('reads sequence with complex objects', () {
        final subject = const IriTerm('http://test.org/project');
        final container = BlankNodeTerm();
        final author1 = const IriTerm('http://test.org/author/Alice');
        final author2 = const IriTerm('http://test.org/author/Bob');

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.contributors, container),
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), author1),
          Triple(container, rdfLi(2), author2),
          // Author 1 data
          Triple(author1, Rdf.type, const IriTerm('http://test.org/Author')),
          Triple(author1, const IriTerm('http://test.org/name'),
              LiteralTerm.string('Alice')),
          Triple(author1, const IriTerm('http://test.org/email'),
              LiteralTerm.string('alice@test.org')),
          // Author 2 data
          Triple(author2, Rdf.type, const IriTerm('http://test.org/Author')),
          Triple(author2, const IriTerm('http://test.org/name'),
              LiteralTerm.string('Bob')),
          Triple(author2, const IriTerm('http://test.org/email'),
              LiteralTerm.string('bob@test.org')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final contributors =
            reader.requireRdfSeq<TestAuthor>(TestVocab.contributors);

        expect(contributors.length, equals(2));
        expect(contributors[0], equals(TestAuthor('Alice', 'alice@test.org')));
        expect(contributors[1], equals(TestAuthor('Bob', 'bob@test.org')));
      });

      test('throws exception when property not found', () {
        final subject = const IriTerm('http://test.org/book');

        graph = RdfGraph(triples: []);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);

        expect(
          () => reader.requireRdfSeq<String>(TestVocab.chapters),
          throwsA(isA<PropertyValueNotFoundException>()),
        );
      });

      test('throws exception when container is wrong type', () {
        final subject = const IriTerm('http://test.org/book');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.chapters, container),
          Triple(container, Rdf.type, Rdf.Bag), // Wrong type - should be Seq
          Triple(container, rdfLi(1), LiteralTerm.string('Chapter 1')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);

        expect(
          () => reader.requireRdfSeq<String>(TestVocab.chapters),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('optionalRdfSeq', () {
      test('reads sequence when present', () {
        final subject = const IriTerm('http://test.org/book');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.chapters, container),
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('Chapter 1')),
          Triple(container, rdfLi(2), LiteralTerm.string('Chapter 2')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final chapters = reader.optionalRdfSeq<String>(TestVocab.chapters);

        expect(chapters, equals(['Chapter 1', 'Chapter 2']));
      });

      test('returns null when property not found', () {
        final subject = const IriTerm('http://test.org/book');

        graph = RdfGraph(triples: []);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final chapters = reader.optionalRdfSeq<String>(TestVocab.chapters);

        expect(chapters, isNull);
      });

      test('returns empty list when container has no items', () {
        final subject = const IriTerm('http://test.org/book');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.chapters, container),
          Triple(container, Rdf.type, Rdf.Seq),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final chapters = reader.optionalRdfSeq<String>(TestVocab.chapters);

        expect(chapters, equals([]));
      });
    });

    group('requireRdfBag', () {
      test('reads unordered bag successfully', () {
        final subject = const IriTerm('http://test.org/article');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.keywords, container),
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(1), LiteralTerm.string('science')),
          Triple(container, rdfLi(2), LiteralTerm.string('research')),
          Triple(container, rdfLi(3), LiteralTerm.string('data')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final keywords = reader.requireRdfBag<String>(TestVocab.keywords);

        expect(keywords.length, equals(3));
        expect(keywords, containsAll(['science', 'research', 'data']));
      });

      test('allows duplicate values in bag', () {
        final subject = const IriTerm('http://test.org/article');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.keywords, container),
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(1), LiteralTerm.string('important')),
          Triple(container, rdfLi(2), LiteralTerm.string('important')),
          Triple(container, rdfLi(3), LiteralTerm.string('data')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final keywords = reader.requireRdfBag<String>(TestVocab.keywords);

        expect(keywords, equals(['important', 'important', 'data']));
      });

      test('throws exception when container is wrong type', () {
        final subject = const IriTerm('http://test.org/article');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.keywords, container),
          Triple(container, Rdf.type, Rdf.Alt), // Wrong type - should be Bag
          Triple(container, rdfLi(1), LiteralTerm.string('keyword')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);

        expect(
          () => reader.requireRdfBag<String>(TestVocab.keywords),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('optionalRdfBag', () {
      test('reads bag when present', () {
        final subject = const IriTerm('http://test.org/article');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.keywords, container),
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(1), LiteralTerm.string('tag1')),
          Triple(container, rdfLi(2), LiteralTerm.string('tag2')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final keywords = reader.optionalRdfBag<String>(TestVocab.keywords);

        expect(keywords, equals(['tag1', 'tag2']));
      });

      test('returns null when property not found', () {
        final subject = const IriTerm('http://test.org/article');

        graph = RdfGraph(triples: []);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final keywords = reader.optionalRdfBag<String>(TestVocab.keywords);

        expect(keywords, isNull);
      });
    });

    group('requireRdfAlt', () {
      test('reads alternatives successfully', () {
        final subject = const IriTerm('http://test.org/image');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.formats, container),
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(1), LiteralTerm.string('PNG')),
          Triple(container, rdfLi(2), LiteralTerm.string('JPEG')),
          Triple(container, rdfLi(3), LiteralTerm.string('WebP')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final formats = reader.requireRdfAlt<String>(TestVocab.formats);

        expect(formats, equals(['PNG', 'JPEG', 'WebP']));
      });

      test('preserves preference order', () {
        final subject = const IriTerm('http://test.org/content');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.priorities, container),
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(3), LiteralTerm.string('Low')),
          Triple(container, rdfLi(1), LiteralTerm.string('High')),
          Triple(container, rdfLi(2), LiteralTerm.string('Medium')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final priorities = reader.requireRdfAlt<String>(TestVocab.priorities);

        expect(priorities, equals(['High', 'Medium', 'Low']));
      });

      test('throws exception when container is wrong type', () {
        final subject = const IriTerm('http://test.org/image');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.formats, container),
          Triple(container, Rdf.type, Rdf.Seq), // Wrong type - should be Alt
          Triple(container, rdfLi(1), LiteralTerm.string('PNG')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);

        expect(
          () => reader.requireRdfAlt<String>(TestVocab.formats),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('optionalRdfAlt', () {
      test('reads alternatives when present', () {
        final subject = const IriTerm('http://test.org/image');
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(subject, TestVocab.formats, container),
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(1), LiteralTerm.string('First choice')),
          Triple(container, rdfLi(2), LiteralTerm.string('Second choice')),
        ]);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final formats = reader.optionalRdfAlt<String>(TestVocab.formats);

        expect(formats, equals(['First choice', 'Second choice']));
      });

      test('returns null when property not found', () {
        final subject = const IriTerm('http://test.org/image');

        graph = RdfGraph(triples: []);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final formats = reader.optionalRdfAlt<String>(TestVocab.formats);

        expect(formats, isNull);
      });
    });
  });

  group('ResourceBuilder RDF Container Methods', () {
    group('addRdfSeq', () {
      test('adds ordered sequence successfully', () {
        final subject = const IriTerm('http://test.org/book');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(
            TestVocab.chapters, ['Introduction', 'Methods', 'Results']);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.chapters).toList();
        expect(propertyTriples, hasLength(1));

        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should have type declaration and 3 numbered properties
        expect(containerTriples, hasLength(4));

        final typeTriples =
            containerTriples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Seq));

        // Check numbered properties
        final numberedTriples = <int, Triple>{};
        for (final triple in containerTriples) {
          if (triple.predicate is IriTerm) {
            final iri = (triple.predicate as IriTerm).value;
            if (iri
                .startsWith('http://www.w3.org/1999/02/22-rdf-syntax-ns#_')) {
              final number = int.tryParse(iri.substring(
                  'http://www.w3.org/1999/02/22-rdf-syntax-ns#_'.length));
              if (number != null) {
                numberedTriples[number] = triple;
              }
            }
          }
        }

        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));
        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('Introduction'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('Methods'));
        expect((numberedTriples[3]!.object as LiteralTerm).value,
            equals('Results'));
      });

      test('adds sequence with custom item serializer', () {
        final subject = const IriTerm('http://test.org/document');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(TestVocab.keywords, ['important', 'research'],
            itemSerializer: UpperCaseStringSerializer());

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.keywords).toList();
        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Find the numbered properties and check they were serialized with uppercase
        final numberedTriples = <int, Triple>{};
        for (final triple in containerTriples) {
          if (triple.predicate is IriTerm) {
            final iri = (triple.predicate as IriTerm).value;
            if (iri
                .startsWith('http://www.w3.org/1999/02/22-rdf-syntax-ns#_')) {
              final number = int.tryParse(iri.substring(
                  'http://www.w3.org/1999/02/22-rdf-syntax-ns#_'.length));
              if (number != null) {
                numberedTriples[number] = triple;
              }
            }
          }
        }

        expect((numberedTriples[1]!.object as LiteralTerm).value,
            equals('IMPORTANT'));
        expect((numberedTriples[2]!.object as LiteralTerm).value,
            equals('RESEARCH'));
      });

      test('adds sequence with complex objects', () {
        final subject = const IriTerm('http://test.org/project');
        serializationContext = SerializationContextImpl(registry: registry);

        final authors = [
          TestAuthor('Alice', 'alice@test.org'),
          TestAuthor('Bob', 'bob@test.org'),
        ];

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(TestVocab.contributors, authors);

        final (_, triples) = builder.build();

        // Should have created author resources
        final authorTriples = triples
            .where((t) =>
                t.predicate == const IriTerm('http://test.org/name') ||
                t.predicate == const IriTerm('http://test.org/email'))
            .toList();
        expect(authorTriples, hasLength(4)); // 2 authors × 2 properties each

        // Should have created sequence container
        final propertyTriples = triples
            .where((t) => t.predicate == TestVocab.contributors)
            .toList();
        expect(propertyTriples, hasLength(1));
      });

      test('adds empty sequence', () {
        final subject = const IriTerm('http://test.org/book');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(TestVocab.chapters, <String>[]);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.chapters).toList();
        expect(propertyTriples, hasLength(1));

        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should only have type declaration for empty sequence
        expect(containerTriples, hasLength(1));
        expect(containerTriples.first.predicate, equals(Rdf.type));
        expect(containerTriples.first.object, equals(Rdf.Seq));
      });
    });

    group('addRdfBag', () {
      test('adds unordered bag successfully', () {
        final subject = const IriTerm('http://test.org/article');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfBag(TestVocab.keywords, ['science', 'research', 'data']);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.keywords).toList();
        expect(propertyTriples, hasLength(1));

        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should have type declaration and 3 numbered properties
        expect(containerTriples, hasLength(4));

        final typeTriples =
            containerTriples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Bag));
      });

      test('allows duplicate values in bag', () {
        final subject = const IriTerm('http://test.org/article');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder
            .addRdfBag(TestVocab.keywords, ['important', 'important', 'data']);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.keywords).toList();
        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should have type + 3 numbered properties (including duplicates)
        expect(containerTriples, hasLength(4));
      });

      test('adds empty bag', () {
        final subject = const IriTerm('http://test.org/article');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfBag(TestVocab.keywords, <String>[]);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.keywords).toList();
        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should only have type declaration
        expect(containerTriples, hasLength(1));
        expect(containerTriples.first.object, equals(Rdf.Bag));
      });
    });

    group('addRdfAlt', () {
      test('adds alternatives successfully', () {
        final subject = const IriTerm('http://test.org/image');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfAlt(TestVocab.formats, ['PNG', 'JPEG', 'WebP']);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.formats).toList();
        expect(propertyTriples, hasLength(1));

        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should have type declaration and 3 numbered properties
        expect(containerTriples, hasLength(4));

        final typeTriples =
            containerTriples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples, hasLength(1));
        expect(typeTriples.first.object, equals(Rdf.Alt));

        // Check numbered properties preserve order (indicating preference)
        final numberedTriples = <int, Triple>{};
        for (final triple in containerTriples) {
          if (triple.predicate is IriTerm) {
            final iri = (triple.predicate as IriTerm).value;
            if (iri
                .startsWith('http://www.w3.org/1999/02/22-rdf-syntax-ns#_')) {
              final number = int.tryParse(iri.substring(
                  'http://www.w3.org/1999/02/22-rdf-syntax-ns#_'.length));
              if (number != null) {
                numberedTriples[number] = triple;
              }
            }
          }
        }

        expect(numberedTriples.keys.toList()..sort(), equals([1, 2, 3]));
        expect(
            (numberedTriples[1]!.object as LiteralTerm).value, equals('PNG'));
        expect(
            (numberedTriples[2]!.object as LiteralTerm).value, equals('JPEG'));
        expect(
            (numberedTriples[3]!.object as LiteralTerm).value, equals('WebP'));
      });

      test('adds single alternative', () {
        final subject = const IriTerm('http://test.org/content');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfAlt(TestVocab.formats, ['Only choice']);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.formats).toList();
        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should have type + 1 numbered property
        expect(containerTriples, hasLength(2));

        final typeTriples =
            containerTriples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.first.object, equals(Rdf.Alt));
      });

      test('adds empty alternatives', () {
        final subject = const IriTerm('http://test.org/content');
        serializationContext = SerializationContextImpl(registry: registry);

        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfAlt(TestVocab.formats, <String>[]);

        final (_, triples) = builder.build();
        final propertyTriples =
            triples.where((t) => t.predicate == TestVocab.formats).toList();
        final containerSubject = propertyTriples.first.object as RdfSubject;
        final containerTriples =
            triples.where((t) => t.subject == containerSubject).toList();

        // Should only have type declaration
        expect(containerTriples, hasLength(1));
        expect(containerTriples.first.object, equals(Rdf.Alt));
      });
    });

    group('Integration Tests', () {
      test('builder and reader round-trip works correctly', () {
        final subject = const IriTerm('http://test.org/book');
        serializationContext = SerializationContextImpl(registry: registry);

        // Build a resource with all three container types
        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(TestVocab.chapters, ['Intro', 'Body', 'Conclusion']);
        builder
            .addRdfBag(TestVocab.keywords, ['important', 'research', 'study']);
        builder.addRdfAlt(TestVocab.formats, ['PDF', 'HTML', 'EPUB']);

        final (_, triples) = builder.build();

        // Create a new graph and context for reading
        graph = RdfGraph.fromTriples(triples);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        // Read back the data
        final reader = ResourceReader(subject, deserializationContext);
        final chapters = reader.requireRdfSeq<String>(TestVocab.chapters);
        final keywords = reader.requireRdfBag<String>(TestVocab.keywords);
        final formats = reader.requireRdfAlt<String>(TestVocab.formats);

        // Verify round-trip correctness
        expect(chapters, equals(['Intro', 'Body', 'Conclusion']));
        expect(keywords, equals(['important', 'research', 'study']));
        expect(formats, equals(['PDF', 'HTML', 'EPUB']));
      });

      test('complex objects round-trip correctly', () {
        final subject = const IriTerm('http://test.org/project');
        serializationContext = SerializationContextImpl(registry: registry);

        final authors = [
          TestAuthor('Alice', 'alice@test.org'),
          TestAuthor('Bob', 'bob@test.org'),
        ];

        // Build
        final builder = ResourceBuilder(subject, serializationContext);
        builder.addRdfSeq(TestVocab.contributors, authors);

        final (_, triples) = builder.build();

        // Read back
        graph = RdfGraph.fromTriples(triples);
        deserializationContext =
            DeserializationContextImpl(graph: graph, registry: registry);

        final reader = ResourceReader(subject, deserializationContext);
        final readAuthors =
            reader.requireRdfSeq<TestAuthor>(TestVocab.contributors);

        expect(readAuthors.length, equals(2));
        expect(readAuthors[0], equals(TestAuthor('Alice', 'alice@test.org')));
        expect(readAuthors[1], equals(TestAuthor('Bob', 'bob@test.org')));
      });
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late SerializationContext context;

  setUp(() {
    registry = RdfMapperRegistry();
    final contextImpl = SerializationContextImpl(registry: registry);
    context = contextImpl;
  });

  group('ResourceBuilder convenience methods', () {
    group('addRdfList', () {
      test('should serialize a simple list of strings', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');
        final chapters = ['Chapter 1', 'Chapter 2', 'Chapter 3'];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addRdfList(predicate, chapters)
            .build();

        // Should create:
        // - 1 triple linking subject to list head
        // - 3 triples for rdf:first (one per item)
        // - 3 triples for rdf:rest (2 linking to next, 1 linking to rdf:nil)
        // - 1 type triple for the list (rdf:type rdf:List)
        expect(triples.length, equals(8));

        // Find the main triple linking subject to list
        final mainTriples = triples
            .where((t) => t.subject == subject && t.predicate == predicate)
            .toList();
        expect(mainTriples.length, equals(1));

        // Verify list structure
        final firstTriples =
            triples.where((t) => t.predicate == Rdf.first).toList();
        expect(firstTriples.length, equals(3));

        final restTriples =
            triples.where((t) => t.predicate == Rdf.rest).toList();
        expect(restTriples.length, equals(3));

        // Check that all chapter values are present
        final chapterValues =
            firstTriples.map((t) => (t.object as LiteralTerm).value).toSet();
        expect(chapterValues, equals({'Chapter 1', 'Chapter 2', 'Chapter 3'}));

        // Check that one rest triple points to rdf:nil
        final nilTriples =
            restTriples.where((t) => t.object == Rdf.nil).toList();
        expect(nilTriples.length, equals(1));

        // Check type triple
        final typeTriples =
            triples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.length, equals(1));
        expect(typeTriples.first.object, equals(Rdf.List));
      });

      test('should serialize an empty list', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');
        final chapters = <String>[];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addRdfList(predicate, chapters)
            .build();

        // Empty list should just link directly to rdf:nil
        // Plus one type triple for the empty list
        expect(triples.length, equals(2));

        final linkTriple = triples.firstWhere(
            (t) => t.subject == subject && t.predicate == predicate);
        expect(linkTriple.object, equals(Rdf.nil));

        final typeTriple = triples.firstWhere((t) => t.predicate == Rdf.type);
        expect(typeTriple.object, equals(Rdf.List));
      });

      test('should serialize a single-item list', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');
        final chapters = ['Chapter 1'];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addRdfList(predicate, chapters)
            .build();

        // Should create:
        // - 1 triple linking subject to list head
        // - 1 triple for rdf:first
        // - 1 triple for rdf:rest pointing to rdf:nil
        // - 1 type triple for the list
        expect(triples.length, equals(4));

        final mainTriples = triples
            .where((t) => t.subject == subject && t.predicate == predicate)
            .toList();
        expect(mainTriples.length, equals(1));

        final firstTriples =
            triples.where((t) => t.predicate == Rdf.first).toList();
        expect(firstTriples.length, equals(1));
        expect((firstTriples.first.object as LiteralTerm).value,
            equals('Chapter 1'));

        final restTriples =
            triples.where((t) => t.predicate == Rdf.rest).toList();
        expect(restTriples.length, equals(1));
        expect(restTriples.first.object, equals(Rdf.nil));

        final typeTriples =
            triples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.length, equals(1));
        expect(typeTriples.first.object, equals(Rdf.List));
      });

      test('should work with custom item serializer', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');
        final chapters = ['chapter one', 'chapter two'];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addRdfList(predicate, chapters,
                itemSerializer: UpperCaseStringSerializer())
            .build();

        // Should create appropriate triples plus type triple
        expect(triples.length, equals(6)); // 1 main + 2 first + 2 rest + 1 type

        final firstTriples =
            triples.where((t) => t.predicate == Rdf.first).toList();
        expect(firstTriples.length, equals(2));

        final chapterValues =
            firstTriples.map((t) => (t.object as LiteralTerm).value).toSet();
        expect(chapterValues, equals({'CHAPTER ONE', 'CHAPTER TWO'}));

        final typeTriples =
            triples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.length, equals(1));
        expect(typeTriples.first.object, equals(Rdf.List));
      });

      test('should work with complex objects using registered serializer', () {
        // Register a serializer for TestPerson
        registry.registerSerializer<TestPerson>(TestPersonSerializer());

        final subject = const IriTerm('http://example.org/team');
        final predicate = const IriTerm('http://example.org/members');
        final members = [
          TestPerson(iri: 'http://example.org/person1', name: 'Alice'),
          TestPerson(iri: 'http://example.org/person2', name: 'Bob'),
        ];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addRdfList(predicate, members)
            .build();

        // Should create list structure plus person data
        // List: 1 main + 2 first + 2 rest + 1 type = 6
        // Persons: 2 * (1 name + 1 type) = 4
        expect(triples.length, equals(10));

        // Check list structure
        final firstTriples =
            triples.where((t) => t.predicate == Rdf.first).toList();
        expect(firstTriples.length, equals(2));

        final personIris =
            firstTriples.map((t) => (t.object as IriTerm).value).toSet();
        expect(
            personIris,
            equals(
                {'http://example.org/person1', 'http://example.org/person2'}));

        // Check person data was serialized
        final nameTriples = triples
            .where(
                (t) => t.predicate == const IriTerm('http://example.org/name'))
            .toList();
        expect(nameTriples.length, equals(2));

        final names =
            nameTriples.map((t) => (t.object as LiteralTerm).value).toSet();
        expect(names, equals({'Alice', 'Bob'}));

        // Check type triples (list type + person types)
        final typeTriples =
            triples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.length, equals(3)); // 1 list + 2 persons
      });

      test('should work with method chaining', () {
        final subject = const IriTerm('http://example.org/book');
        final chapters = ['Chapter 1', 'Chapter 2'];
        final tags = ['fiction', 'adventure'];

        final (_, triples) = context
            .resourceBuilder(subject)
            .addValue(const IriTerm('http://example.org/title'), 'My Book')
            .addRdfList(const IriTerm('http://example.org/chapters'), chapters)
            .addRdfList(const IriTerm('http://example.org/tags'), tags)
            .build();

        // Should have:
        // - 1 title triple
        // - 6 chapter list triples (1 main + 2 first + 2 rest + 1 type)
        // - 6 tag list triples (1 main + 2 first + 2 rest + 1 type)
        expect(triples.length, equals(13));

        // Check title
        final titleTriples = triples
            .where(
                (t) => t.predicate == const IriTerm('http://example.org/title'))
            .toList();
        expect(titleTriples.length, equals(1));
        expect((titleTriples.first.object as LiteralTerm).value,
            equals('My Book'));

        // Check both lists exist
        final chapterTriples = triples
            .where((t) =>
                t.subject == subject &&
                t.predicate == const IriTerm('http://example.org/chapters'))
            .toList();
        expect(chapterTriples.length, equals(1));

        final tagTriples = triples
            .where((t) =>
                t.subject == subject &&
                t.predicate == const IriTerm('http://example.org/tags'))
            .toList();
        expect(tagTriples.length, equals(1));

        // Check that we have type triples for both lists
        final typeTriples = triples
            .where((t) => t.predicate == Rdf.type && t.object == Rdf.List)
            .toList();
        expect(typeTriples.length, equals(2)); // One for each list
      });
    });
  });
}

// Test helper classes

/// Custom serializer for testing purposes
class UpperCaseStringSerializer implements LiteralTermSerializer<String> {
  final IriTerm datatype = Xsd.string;

  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm(value.toUpperCase(), datatype: datatype);
  }
}

/// Test class for complex object serialization
class TestPerson {
  final String iri;
  final String name;

  TestPerson({required this.iri, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          iri == other.iri &&
          name == other.name;

  @override
  int get hashCode => iri.hashCode ^ name.hashCode;

  @override
  String toString() => 'TestPerson(iri: $iri, name: $name)';
}

/// Test serializer for TestPerson
class TestPersonSerializer implements GlobalResourceSerializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      context
          .resourceBuilder(context.createIriTerm(value.iri))
          .addValue(const IriTerm('http://example.org/name'), value.name)
          .build();
}

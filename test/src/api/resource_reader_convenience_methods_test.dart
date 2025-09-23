import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
  });

  group('ResourceReader convenience methods', () {
    group('requireRdfList', () {
      test('should deserialize a simple RDF list of strings', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create RDF list structure: ( "Chapter 1" "Chapter 2" "Chapter 3" )
        final list1 = BlankNodeTerm();
        final list2 = BlankNodeTerm();
        final list3 = BlankNodeTerm();

        final triples = [
          Triple(subject, predicate, list1),
          Triple(
              list1, Rdf.first, LiteralTerm('Chapter 1', datatype: Xsd.string)),
          Triple(list1, Rdf.rest, list2),
          Triple(
              list2, Rdf.first, LiteralTerm('Chapter 2', datatype: Xsd.string)),
          Triple(list2, Rdf.rest, list3),
          Triple(
              list3, Rdf.first, LiteralTerm('Chapter 3', datatype: Xsd.string)),
          Triple(list3, Rdf.rest, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.requireRdfList<String>(predicate);

        expect(chapters, equals(['Chapter 1', 'Chapter 2', 'Chapter 3']));
        expect(chapters, isA<List<String>>());
      });

      test('should deserialize an empty RDF list', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create empty RDF list: ()
        final triples = [
          Triple(subject, predicate, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.requireRdfList<String>(predicate);

        expect(chapters, isEmpty);
        expect(chapters, isA<List<String>>());
      });

      test('should work with custom item deserializer', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create RDF list structure with custom deserializer that converts to uppercase
        final list1 = BlankNodeTerm();
        final list2 = BlankNodeTerm();

        final triples = [
          Triple(subject, predicate, list1),
          Triple(list1, Rdf.first,
              LiteralTerm('chapter one', datatype: Xsd.string)),
          Triple(list1, Rdf.rest, list2),
          Triple(list2, Rdf.first,
              LiteralTerm('chapter two', datatype: Xsd.string)),
          Triple(list2, Rdf.rest, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.requireRdfList<String>(
          predicate,
          itemDeserializer: UpperCaseStringDeserializer(),
        );

        expect(chapters, equals(['CHAPTER ONE', 'CHAPTER TWO']));
      });

      test('should throw PropertyValueNotFoundException when list is missing',
          () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Empty graph - no list exists
        graph = RdfGraph(triples: []);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);

        expect(
          () => reader.requireRdfList<String>(predicate),
          throwsA(isA<PropertyValueNotFoundException>()),
        );
      });

      test('should work with complex objects using registered deserializer',
          () {
        // Register a deserializer for TestPerson
        registry.registerDeserializer<TestPerson>(TestPersonDeserializer());

        final subject = const IriTerm('http://example.org/team');
        final predicate = const IriTerm('http://example.org/members');

        // Create list of people
        final person1 = const IriTerm('http://example.org/person1');
        final person2 = const IriTerm('http://example.org/person2');
        final list1 = BlankNodeTerm();
        final list2 = BlankNodeTerm();

        final triples = [
          Triple(subject, predicate, list1),
          Triple(list1, Rdf.first, person1),
          Triple(list1, Rdf.rest, list2),
          Triple(list2, Rdf.first, person2),
          Triple(list2, Rdf.rest, Rdf.nil),
          // Person data
          Triple(person1, const IriTerm('http://example.org/name'),
              LiteralTerm('Alice')),
          Triple(person2, const IriTerm('http://example.org/name'),
              LiteralTerm('Bob')),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final members = reader.requireRdfList<TestPerson>(predicate);

        expect(members, hasLength(2));
        expect(members[0].name, equals('Alice'));
        expect(members[1].name, equals('Bob'));
      });
    });

    group('optionalRdfList', () {
      test('should deserialize a simple RDF list of strings when present', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create RDF list structure: ( "Chapter 1" "Chapter 2" )
        final list1 = BlankNodeTerm();
        final list2 = BlankNodeTerm();

        final triples = [
          Triple(subject, predicate, list1),
          Triple(
              list1, Rdf.first, LiteralTerm('Chapter 1', datatype: Xsd.string)),
          Triple(list1, Rdf.rest, list2),
          Triple(
              list2, Rdf.first, LiteralTerm('Chapter 2', datatype: Xsd.string)),
          Triple(list2, Rdf.rest, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.optionalRdfList<String>(predicate);

        expect(chapters, equals(['Chapter 1', 'Chapter 2']));
        expect(chapters, isA<List<String>?>());
      });

      test('should return null when list is missing', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Empty graph - no list exists
        graph = RdfGraph(triples: []);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.optionalRdfList<String>(predicate);

        expect(chapters, isNull);
      });

      test('should deserialize an empty RDF list when present', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create empty RDF list: ()
        final triples = [
          Triple(subject, predicate, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.optionalRdfList<String>(predicate);

        expect(chapters, isNotNull);
        expect(chapters, isEmpty);
        expect(chapters, isA<List<String>?>());
      });

      test('should work with custom item deserializer', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Create RDF list structure
        final list1 = BlankNodeTerm();

        final triples = [
          Triple(subject, predicate, list1),
          Triple(list1, Rdf.first, LiteralTerm('test', datatype: Xsd.string)),
          Triple(list1, Rdf.rest, Rdf.nil),
        ];

        graph = RdfGraph(triples: triples);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.optionalRdfList<String>(
          predicate,
          itemDeserializer: UpperCaseStringDeserializer(),
        );

        expect(chapters, equals(['TEST']));
      });

      test('should work with null-coalescing for default values', () {
        final subject = const IriTerm('http://example.org/book');
        final predicate = const IriTerm('http://example.org/chapters');

        // Empty graph - no list exists
        graph = RdfGraph(triples: []);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final reader = context.reader(subject);
        final chapters = reader.optionalRdfList<String>(predicate) ??
            const ['Default Chapter'];

        expect(chapters, equals(['Default Chapter']));
      });
    });
  });
}

// Test helper classes

/// Custom deserializer for testing purposes
class UpperCaseStringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm datatype;

  UpperCaseStringDeserializer([this.datatype = Xsd.string]);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toUpperCase();
  }
}

/// Test class for complex object deserialization
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

/// Test deserializer for TestPerson
class TestPersonDeserializer implements GlobalResourceDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));
    return TestPerson(iri: subject.value, name: name);
  }
}

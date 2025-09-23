import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late SerializationContext context;

  setUp(() {
    registry = RdfMapperRegistry();
    final contextImpl = SerializationContextImpl(registry: registry);
    context = contextImpl;
  });

  group('ResourceBuilder', () {
    test('constant method should add direct RDF object term', () {
      final subject = const IriTerm('http://example.org/resource/1');
      final predicate = const IriTerm('http://example.org/predicate');
      final object = const IriTerm('http://example.org/object');

      final (_, triples) =
          context.resourceBuilder(subject).addValue(predicate, object).build();

      expect(triples.length, equals(1));
      expect(triples.first, equals(Triple(subject, predicate, object)));
    });

    test(
      'literals method should extract multiple literal values from source object',
      () {
        final subject = const IriTerm('http://example.org/resource/1');
        final predicate = const IriTerm('http://example.org/tag');
        final container = TestContainer(tags: ['tag1', 'tag2', 'tag3']);

        final (_, triples) = context
            .resourceBuilder(subject)
            .addValuesFromSource(predicate, (c) => c.tags, container)
            .build();

        expect(triples.length, equals(3));
        expect(
          triples.map((t) => (t.subject, t.predicate)).toSet(),
          equals({
            (subject, predicate),
            (subject, predicate),
            (subject, predicate),
          }),
        );
        expect(
          triples.map((t) => (t.object as LiteralTerm).value).toSet(),
          equals({'tag1', 'tag2', 'tag3'}),
        );
      },
    );

    test(
      'iris method should extract multiple IRI values from source object',
      () {
        final subject = const IriTerm('http://example.org/resource/1');
        final predicate = const IriTerm('http://example.org/relation');
        final container = TestContainer(
          relatedIds: [
            'http://example.org/related/1',
            'http://example.org/related/2',
            'http://example.org/related/3',
          ],
        );

        final (_, triples) = context
            .resourceBuilder(subject)
            .addValuesFromSource<TestContainer, String>(
                predicate, (c) => c.relatedIds, container,
                // String values would default to Literal, so we need to specify
                // the IriTermSerializer to ensure it is serialized as an Iri
                serializer: const IriFullSerializer())
            .build();

        expect(triples.length, equals(3));
        expect(
          triples.map((t) => (t.subject, t.predicate)).toSet(),
          equals({
            (subject, predicate),
            (subject, predicate),
            (subject, predicate),
          }),
        );
        expect(
          triples.map((t) => (t.object as IriTerm).value).toSet(),
          equals({
            'http://example.org/related/1',
            'http://example.org/related/2',
            'http://example.org/related/3',
          }),
        );
      },
    );

    test(
      'childResources method should extract multiple child nodes from source object',
      () {
        // Register a test serializer
        final personSerializer = TestPersonSerializer();
        registry.registerSerializer<TestPerson>(personSerializer);

        final subject = const IriTerm('http://example.org/resource/1');
        final predicate = const IriTerm('http://example.org/hasMember');
        final container = TestContainer(
          people: [
            TestPerson(id: 'http://example.org/person/1', name: 'Alice'),
            TestPerson(id: 'http://example.org/person/2', name: 'Bob'),
          ],
        );

        final (_, triples) = context
            .resourceBuilder(subject)
            .addValuesFromSource(predicate, (c) => c.people, container)
            .build();

        // Should have:
        // - 2 triples linking subject to each person
        // - 2 name triples (one per person)
        // - 2 type triples (one per person)
        expect(triples.length, equals(6));

        // Check link triples from subject to people
        final linkTriples = triples
            .where((t) => t.subject == subject && t.predicate == predicate)
            .toList();

        expect(linkTriples.length, equals(2));
        expect(
          linkTriples.map((t) => (t.object as IriTerm).value).toSet(),
          equals({
            'http://example.org/person/1',
            'http://example.org/person/2',
          }),
        );

        // Check name triples for each person
        final nameTriples = triples
            .where(
              (t) =>
                  t.predicate ==
                  const IriTerm('http://xmlns.com/foaf/0.1/name'),
            )
            .toList();

        expect(nameTriples.length, equals(2));
        expect(
          nameTriples.map((t) => (t.object as LiteralTerm).value).toSet(),
          equals({'Alice', 'Bob'}),
        );

        // Check type triples for each person
        final typeTriples =
            triples.where((t) => t.predicate == Rdf.type).toList();
        expect(typeTriples.length, equals(2));
        expect(
          typeTriples.map((t) => (t.object as IriTerm).value).toSet(),
          equals({"http://example.org/Person"}),
        );
      },
    );

    test('method chaining should work with new methods', () {
      final subject = const IriTerm('http://example.org/resource/1');
      final container = TestContainer(
        tags: ['tag1', 'tag2'],
        relatedIds: ['http://example.org/related/1'],
        people: [TestPerson(id: 'http://example.org/person/1', name: 'Alice')],
      );

      // Register a test serializer
      final personSerializer = TestPersonSerializer();
      registry.registerSerializer<TestPerson>(personSerializer);

      final (_, triples) = context
          .resourceBuilder(subject)
          .addValue(const IriTerm('http://example.org/title'), 'Test Resource')
          .addValue(
            const IriTerm('http://example.org/type'),
            const IriTerm('http://example.org/Container'),
          )
          .addValuesFromSource(
            const IriTerm('http://example.org/tag'),
            (c) => c.tags,
            container,
          )
          .addValuesFromSource<TestContainer, String>(
              const IriTerm('http://example.org/related'),
              (c) => c.relatedIds,
              container,
              // String values would default to Literal, so we need to specify
              // the IriTermSerializer to ensure it is serialized as an Iri
              serializer: const IriFullSerializer())
          .addValuesFromSource(
            const IriTerm('http://example.org/hasMember'),
            (c) => c.people,
            container,
          )
          .build();

      // 1 title + 1 type + 2 tags + 1 related + 1 link to person + 1 person name + 1 person type = 8 triples
      expect(triples.length, equals(8));
    });
  });
}

// Test classes for the tests

class TestContainer {
  final List<String> tags;
  final List<String> relatedIds;
  final List<TestPerson> people;

  TestContainer({
    this.tags = const [],
    this.relatedIds = const [],
    this.people = const [],
  });
}

class TestPerson {
  final String id;
  final String name;

  TestPerson({required this.id, required this.name});
}

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
          .resourceBuilder(context.createIriTerm(value.id))
          .addValue(const IriTerm('http://xmlns.com/foaf/0.1/name'), value.name)
          .build();
}

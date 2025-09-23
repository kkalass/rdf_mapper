import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:test/test.dart';

void main() {
  group('LiteralTermMapper usage', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = RdfMapper.withDefaultRegistry();
      // Register our test person mapper
      rdfMapper.registerMapper(TestPersonMapper());
    });

    test(
      'demonstrates that literal term mappers cannot be used directly for RDF serialization',
      () {
        // A simple string value
        const simpleString = 'Hello, World!';

        // Create a literal term directly using the standard mapper
        final stringMapper = const StringMapper();
        final serializationContext = MockSerializationContext();
        final literalTerm = stringMapper.toRdfTerm(
          simpleString,
          serializationContext,
        );

        // Verify it's a valid literal term with the expected value
        expect(literalTerm, isA<LiteralTerm>());
        expect(literalTerm.value, equals(simpleString));

        // However, this term alone is not a valid RDF document - it needs to be part of a triple
        // To create a valid RDF document, we need at least one triple with subject, predicate, and object
        final subject = const IriTerm('http://example.org/resource');
        final predicate = const IriTerm('http://example.org/property');

        // Create a valid RDF graph with a triple containing our literal
        final graph = RdfGraph(
          triples: [Triple(subject, predicate, literalTerm)],
        );

        // Verify the graph contains our triple
        expect(graph.triples.length, equals(1));
        expect(graph.triples.first.subject, equals(subject));
        expect(graph.triples.first.predicate, equals(predicate));
        expect(graph.triples.first.object, equals(literalTerm));

        // Now we can serialize the graph to a string using a graph codec
        final rdfCore = RdfCore.withStandardCodecs();
        final turtle = rdfCore.codec(contentType: 'text/turtle').encode(graph);

        // Verify the turtle string looks valid and contains our value
        expect(turtle, isNotEmpty);
        // The RDF library may use prefixes or full IRIs in the serialization
        expect(turtle, contains('resource'));
        expect(turtle, contains('property'));
        expect(turtle, contains('"Hello, World!"'));
      },
    );

    test('shows how literals are properly used through node mappers', () {
      // Create a test person with properties that will become literals
      final person = TestPerson(
        id: 'http://example.org/person/123',
        name: 'Alice Smith', // This will be a string literal
        age: 30, // This will be an integer literal
      );

      // Encode the person to RDF
      final graph = rdfMapper.graph.encodeObject(person);

      // Verify the graph contains the expected triples including literals
      expect(graph.triples, isNotEmpty);

      // Find the name triple that should have a literal as its object
      final nameTriples = graph.findTriples(
        subject: IriTerm.validated(person.id),
        predicate: TestPersonMapper.namePredicate,
      );

      // Verify the literal is correctly serialized
      expect(nameTriples.length, equals(1));
      expect(nameTriples.first.object, isA<LiteralTerm>());
      expect(
        (nameTriples.first.object as LiteralTerm).value,
        equals('Alice Smith'),
      );

      // Same for age
      final ageTriples = graph.findTriples(
        subject: IriTerm.validated(person.id),
        predicate: TestPersonMapper.agePredicate,
      );

      expect(ageTriples.length, equals(1));
      expect(ageTriples.first.object, isA<LiteralTerm>());
      expect((ageTriples.first.object as LiteralTerm).value, equals('30'));
    });

    test(
      'throws exception when trying to directly serialize a string with encodeObject',
      () {
        // A simple string value
        const simpleString = 'Hello, World!';

        // This should throw an exception because a string can't be serialized directly as RDF
        // It needs to be part of a subject-predicate-object triple
        expect(
          () => rdfMapper.encodeObject(simpleString),
          throwsA(anything), // The exact exception type may vary
        );
      },
    );

    test(
      'throws exception when trying to directly serialize an int with encodeObject',
      () {
        // A simple int value
        const simpleInt = 42;

        // This should throw an exception because an int can't be serialized directly as RDF
        // It needs to be part of a subject-predicate-object triple
        expect(
          () => rdfMapper.encodeObject(simpleInt),
          throwsA(anything), // The exact exception type may vary
        );
      },
    );
  });

  group('LiteralTermMapper in collections', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = RdfMapper.withDefaultRegistry();
      // Register our test collection container mapper
      rdfMapper.registerMapper(TestCollectionContainerMapper());
    });

    test(
      'demonstrates how literals are used in collections within complex objects',
      () {
        // Create a container with a list of string values
        final container = TestCollectionContainer(
          id: 'http://example.org/container/1',
          stringList: ['Value 1', 'Value 2', 'Value 3'],
        );

        // Encode the container to RDF
        final graph = rdfMapper.graph.encodeObject(container);

        // Verify the graph contains the expected triples
        expect(graph.triples, isNotEmpty);

        // Check that the graph contains triples for each string in the list
        final stringListTriples = graph.findTriples(
          subject: IriTerm.validated(container.id),
          predicate: TestCollectionContainerMapper.stringListPredicate,
        );

        expect(stringListTriples.length, equals(container.stringList.length));

        // Verify that all strings from the list are represented as literal terms
        for (var i = 0; i < container.stringList.length; i++) {
          final triple = stringListTriples[i];
          expect(triple.object, isA<LiteralTerm>());
          expect(
            container.stringList,
            contains((triple.object as LiteralTerm).value),
          );
        }

        // Deserialize the graph back to an object
        final deserializedContainer =
            rdfMapper.graph.decodeObject<TestCollectionContainer>(graph);

        // Verify all properties were correctly round-tripped
        expect(deserializedContainer.id, equals(container.id));
        expect(deserializedContainer.stringList, equals(container.stringList));
      },
    );
  });
}

// Simple context implementation for testing
class MockSerializationContext implements SerializationContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test model classes
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({required this.id, required this.name, required this.age});
}

// Test mapper for Person
class TestPersonMapper implements GlobalResourceMapper<TestPerson> {
  static final IriTerm personTypeIri = FoafPerson.classIri;
  static final IriTerm namePredicate = FoafPerson.name;
  static final IriTerm agePredicate = FoafPerson.age;

  @override
  IriTerm get typeIri => TestPersonMapper.personTypeIri;

  @override
  TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestPerson(
      id: subject.value,
      name: reader.require<String>(namePredicate),
      age: reader.require<int>(agePredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(instance.id))
        .addValue(
          const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          personTypeIri,
        )
        .addValue(namePredicate, instance.name)
        .addValue(agePredicate, instance.age)
        .build();
  }
}

// Test model classes for collections
class TestCollectionContainer {
  final String id;
  final Iterable<String> stringList;

  TestCollectionContainer({required this.id, required this.stringList});
}

// Test mapper for collection container
class TestCollectionContainerMapper
    implements GlobalResourceMapper<TestCollectionContainer> {
  static final IriTerm containerTypeIri = const IriTerm(
    'http://example.org/CollectionContainer',
  );
  static final IriTerm stringListPredicate = const IriTerm(
    'http://example.org/stringList',
  );

  @override
  IriTerm get typeIri => TestCollectionContainerMapper.containerTypeIri;

  @override
  TestCollectionContainer fromRdfResource(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);

    // Read the string list directly
    final stringList = reader.getValues<String>(stringListPredicate);

    return TestCollectionContainer(id: subject.value, stringList: stringList);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestCollectionContainer instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Create builder with subject
    final builder = context.resourceBuilder(context.createIriTerm(instance.id));

    // Add type triple
    builder.addValue(
      const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      typeIri,
    );

    // Add string list values one by one
    for (final str in instance.stringList) {
      builder.addValue(stringListPredicate, str);
    }

    return builder.build();
  }
}

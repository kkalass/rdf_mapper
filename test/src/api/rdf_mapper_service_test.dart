import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperService', () {
    late RdfMapperRegistry registry;
    late RdfMapperService service;

    setUp(() {
      registry = RdfMapperRegistry();
      service = RdfMapperService(registry: registry);
    });

    test('deserializeBySubject deserializes an object from triples', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create test triples
      final subject = const IriTerm('http://example.org/person/1');
      final triples = [
        Triple(
          subject,
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('John Doe'),
        ),
        Triple(
          subject,
          const IriTerm('http://xmlns.com/foaf/0.1/age'),
          LiteralTerm.typed('30', 'integer'),
        ),
        Triple(subject, Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person')),
      ];

      // Deserialize the object
      final person = service.deserializeBySubject<TestPerson>(
        RdfGraph(triples: triples),
        subject,
      );

      // Verify the deserialized object
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test('fromGraphBySubject deserializes an object from a graph', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph
      final subject = const IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subject,
            const IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subject,
            const IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subject,
            Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
        ],
      );

      // Deserialize the object
      final person = service.deserializeBySubject<TestPerson>(graph, subject);

      // Verify the deserialized object
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test('fromGraph deserializes a single object from a graph', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph with a single subject
      final subject = const IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subject,
            const IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subject,
            const IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subject,
            Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
        ],
      );

      // Deserialize the object
      final person = service.deserialize<TestPerson>(graph);

      // Verify the deserialized object
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test('fromGraph throws for empty graph', () {
      expect(
        () => service.deserialize<TestPerson>(RdfGraph()),
        throwsA(isA<DeserializationException>()),
      );
    });

    test('fromGraph throws for multiple subjects', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph with multiple subjects
      final graph = RdfGraph(
        triples: [
          Triple(
            const IriTerm('http://example.org/person/1'),
            Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
          Triple(
            const IriTerm('http://example.org/person/2'),
            Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
        ],
      );

      // Attempt to deserialize should throw
      expect(
        () => service.deserialize<TestPerson>(graph),
        throwsA(isA<DeserializationException>()),
      );
    });

    test(
      'fromGraphAllSubjects deserializes multiple subjects from a graph',
      () {
        // Register a test mapper
        registry.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test graph with multiple subjects
        final graph = RdfGraph(
          triples: [
            // Person 1
            Triple(
              const IriTerm('http://example.org/person/1'),
              Rdf.type,
              const IriTerm('http://xmlns.com/foaf/0.1/Person'),
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              const IriTerm('http://xmlns.com/foaf/0.1/name'),
              LiteralTerm.string('John Doe'),
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              const IriTerm('http://xmlns.com/foaf/0.1/age'),
              LiteralTerm.typed('30', 'integer'),
            ),

            // Person 2
            Triple(
              const IriTerm('http://example.org/person/2'),
              Rdf.type,
              const IriTerm('http://xmlns.com/foaf/0.1/Person'),
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://xmlns.com/foaf/0.1/name'),
              LiteralTerm.string('Jane Smith'),
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://xmlns.com/foaf/0.1/age'),
              LiteralTerm.typed('28', 'integer'),
            ),
          ],
        );

        // Deserialize all subjects
        final objects = service.deserializeAll(graph,
            completeness: CompletenessMode.lenient);

        // Verify the deserialized objects
        expect(objects.length, equals(2));

        // Convert to strongly typed list for easier assertions
        final people = objects.whereType<TestPerson>().toList();
        expect(people.length, equals(2));

        // Sort by ID for consistent test assertions
        people.sort((a, b) => a.id.compareTo(b.id));

        // Verify person 1
        expect(people[0].id, equals('http://example.org/person/1'));
        expect(people[0].name, equals('John Doe'));
        expect(people[0].age, equals(30));

        // Verify person 2
        expect(people[1].id, equals('http://example.org/person/2'));
        expect(people[1].name, equals('Jane Smith'));
        expect(people[1].age, equals(28));
      },
    );

    test('fromGraphAllSubjects throws for subjects with unmapped types', () {
      // Register only a person mapper, not an address mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph with multiple subjects of different types
      final graph = RdfGraph(
        triples: [
          // Person
          Triple(
            const IriTerm('http://example.org/person/1'),
            Rdf.type,
            const IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),

          // Address (unmapped type)
          Triple(
            const IriTerm('http://example.org/address/1'),
            Rdf.type,
            const IriTerm('http://example.org/Address'),
          ),
          Triple(
            const IriTerm('http://example.org/address/1'),
            const IriTerm('http://example.org/street'),
            LiteralTerm.string('123 Main St'),
          ),
        ],
      );

      // Attempt to deserialize all subjects should throw an IncompleteDeserializationException
      expect(
        () => service.deserializeAll(graph),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });

    test('toGraph serializes an object to a graph', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Serialize to graph
      final graph = service.serialize(person);

      // Verify the serialized graph
      expect(graph.size, greaterThan(0));

      // Check for the name triple
      final nameTriples = graph.findTriples(
        subject: const IriTerm('http://example.org/person/1'),
        predicate: const IriTerm('http://xmlns.com/foaf/0.1/name'),
      );
      expect(nameTriples.length, equals(1));
      expect((nameTriples[0].object as LiteralTerm).value, equals('John Doe'));

      // Check for the type triple
      final typeTriples = graph.findTriples(
        subject: const IriTerm('http://example.org/person/1'),
        predicate: Rdf.type,
      );
      expect(typeTriples.length, equals(1));
      expect(
        typeTriples[0].object,
        equals(const IriTerm('http://xmlns.com/foaf/0.1/Person')),
      );
    });

    test('toGraph uses temporary registry from register callback', () {
      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Serialize with temporary mapper registration
      final graph = service.serialize(
        person,
        register: (registry) {
          registry.registerMapper<TestPerson>(TestPersonMapper());
        },
      );

      // Verify the graph still serialized correctly
      expect(graph.size, greaterThan(0));
      expect(
        graph
            .findTriples(
              subject: const IriTerm('http://example.org/person/1'),
              predicate: const IriTerm('http://xmlns.com/foaf/0.1/name'),
            )
            .length,
        equals(1),
      );

      // And verify the main registry wasn't affected
      expect(service.registry.hasResourceSerializerFor<TestPerson>(), isFalse);
    });

    test('toGraphFromList serializes a list of objects to a graph', () {
      // Register a test mapper
      registry.registerMapper<TestPerson>(TestPersonMapper());

      // Create test people
      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
        TestPerson(
          id: 'http://example.org/person/2',
          name: 'Jane Smith',
          age: 28,
        ),
      ];

      // Serialize to graph
      final graph = service.serializeList(people);

      // Verify the graph contains triples for both people
      final person1Triples = graph.findTriples(
        subject: const IriTerm('http://example.org/person/1'),
      );
      final person2Triples = graph.findTriples(
        subject: const IriTerm('http://example.org/person/2'),
      );

      expect(person1Triples.isNotEmpty, isTrue);
      expect(person2Triples.isNotEmpty, isTrue);

      // Verify specific triples for each person
      expect(
        graph
            .findTriples(
              subject: const IriTerm('http://example.org/person/1'),
              predicate: const IriTerm('http://xmlns.com/foaf/0.1/name'),
            )[0]
            .object,
        isA<LiteralTerm>(),
      );

      expect(
        (graph
                .findTriples(
                  subject: const IriTerm('http://example.org/person/1'),
                  predicate: const IriTerm('http://xmlns.com/foaf/0.1/name'),
                )[0]
                .object as LiteralTerm)
            .value,
        equals('John Doe'),
      );

      expect(
        (graph
                .findTriples(
                  subject: const IriTerm('http://example.org/person/2'),
                  predicate: const IriTerm('http://xmlns.com/foaf/0.1/name'),
                )[0]
                .object as LiteralTerm)
            .value,
        equals('Jane Smith'),
      );
    });

    test(
      'deserializeAll should filter nested addressable entities correctly',
      () {
        // Setup registry with test mappers
        final registry = RdfMapperRegistry();
        registry.registerMapper<Address>(AddressMapper());
        registry.registerMapper<Person>(PersonMapper());

        final service = RdfMapperService(registry: registry);

        // Create test graph with:
        // - Person 1 referencing Address 1
        // - Person 2 referencing Address 2
        // - Address 1 and Address 2 as separate subjects
        final graph = RdfGraph(
          triples: [
            // Person 1
            Triple(
              const IriTerm('http://example.org/person/1'),
              Rdf.type,
              const IriTerm('http://example.org/Person'),
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              const IriTerm('http://example.org/name'),
              LiteralTerm.string('John'),
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              const IriTerm('http://example.org/address'),
              const IriTerm('http://example.org/address/1'),
            ),

            // Person 2
            Triple(
              const IriTerm('http://example.org/person/2'),
              Rdf.type,
              const IriTerm('http://example.org/Person'),
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://example.org/name'),
              LiteralTerm.string('Jane'),
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://example.org/address'),
              const IriTerm('http://example.org/address/2'),
            ),

            // Address 1
            Triple(
              const IriTerm('http://example.org/address/1'),
              Rdf.type,
              const IriTerm('http://example.org/Address'),
            ),
            Triple(
              const IriTerm('http://example.org/address/1'),
              const IriTerm('http://example.org/city'),
              LiteralTerm.string('New York'),
            ),

            // Address 2
            Triple(
              const IriTerm('http://example.org/address/2'),
              Rdf.type,
              const IriTerm('http://example.org/Address'),
            ),
            Triple(
              const IriTerm('http://example.org/address/2'),
              const IriTerm('http://example.org/city'),
              LiteralTerm.string('San Francisco'),
            ),
          ],
        );

        // Execute deserializeAll
        final objects = service.deserializeAll(graph,
            completeness: CompletenessMode.lenient);

        // Verify we get only Person objects, not addresses
        expect(objects.length, equals(2));

        // Check all objects are Persons
        expect(objects.whereType<Person>().length, equals(2));
        expect(objects.whereType<Address>().length, equals(0));

        // Verify person references are correct
        final people = objects.cast<Person>().toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        expect(people[0].name, equals('Jane'));
        expect(people[0].address?.city, equals('San Francisco'));

        expect(people[1].name, equals('John'));
        expect(people[1].address?.city, equals('New York'));
      },
    );

    test(
      'deserializeAll with a DocumentDeserializer that only references the IRIs',
      () {
        // Setup registry with test mappers
        final registry = RdfMapperRegistry();
        registry.registerDeserializer<Document>(
          DocumentWithTagReferencesDeserializer(),
        );
        registry.registerDeserializer<Tag>(TagDeserializer());

        final service = RdfMapperService(registry: registry);

        // Create test graph with:
        // - One document referencing two tags by IRI
        // - Two tags as separate subjects
        // - One standalone tag that isn't referenced
        final graph = RdfGraph(
          triples: [
            // Document
            Triple(
              const IriTerm('http://example.org/doc/1'),
              Rdf.type,
              const IriTerm('http://example.org/Document'),
            ),
            Triple(
              const IriTerm('http://example.org/doc/1'),
              const IriTerm('http://example.org/title'),
              LiteralTerm.string('Test Document'),
            ),
            Triple(
              const IriTerm('http://example.org/doc/1'),
              const IriTerm('http://example.org/tag'),
              const IriTerm('http://example.org/tag/1'),
            ),
            Triple(
              const IriTerm('http://example.org/doc/1'),
              const IriTerm('http://example.org/tag'),
              const IriTerm('http://example.org/tag/2'),
            ),

            // Referenced Tag 1
            Triple(
              const IriTerm('http://example.org/tag/1'),
              Rdf.type,
              const IriTerm('http://example.org/Tag'),
            ),
            Triple(
              const IriTerm('http://example.org/tag/1'),
              const IriTerm('http://example.org/name'),
              LiteralTerm.string('important'),
            ),

            // Referenced Tag 2
            Triple(
              const IriTerm('http://example.org/tag/2'),
              Rdf.type,
              const IriTerm('http://example.org/Tag'),
            ),
            Triple(
              const IriTerm('http://example.org/tag/2'),
              const IriTerm('http://example.org/name'),
              LiteralTerm.string('work'),
            ),

            // Standalone Tag (not referenced)
            Triple(
              const IriTerm('http://example.org/tag/3'),
              Rdf.type,
              const IriTerm('http://example.org/Tag'),
            ),
            Triple(
              const IriTerm('http://example.org/tag/3'),
              const IriTerm('http://example.org/name'),
              LiteralTerm.string('standalone'),
            ),
          ],
        );

        // Execute deserializeAll
        final objects = service.deserializeAll(graph);

        // Verify we get all, because the document references the tags
        expect(objects.length, equals(4));
        expect(objects.whereType<Document>().length, equals(1));
        expect(objects.whereType<Tag>().length, equals(3));

        final document = objects.whereType<Document>().first;
        final tags = objects.whereType<Tag>().toList();

        // Verify document has correct references
        expect(document.title, equals('Test Document'));
        expect(document.tags.length, equals(2));
        expect(document.tags, contains('http://example.org/tag/1'));
        expect(document.tags, contains('http://example.org/tag/2'));

        // Verify standalone tags
        expect(tags[0].id, equals('http://example.org/tag/1'));
        expect(tags[0].name, equals('important'));
        expect(tags[1].id, equals('http://example.org/tag/2'));
        expect(tags[1].name, equals('work'));
        expect(tags[2].id, equals('http://example.org/tag/3'));
        expect(tags[2].name, equals('standalone'));
      },
    );
  });
  test(
    'deserializeAll should handle standalone and referenced entities correctly',
    () {
      // Setup registry with test mappers
      final registry = RdfMapperRegistry();
      registry.registerDeserializer<Document>(DocumentDeserializer());
      registry.registerDeserializer<Tag>(TagDeserializer());

      final service = RdfMapperService(registry: registry);

      // Create test graph with:
      // - One document referencing two tags by IRI
      // - Two tags as separate subjects
      // - One standalone tag that isn't referenced
      final graph = RdfGraph(
        triples: [
          // Document
          Triple(
            const IriTerm('http://example.org/doc/1'),
            Rdf.type,
            const IriTerm('http://example.org/Document'),
          ),
          Triple(
            const IriTerm('http://example.org/doc/1'),
            const IriTerm('http://example.org/title'),
            LiteralTerm.string('Test Document'),
          ),
          Triple(
            const IriTerm('http://example.org/doc/1'),
            const IriTerm('http://example.org/tag'),
            const IriTerm('http://example.org/tag/1'),
          ),
          Triple(
            const IriTerm('http://example.org/doc/1'),
            const IriTerm('http://example.org/tag'),
            const IriTerm('http://example.org/tag/2'),
          ),

          // Referenced Tag 1
          Triple(
            const IriTerm('http://example.org/tag/1'),
            Rdf.type,
            const IriTerm('http://example.org/Tag'),
          ),
          Triple(
            const IriTerm('http://example.org/tag/1'),
            const IriTerm('http://example.org/name'),
            LiteralTerm.string('important'),
          ),

          // Referenced Tag 2
          Triple(
            const IriTerm('http://example.org/tag/2'),
            Rdf.type,
            const IriTerm('http://example.org/Tag'),
          ),
          Triple(
            const IriTerm('http://example.org/tag/2'),
            const IriTerm('http://example.org/name'),
            LiteralTerm.string('work'),
          ),

          // Standalone Tag (not referenced)
          Triple(
            const IriTerm('http://example.org/tag/3'),
            Rdf.type,
            const IriTerm('http://example.org/Tag'),
          ),
          Triple(
            const IriTerm('http://example.org/tag/3'),
            const IriTerm('http://example.org/name'),
            LiteralTerm.string('standalone'),
          ),
        ],
      );

      // Execute deserializeAll
      final objects = service.deserializeAll(graph);

      // Verify we get document and standalone tag, but not referenced tags
      expect(objects.length, equals(2));
      expect(objects.whereType<Document>().length, equals(1));
      expect(objects.whereType<Tag>().length, equals(1));

      final document = objects.whereType<Document>().first;
      final tag = objects.whereType<Tag>().first;

      // Verify document has correct tags
      expect(document.title, equals('Test Document'));
      expect(document.tags.length, equals(2));
      expect(document.tags, contains('important'));
      expect(document.tags, contains('work'));

      // Verify standalone tag
      expect(tag.id, equals('http://example.org/tag/3'));
      expect(tag.name, equals('standalone'));
    },
  );
}

// Define models and mappers for a standalone entity case
class Document {
  final String id;
  final String title;
  final Iterable<String> tags;

  Document({required this.id, required this.title, this.tags = const []});
}

class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});
}

class DocumentDeserializer implements GlobalResourceDeserializer<Document> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Document');

  @override
  Document fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final title =
        reader.require<String>(const IriTerm('http://example.org/title'));

    final tagNames = reader
        .getValues<Tag>(const IriTerm('http://example.org/tag'))
        .map((tag) => tag.name)
        .toList();

    return Document(id: subject.value, title: title, tags: tagNames);
  }
}

class DocumentWithTagReferencesDeserializer
    implements GlobalResourceDeserializer<Document> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Document');

  @override
  Document fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final title =
        reader.require<String>(const IriTerm('http://example.org/title'));

    final tagIris = reader.getValues<String>(
      const IriTerm('http://example.org/tag'),
      deserializer: IriStringDeserializer(),
    );

    return Document(id: subject.value, title: title, tags: tagIris);
  }
}

class TagDeserializer implements GlobalResourceDeserializer<Tag> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Tag');

  @override
  Tag fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));

    return Tag(id: subject.value, name: name);
  }
}

// Helper deserializer for IRI strings
class IriStringDeserializer implements IriTermDeserializer<String> {
  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.value;
  }
}

// Define test models and mappers
class Address {
  final String id;
  final String city;
  Address({required this.id, required this.city});

  @override
  String toString() => 'Address($id, $city)';
}

class Person {
  final String id;
  final String name;
  final Address? address;
  Person({required this.id, required this.name, this.address});

  @override
  String toString() => 'Person($id, $name)';
}

class AddressMapper implements GlobalResourceMapper<Address> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Address');

  @override
  Address fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final city =
        reader.require<String>(const IriTerm('http://example.org/city'));
    return Address(id: subject.value, city: city);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(const IriTerm('http://example.org/city'), value.city)
        .build();
  }
}

class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  Person fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));
    final address = reader.optional<Address>(
      const IriTerm('http://example.org/address'),
    );
    return Person(id: subject.value, name: name, address: address);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Person value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(const IriTerm('http://example.org/name'), value.name)
        .addValueIfNotNull(
            const IriTerm('http://example.org/address'),
            value.address == null
                ? null
                : context.createIriTerm(value.address!.id))
        .build();
  }
}

// Test mapper implementation
// Test model class
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({required this.id, required this.name, required this.age});
}

class TestPersonMapper implements GlobalResourceMapper<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://xmlns.com/foaf/0.1/Person');

  @override
  TestPerson fromRdfResource(IriTerm term, DeserializationContext context) {
    final id = term.value;
    final reader = context.reader(term);

    // Get name property
    final name = reader.optional<String>(
      const IriTerm('http://xmlns.com/foaf/0.1/name'),
    );

    // Get age property
    final age =
        reader.optional<int>(const IriTerm('http://xmlns.com/foaf/0.1/age')) ??
            0; // Default age to 0 if not present

    return TestPerson(id: id, name: name ?? 'Unknown', age: age);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(value.id);
    final triples = <Triple>[
      // Name triple
      Triple(
        subject,
        const IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string(value.name),
      ),

      // Age triple
      Triple(
        subject,
        const IriTerm('http://xmlns.com/foaf/0.1/age'),
        LiteralTerm.typed(value.age.toString(), 'integer'),
      ),
    ];

    return (subject, triples);
  }
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
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
      final subject = IriTerm('http://example.org/person/1');
      final triples = [
        Triple(
          subject,
          IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('John Doe'),
        ),
        Triple(
          subject,
          IriTerm('http://xmlns.com/foaf/0.1/age'),
          LiteralTerm.typed('30', 'integer'),
        ),
        Triple(
          subject,
          RdfPredicates.type,
          IriTerm('http://xmlns.com/foaf/0.1/Person'),
        ),
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
      final subject = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subject,
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subject,
            IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subject,
            RdfPredicates.type,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
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
      final subject = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subject,
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subject,
            IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subject,
            RdfPredicates.type,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
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
            IriTerm('http://example.org/person/1'),
            RdfPredicates.type,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
          Triple(
            IriTerm('http://example.org/person/2'),
            RdfPredicates.type,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
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
              IriTerm('http://example.org/person/1'),
              RdfPredicates.type,
              IriTerm('http://xmlns.com/foaf/0.1/Person'),
            ),
            Triple(
              IriTerm('http://example.org/person/1'),
              IriTerm('http://xmlns.com/foaf/0.1/name'),
              LiteralTerm.string('John Doe'),
            ),
            Triple(
              IriTerm('http://example.org/person/1'),
              IriTerm('http://xmlns.com/foaf/0.1/age'),
              LiteralTerm.typed('30', 'integer'),
            ),

            // Person 2
            Triple(
              IriTerm('http://example.org/person/2'),
              RdfPredicates.type,
              IriTerm('http://xmlns.com/foaf/0.1/Person'),
            ),
            Triple(
              IriTerm('http://example.org/person/2'),
              IriTerm('http://xmlns.com/foaf/0.1/name'),
              LiteralTerm.string('Jane Smith'),
            ),
            Triple(
              IriTerm('http://example.org/person/2'),
              IriTerm('http://xmlns.com/foaf/0.1/age'),
              LiteralTerm.typed('28', 'integer'),
            ),
          ],
        );

        // Deserialize all subjects
        final objects = service.deserializeAll(graph);

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
            IriTerm('http://example.org/person/1'),
            RdfPredicates.type,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
          Triple(
            IriTerm('http://example.org/person/1'),
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),

          // Address (unmapped type)
          Triple(
            IriTerm('http://example.org/address/1'),
            RdfPredicates.type,
            IriTerm('http://example.org/Address'),
          ),
          Triple(
            IriTerm('http://example.org/address/1'),
            IriTerm('http://example.org/street'),
            LiteralTerm.string('123 Main St'),
          ),
        ],
      );

      // Attempt to deserialize all subjects should throw a DeserializerNotFoundException
      expect(
        () => service.deserializeAll(graph),
        throwsA(isA<DeserializerNotFoundException>()),
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
        subject: IriTerm('http://example.org/person/1'),
        predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
      );
      expect(nameTriples.length, equals(1));
      expect((nameTriples[0].object as LiteralTerm).value, equals('John Doe'));

      // Check for the type triple
      final typeTriples = graph.findTriples(
        subject: IriTerm('http://example.org/person/1'),
        predicate: RdfPredicates.type,
      );
      expect(typeTriples.length, equals(1));
      expect(
        typeTriples[0].object,
        equals(IriTerm('http://xmlns.com/foaf/0.1/Person')),
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
              subject: IriTerm('http://example.org/person/1'),
              predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
            )
            .length,
        equals(1),
      );

      // And verify the main registry wasn't affected
      expect(service.registry.hasNodeSerializerFor<TestPerson>(), isFalse);
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
        subject: IriTerm('http://example.org/person/1'),
      );
      final person2Triples = graph.findTriples(
        subject: IriTerm('http://example.org/person/2'),
      );

      expect(person1Triples.isNotEmpty, isTrue);
      expect(person2Triples.isNotEmpty, isTrue);

      // Verify specific triples for each person
      expect(
        graph
            .findTriples(
              subject: IriTerm('http://example.org/person/1'),
              predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
            )[0]
            .object,
        isA<LiteralTerm>(),
      );

      expect(
        (graph
                    .findTriples(
                      subject: IriTerm('http://example.org/person/1'),
                      predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
                    )[0]
                    .object
                as LiteralTerm)
            .value,
        equals('John Doe'),
      );

      expect(
        (graph
                    .findTriples(
                      subject: IriTerm('http://example.org/person/2'),
                      predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
                    )[0]
                    .object
                as LiteralTerm)
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
              IriTerm('http://example.org/person/1'),
              RdfPredicates.type,
              IriTerm('http://example.org/Person'),
            ),
            Triple(
              IriTerm('http://example.org/person/1'),
              IriTerm('http://example.org/name'),
              LiteralTerm.string('John'),
            ),
            Triple(
              IriTerm('http://example.org/person/1'),
              IriTerm('http://example.org/address'),
              IriTerm('http://example.org/address/1'),
            ),

            // Person 2
            Triple(
              IriTerm('http://example.org/person/2'),
              RdfPredicates.type,
              IriTerm('http://example.org/Person'),
            ),
            Triple(
              IriTerm('http://example.org/person/2'),
              IriTerm('http://example.org/name'),
              LiteralTerm.string('Jane'),
            ),
            Triple(
              IriTerm('http://example.org/person/2'),
              IriTerm('http://example.org/address'),
              IriTerm('http://example.org/address/2'),
            ),

            // Address 1
            Triple(
              IriTerm('http://example.org/address/1'),
              RdfPredicates.type,
              IriTerm('http://example.org/Address'),
            ),
            Triple(
              IriTerm('http://example.org/address/1'),
              IriTerm('http://example.org/city'),
              LiteralTerm.string('New York'),
            ),

            // Address 2
            Triple(
              IriTerm('http://example.org/address/2'),
              RdfPredicates.type,
              IriTerm('http://example.org/Address'),
            ),
            Triple(
              IriTerm('http://example.org/address/2'),
              IriTerm('http://example.org/city'),
              LiteralTerm.string('San Francisco'),
            ),
          ],
        );

        // Execute deserializeAll
        final objects = service.deserializeAll(graph);

        // Verify we get only Person objects, not addresses
        expect(objects.length, equals(2));

        // Check all objects are Persons
        expect(objects.where((obj) => obj is Person).length, equals(2));
        expect(objects.where((obj) => obj is Address).length, equals(0));

        // Verify person references are correct
        final people =
            objects.cast<Person>().toList()
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
              IriTerm('http://example.org/doc/1'),
              RdfPredicates.type,
              IriTerm('http://example.org/Document'),
            ),
            Triple(
              IriTerm('http://example.org/doc/1'),
              IriTerm('http://example.org/title'),
              LiteralTerm.string('Test Document'),
            ),
            Triple(
              IriTerm('http://example.org/doc/1'),
              IriTerm('http://example.org/tag'),
              IriTerm('http://example.org/tag/1'),
            ),
            Triple(
              IriTerm('http://example.org/doc/1'),
              IriTerm('http://example.org/tag'),
              IriTerm('http://example.org/tag/2'),
            ),

            // Referenced Tag 1
            Triple(
              IriTerm('http://example.org/tag/1'),
              RdfPredicates.type,
              IriTerm('http://example.org/Tag'),
            ),
            Triple(
              IriTerm('http://example.org/tag/1'),
              IriTerm('http://example.org/name'),
              LiteralTerm.string('important'),
            ),

            // Referenced Tag 2
            Triple(
              IriTerm('http://example.org/tag/2'),
              RdfPredicates.type,
              IriTerm('http://example.org/Tag'),
            ),
            Triple(
              IriTerm('http://example.org/tag/2'),
              IriTerm('http://example.org/name'),
              LiteralTerm.string('work'),
            ),

            // Standalone Tag (not referenced)
            Triple(
              IriTerm('http://example.org/tag/3'),
              RdfPredicates.type,
              IriTerm('http://example.org/Tag'),
            ),
            Triple(
              IriTerm('http://example.org/tag/3'),
              IriTerm('http://example.org/name'),
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
            IriTerm('http://example.org/doc/1'),
            RdfPredicates.type,
            IriTerm('http://example.org/Document'),
          ),
          Triple(
            IriTerm('http://example.org/doc/1'),
            IriTerm('http://example.org/title'),
            LiteralTerm.string('Test Document'),
          ),
          Triple(
            IriTerm('http://example.org/doc/1'),
            IriTerm('http://example.org/tag'),
            IriTerm('http://example.org/tag/1'),
          ),
          Triple(
            IriTerm('http://example.org/doc/1'),
            IriTerm('http://example.org/tag'),
            IriTerm('http://example.org/tag/2'),
          ),

          // Referenced Tag 1
          Triple(
            IriTerm('http://example.org/tag/1'),
            RdfPredicates.type,
            IriTerm('http://example.org/Tag'),
          ),
          Triple(
            IriTerm('http://example.org/tag/1'),
            IriTerm('http://example.org/name'),
            LiteralTerm.string('important'),
          ),

          // Referenced Tag 2
          Triple(
            IriTerm('http://example.org/tag/2'),
            RdfPredicates.type,
            IriTerm('http://example.org/Tag'),
          ),
          Triple(
            IriTerm('http://example.org/tag/2'),
            IriTerm('http://example.org/name'),
            LiteralTerm.string('work'),
          ),

          // Standalone Tag (not referenced)
          Triple(
            IriTerm('http://example.org/tag/3'),
            RdfPredicates.type,
            IriTerm('http://example.org/Tag'),
          ),
          Triple(
            IriTerm('http://example.org/tag/3'),
            IriTerm('http://example.org/name'),
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
  final List<String> tags;

  Document({required this.id, required this.title, this.tags = const []});
}

class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});
}

class DocumentDeserializer implements IriNodeDeserializer<Document> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Document');

  @override
  Document fromRdfNode(IriTerm subject, DeserializationContext context) {
    final title = context.require<String>(
      subject,
      IriTerm('http://example.org/title'),
    );

    final tagNames =
        context
            .getList<Tag>(subject, IriTerm('http://example.org/tag'))
            .map((tag) => tag.name)
            .toList();

    return Document(id: subject.iri, title: title, tags: tagNames);
  }
}

class DocumentWithTagReferencesDeserializer
    implements IriNodeDeserializer<Document> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Document');

  @override
  Document fromRdfNode(IriTerm subject, DeserializationContext context) {
    final title = context.require<String>(
      subject,
      IriTerm('http://example.org/title'),
    );

    final tagIris = context.getList<String>(
      subject,
      IriTerm('http://example.org/tag'),
      iriTermDeserializer: IriStringDeserializer(),
    );

    return Document(id: subject.iri, title: title, tags: tagIris);
  }
}

class TagDeserializer implements IriNodeDeserializer<Tag> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Tag');

  @override
  Tag fromRdfNode(IriTerm subject, DeserializationContext context) {
    final name = context.require<String>(
      subject,
      IriTerm('http://example.org/name'),
    );

    return Tag(id: subject.iri, name: name);
  }
}

// Helper deserializer for IRI strings
class IriStringDeserializer implements IriTermDeserializer<String> {
  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
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

class AddressMapper implements IriNodeMapper<Address> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Address');

  @override
  Address fromRdfNode(IriTerm subject, DeserializationContext context) {
    final city = context.require<String>(
      subject,
      IriTerm('http://example.org/city'),
    );
    return Address(id: subject.iri, city: city);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm(value.id);
    final triples = [
      Triple(
        subject,
        IriTerm('http://example.org/city'),
        LiteralTerm.string(value.city),
      ),
    ];
    return (subject, triples);
  }
}

class PersonMapper implements IriNodeMapper<Person> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Person');

  @override
  Person fromRdfNode(IriTerm subject, DeserializationContext context) {
    final name = context.require<String>(
      subject,
      IriTerm('http://example.org/name'),
    );
    final address = context.get<Address>(
      subject,
      IriTerm('http://example.org/address'),
    );
    return Person(id: subject.iri, name: name, address: address);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Person value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm(value.id);
    final triples = <Triple>[
      Triple(
        subject,
        IriTerm('http://example.org/name'),
        LiteralTerm.string(value.name),
      ),
    ];

    if (value.address != null) {
      triples.add(
        Triple(
          subject,
          IriTerm('http://example.org/address'),
          IriTerm(value.address!.id),
        ),
      );
    }

    return (subject, triples);
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

class TestPersonMapper implements IriNodeMapper<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://xmlns.com/foaf/0.1/Person');

  @override
  TestPerson fromRdfNode(IriTerm term, DeserializationContext context) {
    final id = term.iri;

    // Get name property
    final name = context.get<String>(
      term,
      IriTerm('http://xmlns.com/foaf/0.1/name'),
    );

    // Get age property
    final age =
        context.get<int>(term, IriTerm('http://xmlns.com/foaf/0.1/age')) ??
        0; // Default age to 0 if not present

    return TestPerson(id: id, name: name ?? 'Unknown', age: age);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    TestPerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm(value.id);
    final triples = <Triple>[
      // Name triple
      Triple(
        subject,
        IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string(value.name),
      ),

      // Age triple
      Triple(
        subject,
        IriTerm('http://xmlns.com/foaf/0.1/age'),
        LiteralTerm.typed(value.age.toString(), 'integer'),
      ),
    ];

    return (subject, triples);
  }
}

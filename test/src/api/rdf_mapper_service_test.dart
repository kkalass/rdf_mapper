import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperService', () {
    late RdfMapperRegistry registry;
    late RdfMapperService service;

    setUp(() {
      registry = RdfMapperRegistry();
      service = RdfMapperService(registry: registry);
    });

    test('fromTriplesByRdfSubjectId deserializes an object from triples', () {
      // Register a test mapper
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
        registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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

    test('fromGraphAllSubjects ignores subjects with unmapped types', () {
      // Register only a person mapper, not an address mapper
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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

      // Deserialize all subjects
      final objects = service.deserializeAll(graph);

      // Only the Person should be deserialized, the Address should be ignored
      expect(objects.length, equals(1));
      expect(objects[0], isA<TestPerson>());
      expect(
        (objects[0] as TestPerson).id,
        equals('http://example.org/person/1'),
      );
    });

    test('toGraph serializes an object to a graph', () {
      // Register a test mapper
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
          registry.registerSubjectMapper<TestPerson>(TestPersonMapper());
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
      expect(service.registry.hasSubjectSerializerFor<TestPerson>(), isFalse);
    });

    test('toGraphFromList serializes a list of objects to a graph', () {
      // Register a test mapper
      registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

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
  });
}

// Test mapper implementation
// Test model class
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({required this.id, required this.name, required this.age});
}

class TestPersonMapper implements RdfSubjectMapper<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://xmlns.com/foaf/0.1/Person');

  @override
  TestPerson fromRdfTerm(IriTerm term, DeserializationContext context) {
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
  (RdfSubject, List<Triple>) toRdfSubject(
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

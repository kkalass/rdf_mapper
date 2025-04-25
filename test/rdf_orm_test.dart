import 'package:rdf_core/constants/rdf_constants.dart';
import 'package:rdf_core/graph/rdf_graph.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/rdf_orm.dart';
import 'package:test/test.dart';

void main() {
  late RdfOrm rdfOrm;

  setUp(() {
    // Create a fresh instance for each test
    rdfOrm = RdfOrm.withDefaultRegistry();
  });

  group('RdfOrm facade', () {
    test(
      'withDefaultRegistry should create an instance with standard mappers',
      () {
        expect(rdfOrm, isNotNull);
        expect(rdfOrm.registry, isNotNull);

        // Check that standard primitive type serializers and deserializers are registered
        expect(rdfOrm.registry.hasLiteralDeserializerFor<String>(), isTrue);
        expect(rdfOrm.registry.hasLiteralDeserializerFor<int>(), isTrue);
        expect(rdfOrm.registry.hasLiteralDeserializerFor<double>(), isTrue);
        expect(rdfOrm.registry.hasLiteralDeserializerFor<bool>(), isTrue);
        expect(rdfOrm.registry.hasLiteralDeserializerFor<DateTime>(), isTrue);

        expect(rdfOrm.registry.hasLiteralSerializerFor<String>(), isTrue);
        expect(rdfOrm.registry.hasLiteralSerializerFor<int>(), isTrue);
        expect(rdfOrm.registry.hasLiteralSerializerFor<double>(), isTrue);
        expect(rdfOrm.registry.hasLiteralSerializerFor<bool>(), isTrue);
        expect(rdfOrm.registry.hasLiteralSerializerFor<DateTime>(), isTrue);
      },
    );

    test(
      'toGraph should serialize an object to RDF graph using a custom mapper',
      () {
        // Register a custom mapper
        rdfOrm.registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

        // Create a test object
        final person = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        );

        // Serialize to graph
        final graph = rdfOrm.toGraph(person);

        // Check for the person name triple
        final nameTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
        );
        // At least one name triple should exist
        expect(nameTriples.isNotEmpty, isTrue);

        // Find the name triple with the expected value
        final nameTriple = nameTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == 'John Doe',
          orElse: () => throw TestFailure('Expected name triple not found'),
        );
        expect(nameTriple, isNotNull);

        // Check for the person age triple
        final ageTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: IriTerm('http://xmlns.com/foaf/0.1/age'),
        );
        // At least one age triple should exist
        expect(ageTriples.isNotEmpty, isTrue);

        // Find the age triple with the expected value
        final ageTriple = ageTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == '30',
          orElse: () => throw TestFailure('Expected age triple not found'),
        );
        expect(ageTriple, isNotNull);

        // Check for the person type triple
        final typeTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: RdfConstants.typeIri,
        );
        // At least one type triple should exist
        expect(typeTriples.isNotEmpty, isTrue);

        // Find the type triple with the expected value
        final typeTriple = typeTriples.firstWhere(
          (t) =>
              t.object is IriTerm &&
              (t.object as IriTerm).iri == 'http://xmlns.com/foaf/0.1/Person',
          orElse: () => throw TestFailure('Expected type triple not found'),
        );
        expect(typeTriple, isNotNull);
      },
    );

    test('fromGraphBySubject should deserialize an RDF graph to an object', () {
      // Register a custom mapper
      rdfOrm.registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

      // Create a test graph
      final subjectId = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subjectId,
            RdfConstants.typeIri,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
        ],
      );

      // Deserialize from graph
      final person = rdfOrm.fromGraphBySubject<TestPerson>(graph, subjectId);

      // Verify the object properties
      expect(person, isNotNull);
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test('fromGraph should deserialize the single subject in an RDF graph', () {
      // Register a custom mapper
      rdfOrm.registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

      // Create a test graph with a single subject
      final subjectId = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            IriTerm('http://xmlns.com/foaf/0.1/age'),
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subjectId,
            RdfConstants.typeIri,
            IriTerm('http://xmlns.com/foaf/0.1/Person'),
          ),
        ],
      );

      // Deserialize from graph
      final person = rdfOrm.fromGraph<TestPerson>(graph);

      // Verify the object properties
      expect(person, isNotNull);
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test(
      'toGraphFromList should serialize a list of objects to an RDF graph',
      () {
        // Register a custom mapper
        rdfOrm.registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

        // Create test objects
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
        final graph = rdfOrm.toGraphFromList(people);

        // Check for John's name property
        final johnNameTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
        );

        // At least one name triple should exist for John
        expect(johnNameTriples.isNotEmpty, isTrue);

        // Find the name triple with John's name
        final johnNameTriple = johnNameTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == 'John Doe',
          orElse:
              () =>
                  throw TestFailure('Expected name triple for John not found'),
        );
        expect(johnNameTriple, isNotNull);

        // Check for Jane's name property
        final janeNameTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/2'),
          predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
        );

        // At least one name triple should exist for Jane
        expect(janeNameTriples.isNotEmpty, isTrue);

        // Find the name triple with Jane's name
        final janeNameTriple = janeNameTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == 'Jane Smith',
          orElse:
              () =>
                  throw TestFailure('Expected name triple for Jane not found'),
        );
        expect(janeNameTriple, isNotNull);
      },
    );

    test(
      'fromGraphAllSubjects should deserialize all subjects in an RDF graph',
      () {
        // Register a custom mapper
        rdfOrm.registry.registerSubjectMapper<TestPerson>(TestPersonMapper());

        // Create a test graph with multiple subjects
        final graph = RdfGraph(
          triples: [
            // Person 1
            Triple(
              IriTerm('http://example.org/person/1'),
              RdfConstants.typeIri,
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
              RdfConstants.typeIri,
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

        // Deserialize all subjects from graph
        final objects = rdfOrm.fromGraphAllSubjects(graph);

        // Verify we got both persons
        expect(objects.length, equals(2));

        // Convert to strongly typed list for easier assertions
        final people = objects.whereType<TestPerson>().toList();
        expect(people.length, equals(2));

        // Sort by name for consistent test assertions
        people.sort((a, b) => a.name.compareTo(b.name));

        // Verify Jane's properties
        expect(people[0].id, equals('http://example.org/person/2'));
        expect(people[0].name, equals('Jane Smith'));
        expect(people[0].age, equals(28));

        // Verify John's properties
        expect(people[1].id, equals('http://example.org/person/1'));
        expect(people[1].name, equals('John Doe'));
        expect(people[1].age, equals(30));
      },
    );

    test('register callback allows temporary registration of mappers', () {
      // Create a test object
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Serialize to graph using a temporary mapper registration
      final graph = rdfOrm.toGraph<TestPerson>(
        person,
        register: (registry) {
          registry.registerSubjectMapper<TestPerson>(TestPersonMapper());
        },
      );

      // Verify the serialization worked by checking for at least one name triple
      final nameTriples = graph.findTriples(
        subject: IriTerm('http://example.org/person/1'),
        predicate: IriTerm('http://xmlns.com/foaf/0.1/name'),
      );
      expect(nameTriples.isNotEmpty, isTrue);

      // Verify the temporary registration didn't affect the original registry
      expect(rdfOrm.registry.hasSubjectSerializerFor<TestPerson>(), isFalse);
    });
  });
}

// Test model class
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({required this.id, required this.name, required this.age});
}

// Test mapper implementation
class TestPersonMapper implements RdfSubjectMapper<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://xmlns.com/foaf/0.1/Person');

  @override
  TestPerson fromIriTerm(IriTerm term, DeserializationContext context) {
    final id = term.iri;

    // Get name property
    final name = context.getPropertyValue<String>(
      term,
      IriTerm('http://xmlns.com/foaf/0.1/name'),
    );

    // Get age property
    final age = context.getPropertyValue<int>(
      term,
      IriTerm('http://xmlns.com/foaf/0.1/age'),
    );

    return TestPerson(id: id, name: name!, age: age!);
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

      // Type triple
      Triple(subject, RdfConstants.typeIri, typeIri),
    ];

    return (subject, triples);
  }
}

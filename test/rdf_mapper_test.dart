import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    // Create a fresh instance for each test
    rdfMapper = RdfMapper.withDefaultRegistry();
  });

  group('RdfMapper facade', () {
    test(
      'withDefaultRegistry should create an instance with standard mappers',
      () {
        expect(rdfMapper, isNotNull);
        expect(rdfMapper.registry, isNotNull);

        // Check that standard primitive type serializers and deserializers are registered
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<String>(),
          isTrue,
        );
        expect(rdfMapper.registry.hasLiteralTermDeserializerFor<int>(), isTrue);
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<double>(),
          isTrue,
        );
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<bool>(),
          isTrue,
        );
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<DateTime>(),
          isTrue,
        );

        expect(
          rdfMapper.registry.hasLiteralTermSerializerFor<String>(),
          isTrue,
        );
        expect(rdfMapper.registry.hasLiteralTermSerializerFor<int>(), isTrue);
        expect(
          rdfMapper.registry.hasLiteralTermSerializerFor<double>(),
          isTrue,
        );
        expect(rdfMapper.registry.hasLiteralTermSerializerFor<bool>(), isTrue);
        expect(
          rdfMapper.registry.hasLiteralTermSerializerFor<DateTime>(),
          isTrue,
        );
      },
    );

    test(
      'toGraph should serialize an object to RDF graph using a custom mapper',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test object
        final person = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        );

        // Serialize to graph
        final graph = rdfMapper.graph.encodeObject(person);

        // Check for the person name triple
        final nameTriples = graph.findTriples(
          subject: const IriTerm('http://example.org/person/1'),
          predicate: SchemaPerson.givenName,
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
          subject: const IriTerm('http://example.org/person/1'),
          predicate: const IriTerm('http://xmlns.com/foaf/0.1/age'),
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
          subject: const IriTerm('http://example.org/person/1'),
          predicate: Rdf.type,
        );
        // At least one type triple should exist
        expect(typeTriples.isNotEmpty, isTrue);

        // Find the type triple with the expected value
        final typeTriple = typeTriples.firstWhere(
          (t) =>
              t.object is IriTerm &&
              (t.object as IriTerm).value == 'https://schema.org/Person',
          orElse: () => throw TestFailure('Expected type triple not found'),
        );
        expect(typeTriple, isNotNull);
      },
    );

    test('fromGraphBySubject should deserialize an RDF graph to an object', () {
      // Register a custom mapper
      rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph
      final subjectId = const IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            SchemaPerson.givenName,
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            SchemaPerson.foafAge,
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
              subjectId, Rdf.type, const IriTerm('https://schema.org/Person')),
        ],
      );

      // Deserialize from graph
      final person = rdfMapper.graph.decodeObject<TestPerson>(
        graph,
        subject: subjectId,
      );

      // Verify the object properties
      expect(person, isNotNull);
      expect(person.id, equals('http://example.org/person/1'));
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
    });

    test('fromGraph should deserialize the single subject in an RDF graph', () {
      // Register a custom mapper
      rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph with a single subject
      final subjectId = const IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            SchemaPerson.givenName,
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            SchemaPerson.foafAge,
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(subjectId, Rdf.type, SchemaPerson.classIri),
        ],
      );

      // Deserialize from graph
      final person = rdfMapper.graph.decodeObject<TestPerson>(graph);

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
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

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
        final graph = rdfMapper.graph.encodeObjects(people);

        // Check for John's name property
        final johnNameTriples = graph.findTriples(
          subject: const IriTerm('http://example.org/person/1'),
          predicate: SchemaPerson.givenName,
        );

        // At least one name triple should exist for John
        expect(johnNameTriples.isNotEmpty, isTrue);

        // Find the name triple with John's name
        final johnNameTriple = johnNameTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == 'John Doe',
          orElse: () =>
              throw TestFailure('Expected name triple for John not found'),
        );
        expect(johnNameTriple, isNotNull);

        // Check for Jane's name property
        final janeNameTriples = graph.findTriples(
          subject: const IriTerm('http://example.org/person/2'),
          predicate: SchemaPerson.givenName,
        );

        // At least one name triple should exist for Jane
        expect(janeNameTriples.isNotEmpty, isTrue);

        // Find the name triple with Jane's name
        final janeNameTriple = janeNameTriples.firstWhere(
          (t) =>
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == 'Jane Smith',
          orElse: () =>
              throw TestFailure('Expected name triple for Jane not found'),
        );
        expect(janeNameTriple, isNotNull);
      },
    );

    test(
      'fromGraphAllSubjects should deserialize all subjects in an RDF graph',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test graph with multiple subjects
        final graph = RdfGraph(
          triples: [
            // Person 1
            Triple(
              const IriTerm('http://example.org/person/1'),
              Rdf.type,
              SchemaPerson.classIri,
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              SchemaPerson.givenName,
              LiteralTerm.string('John Doe'),
            ),
            Triple(
              const IriTerm('http://example.org/person/1'),
              SchemaPerson.foafAge,
              LiteralTerm.typed('30', 'integer'),
            ),

            // Person 2
            Triple(
              const IriTerm('http://example.org/person/2'),
              Rdf.type,
              SchemaPerson.classIri,
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              SchemaPerson.givenName,
              LiteralTerm.string('Jane Smith'),
            ),
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://xmlns.com/foaf/0.1/age'),
              LiteralTerm.typed('28', 'integer'),
            ),
          ],
        );

        // Deserialize all subjects from graph
        final objects = rdfMapper.graph.decodeObjects(graph);

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
      final graph = rdfMapper.graph.encodeObject<TestPerson>(
        person,
        register: (registry) {
          registry.registerMapper<TestPerson>(TestPersonMapper());
        },
      );

      // Verify the serialization worked by checking for at least one name triple
      final nameTriples = graph.findTriples(
        subject: const IriTerm('http://example.org/person/1'),
        predicate: SchemaPerson.givenName,
      );
      expect(nameTriples.isNotEmpty, isTrue);

      // Verify the temporary registration didn't affect the original registry
      expect(
          rdfMapper.registry.hasResourceSerializerFor<TestPerson>(), isFalse);
    });

    test(
      'toString should serialize an object to RDF string using default Turtle format',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test object
        final person = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        );

        // Convert to string with default format (Turtle)
        final turtle = rdfMapper.encodeObject(person);

        // Verify the Turtle string contains expected content
        expect(turtle, contains('<http://example.org/person/1>'));
        expect(turtle, contains('a schema:Person'));
        expect(turtle, contains('schema:givenName'));
        expect(turtle, contains('"John Doe"'));
        expect(turtle, contains('foaf:age'));
        expect(turtle, contains('30'));
      },
    );

    test(
      'toString should serialize an object with blank child to RDF string using default Turtle format',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper(TestPersonMapper());
        rdfMapper.registerMapper(AddressMapper());

        // Create a test object
        final person = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
          address: Address(
            street: '123 Main St',
            city: 'Anytown',
            zipCode: '12345',
            country: 'USA',
          ),
        );

        // Convert to string with default format (Turtle)
        final turtle = rdfMapper.encodeObject(person);

        final expectedTurtle = """
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix schema: <https://schema.org/> .

<http://example.org/person/1> a schema:Person;
    foaf:age 30;
    schema:address [ a schema:PostalAddress ; schema:streetAddress "123 Main St" ; schema:addressLocality "Anytown" ; schema:postalCode "12345" ; schema:addressCountry "USA" ];
    schema:givenName "John Doe" .
""";
        // Verify the Turtle string contains expected content
        expect(turtle, equals(expectedTurtle.trim()));
      },
    );

    test(
      'fromString should deserialize an RDF string to an object using default Turtle format',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test Turtle string
        final turtle = '''
          @prefix schema: <https://schema.org/> .
          @prefix foaf: <http://xmlns.com/foaf/0.1/> .
          
          <http://example.org/person/1> a schema:Person ;
            schema:givenName "John Doe" ;
            foaf:age "30"^^<http://www.w3.org/2001/XMLSchema#integer> .
        ''';

        // Deserialize from string with default format (Turtle)
        final person = rdfMapper.decodeObject<TestPerson>(turtle);

        // Verify the object properties
        expect(person, isNotNull);
        expect(person.id, equals('http://example.org/person/1'));
        expect(person.name, equals('John Doe'));
        expect(person.age, equals(30));
      },
    );

    test(
      'toString should serialize an object with blank child to RDF string using default Turtle format including blank node',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper(TestPersonMapper());
        rdfMapper.registerMapper(AddressMapper());

        final turtle = """
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/person/1> a schema:Person;
    schema:givenName "John Doe";
    foaf:age "30"^^xsd:integer;
    schema:address _:b0 .
_:b0 a schema:PostalAddress;
    schema:streetAddress "123 Main St";
    schema:addressLocality "Anytown";
    schema:postalCode "12345";
    schema:addressCountry "USA" .
""";
        // Convert from string with detected format (Turtle)
        final person = rdfMapper.decodeObject(turtle);

        // Create a test object
        final expectedPerson = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
          address: Address(
            street: '123 Main St',
            city: 'Anytown',
            zipCode: '12345',
            country: 'USA',
          ),
        );

        // Verify the Turtle string contains expected content
        expect(person, equals(expectedPerson));
      },
    );
    test(
      'fromStringAllSubjects should deserialize multiple subjects from an RDF string',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test Turtle string with multiple subjects
        final turtle = '''
          @prefix foaf: <http://xmlns.com/foaf/0.1/> .
          @prefix schema: <https://schema.org/> .
          @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          
          <http://example.org/person/1> a schema:Person ;
            schema:givenName "John Doe" ;
            foaf:age "30"^^xsd:integer .
            
          <http://example.org/person/2> a schema:Person ;
            schema:givenName "Jane Smith" ;
            foaf:age "28"^^xsd:integer .
        ''';

        // Deserialize all subjects from Turtle string
        final objects = rdfMapper.decodeObjects(
          turtle,
          contentType: 'text/turtle',
        );

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

    test(
      'toStringFromList should serialize a list of objects to an RDF string',
      () {
        // Register a custom mapper
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

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

        // Convert to Turtle format
        final turtle = rdfMapper.encodeObjects(
          people,
          contentType: 'text/turtle',
        );

        // Verify the Turtle string contains content from both persons
        expect(turtle, contains('<http://example.org/person/1>'));
        expect(turtle, contains('<http://example.org/person/2>'));
        expect(turtle, contains('"John Doe"'));
        expect(turtle, contains('"Jane Smith"'));
        expect(turtle, contains('30'));
        expect(turtle, contains('28'));
      },
    );

    test('should use injected RdfCore instance', () {
      // Create RdfMapper with a real RdfCore
      final customRdfMapper = RdfMapper(
        registry: RdfMapperRegistry(),
        rdfCore: RdfCore.withStandardCodecs(
          additionalCodecs: [
            _PredefinedResultsCodec(
              contentType: 'application/predefined-results',
              parsed: [
                Triple(
                  const IriTerm('http://example.org/testperson'),
                  Rdf.type,
                  SchemaPerson.classIri,
                ),
                Triple(
                  const IriTerm('http://example.org/testperson'),
                  SchemaPerson.givenName,
                  LiteralTerm.string('Test Person'),
                ),
                Triple(
                  const IriTerm('http://example.org/testperson'),
                  SchemaPerson.foafAge,
                  LiteralTerm.integer(42),
                ),
              ],
              serialized: "TEST SERIALIZATION RESULT",
            ),
          ],
        ),
      );

      // Register mapper for testing
      customRdfMapper.registerMapper<TestPerson>(TestPersonMapper());

      // Test parsing using the mock
      final person = customRdfMapper.decodeObject<TestPerson>(
        'THIS CONTENT IS IGNORED BY THE MOCK',
      );
      expect(person.name, equals('Test Person'));
      expect(person.age, equals(42));

      // Test serialization using the mock
      final serialized = customRdfMapper.encodeObject(
        person,
        contentType: 'application/predefined-results',
      );
      expect(serialized, equals('TEST SERIALIZATION RESULT'));
    });
  });

  group('Mapper registration convenience methods', () {
    test(
      'registerMapper should register a subject serializer and deserializer in the registry',
      () {
        final mapper = TestPersonMapper();

        // Verify mapper is not registered initially
        expect(
            rdfMapper.registry.hasResourceSerializerFor<TestPerson>(), isFalse);
        expect(
          rdfMapper.registry.hasGlobalResourceDeserializerFor<TestPerson>(),
          isFalse,
        );

        // Register mapper through convenience method
        rdfMapper.registerMapper<TestPerson>(mapper);

        // Verify mapper is now registered
        expect(
            rdfMapper.registry.hasResourceSerializerFor<TestPerson>(), isTrue);
        expect(
          rdfMapper.registry.hasGlobalResourceDeserializerFor<TestPerson>(),
          isTrue,
        );

        // Test the registered mapper works for serialization
        final person = TestPerson(
          id: 'http://test.org/p1',
          name: 'Test',
          age: 25,
        );
        final graph = rdfMapper.graph.encodeObject(person);
        expect(graph.triples, isNotEmpty);
      },
    );

    test(
      'registerLiteralMapper should register a serializer and deserializer in the registry',
      () {
        final mapper = _TestLiteralMapper();

        // Verify serializer is not registered initially
        expect(
          rdfMapper.registry.hasLiteralTermSerializerFor<_TestType>(),
          isFalse,
        );
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<_TestType>(),
          isFalse,
        );

        // Register serializer through convenience method
        rdfMapper.registerMapper<_TestType>(mapper);

        // Verify serializer is now registered
        expect(
          rdfMapper.registry.hasLiteralTermSerializerFor<_TestType>(),
          isTrue,
        );
        expect(
          rdfMapper.registry.hasLiteralTermDeserializerFor<_TestType>(),
          isTrue,
        );
      },
    );

    test(
      'registerIriTermMapper should register a IriTerm serializer and deserializer in the registry',
      () {
        final mapper = _TestIriTermMapper();

        // Verify serializer is not registered initially
        expect(
          rdfMapper.registry.hasIriTermSerializerFor<_TestType>(),
          isFalse,
        );
        expect(
          rdfMapper.registry.hasIriTermDeserializerFor<_TestType>(),
          isFalse,
        );

        // Register serializer through convenience method
        rdfMapper.registerMapper<_TestType>(mapper);

        // Verify serializer is now registered
        expect(rdfMapper.registry.hasIriTermSerializerFor<_TestType>(), isTrue);
        expect(
          rdfMapper.registry.hasIriTermDeserializerFor<_TestType>(),
          isTrue,
        );
      },
    );
    test(
      'registerBlankSubjectTermMapper should register a serializer and deserializer for blank nodes in the registry',
      () {
        final mapper = AddressMapper();

        // Verify deserializer is not registered initially
        expect(
          rdfMapper.registry.hasLocalResourceDeserializerFor<Address>(),
          isFalse,
        );
        expect(rdfMapper.registry.hasResourceSerializerFor<Address>(), isFalse);

        // Register deserializer through convenience method
        rdfMapper.registerMapper<Address>(mapper);

        // Verify deserializer is now registered
        expect(
          rdfMapper.registry.hasLocalResourceDeserializerFor<Address>(),
          isTrue,
        );
        expect(rdfMapper.registry.hasResourceSerializerFor<Address>(), isTrue);
      },
    );
  });

  group('Advanced deserialization cases', () {
    test(
      'deserializeAll should only return root objects, not nested entities - Employee with full Company',
      () {
        // Register mappers for our test classes
        rdfMapper.registerMapper<Employee>(EmployeeMapper());
        rdfMapper.registerMapper<Address>(AddressMapper());
        rdfMapper.registerMapper<Company>(CompanyMapper());

        // Create a test Turtle string with nested objects
        // The graph describes:
        // 1. A person (John) with an address and an employer (company)
        // 2. A company with an address
        // 3. The company appears both as direct subjects
        //    and as nested object within other entities
        // 3. The address objects are blank
        final turtle = '''
        @prefix schema: <https://schema.org/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        
        <http://example.org/person/1> a schema:Person ;
          schema:givenName "John Doe" ;
          foaf:age "30"^^xsd:integer ;
          schema:address _:address1 ;
          schema:worksFor <http://example.org/company/1> .
        
        <http://example.org/company/1> a schema:Organization ;
          schema:name "ACME Corporation" ;
          schema:address _:address2 .
        
        _:address1 a schema:PostalAddress ;
          schema:streetAddress "123 Home St" ;
          schema:addressLocality "Hometown" ;
          schema:postalCode "12345" ;
          schema:addressCountry "USA" .
          
        _:address2 a schema:PostalAddress ;
          schema:streetAddress "456 Business Ave" ;
          schema:addressLocality "Commerce City" ;
          schema:postalCode "67890" ;
          schema:addressCountry "USA" .
      ''';

        // Deserialize all subjects from the graph
        final objects = rdfMapper.decodeObjects(
          turtle,
          contentType: 'text/turtle',
        );

        // We should only get one root-level object (person), because the company is
        // fully included by person and the address is a blank node
        expect(objects.length, equals(1));

        // Check the types of objects we got
        final people = objects.whereType<Employee>().toList();
        final companies = objects.whereType<Company>().toList();
        final addresses = objects.whereType<Address>().toList();

        expect(people.length, equals(1));
        expect(companies.length, equals(0));
        expect(
          addresses.length,
          equals(0),
        ); // Only the person should be considered a root object

        // Verify the person has the correct properties
        final person = people.first;
        expect(person.id, equals('http://example.org/person/1'));
        expect(person.name, equals('John Doe'));
        expect(person.age, equals(30));

        // The person should have a reference to both the address and company
        expect(person.address, isNotNull);
        if (person.employer != null) {
          expect(person.employer!.name, equals('ACME Corporation'));
          final company = person.employer!;
          expect(company.id, equals('http://example.org/company/1'));
          expect(company.name, equals('ACME Corporation'));
          expect(company.address, isNotNull);
        } else {
          fail('Person should have an employer');
        }
      },
    );

    test(
      'deserializeAll should only return root objects, not nested entities - Employee with referenced Company',
      () {
        // Register mappers for our test classes
        rdfMapper.registerMapper<EmployeeWithCompanyReference>(
          EmployeeWithCompanyReferenceMapper(),
        );
        rdfMapper.registerMapper<Address>(AddressMapper());
        rdfMapper.registerMapper<CompanyReference>(CompanyReferenceMapper());
        rdfMapper.registerMapper<Company>(CompanyMapper());

        // Create a test Turtle string with nested objects
        // The graph describes:
        // 1. A person (John) with an address and an employer (company)
        // 2. A company with an address
        // 3. The company appears both as direct subjects
        //    and as nested object within other entities
        // 3. The address objects are blank
        final turtle = '''
        @prefix schema: <https://schema.org/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        
        <http://example.org/person/1> a schema:Person ;
          schema:givenName "John Doe" ;
          foaf:age "30"^^xsd:integer ;
          schema:address _:address1 ;
          schema:worksFor <http://example.org/company/1> .
        
        <http://example.org/company/1> a schema:Organization ;
          schema:name "ACME Corporation" ;
          schema:address _:address2 .
        
        _:address1 a schema:PostalAddress ;
          schema:streetAddress "123 Home St" ;
          schema:addressLocality "Hometown" ;
          schema:postalCode "12345" ;
          schema:addressCountry "USA" .
          
        _:address2 a schema:PostalAddress ;
          schema:streetAddress "456 Business Ave" ;
          schema:addressLocality "Commerce City" ;
          schema:postalCode "67890" ;
          schema:addressCountry "USA" .
      ''';

        // Deserialize all subjects from the graph
        final objects = rdfMapper.decodeObjects(
          turtle,
          contentType: 'text/turtle',
        );

        // We should get two root-level objects (person and company), because the company is
        // only referenced by person and the address is a blank node
        expect(objects.length, equals(2));

        // Check the types of objects we got
        final people =
            objects.whereType<EmployeeWithCompanyReference>().toList();
        final companies = objects.whereType<Company>().toList();
        final addresses = objects.whereType<Address>().toList();

        expect(people.length, equals(1));
        expect(companies.length, equals(1));
        expect(addresses.length, equals(0));

        // Verify the person has the correct properties
        final person = people.first;
        expect(person.id, equals('http://example.org/person/1'));
        expect(person.name, equals('John Doe'));
        expect(person.age, equals(30));

        // The person should have a reference to both the address and company
        expect(person.address, isNotNull);
        if (person.employer != null) {
          expect(person.employer!.iri, equals('http://example.org/company/1'));
        } else {
          fail('Person should have an employer');
        }

        // Verify the company has the correct properties
        final company = companies.first;
        expect(company.id, equals('http://example.org/company/1'));
        expect(company.name, equals('ACME Corporation'));
        expect(company.address, isNotNull);
      },
    );
  });
}

// Test model classes
// Add company class for testing nested objects
class Company {
  final String id;
  final String name;
  final Address? address;

  Company({required this.id, required this.name, this.address});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          id == other.id &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ address.hashCode;
}

const worksForPredicate = const IriTerm('https://schema.org/worksFor');

// Update TestPerson to include employer
class Employee {
  final String id;
  final String name;
  final int age;
  final Address? address;
  final Company? employer;

  Employee({
    required this.id,
    required this.name,
    required this.age,
    this.address,
    this.employer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          address == other.address &&
          employer == other.employer;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      age.hashCode ^
      address.hashCode ^
      (employer?.hashCode ?? 0);
}

class CompanyReference {
  final String iri;

  CompanyReference({required this.iri});
}

class EmployeeWithCompanyReference {
  final String id;
  final String name;
  final int age;
  final Address? address;
  final CompanyReference? employer;

  EmployeeWithCompanyReference({
    required this.id,
    required this.name,
    required this.age,
    this.address,
    this.employer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeWithCompanyReference &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          address == other.address &&
          employer == other.employer;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      age.hashCode ^
      address.hashCode ^
      (employer?.hashCode ?? 0);
}

class CompanyReferenceMapper implements IriTermMapper<CompanyReference> {
  @override
  CompanyReference fromRdfTerm(
    IriTerm subject,
    DeserializationContext context,
  ) {
    return CompanyReference(iri: subject.value);
  }

  @override
  IriTerm toRdfTerm(CompanyReference company, SerializationContext context) {
    return context.createIriTerm(company.iri);
  }
}

// Test mapper for Company class
class CompanyMapper implements GlobalResourceMapper<Company> {
  static final namePredicate = SchemaOrganization.name;
  static final addressPredicate = SchemaOrganization.address;

  @override
  final IriTerm typeIri = SchemaOrganization.classIri;

  @override
  Company fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.value;
    final name = reader.require<String>(namePredicate);
    final address = reader.optional<Address>(addressPredicate);

    return Company(id: id, name: name, address: address);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Company company,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(company.id))
        .addValue(namePredicate, company.name)
        .addValueIfNotNull(addressPredicate, company.address)
        .build();
  }
}

// Update TestPersonMapper to include employer
class EmployeeMapper implements GlobalResourceMapper<Employee> {
  static final addressPredicate = SchemaPerson.address;
  static final employerPredicate = SchemaPerson.worksFor;
  static final givenNamePredicate = SchemaPerson.givenName;
  static final agePredicate = SchemaPerson.foafAge;

  @override
  final IriTerm typeIri = SchemaPerson.classIri;

  @override
  Employee fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.value;
    final name = reader.require<String>(givenNamePredicate);
    final age = reader.require<int>(agePredicate);
    final address = reader.optional<Address>(addressPredicate);
    final employer = reader.optional<Company>(employerPredicate);

    return Employee(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Employee person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(person.id))
        .addValue(givenNamePredicate, person.name)
        .addValue(agePredicate, person.age)
        .addValueIfNotNull(addressPredicate, person.address)
        .addValueIfNotNull(employerPredicate, person.employer)
        .build();
  }
}

class EmployeeWithCompanyReferenceMapper
    implements GlobalResourceMapper<EmployeeWithCompanyReference> {
  static final addressPredicate = SchemaPerson.address;
  static final employerPredicate = worksForPredicate;
  static final givenNamePredicate = SchemaPerson.givenName;
  static final agePredicate = const IriTerm('http://xmlns.com/foaf/0.1/age');

  @override
  final IriTerm typeIri = SchemaPerson.classIri;

  @override
  EmployeeWithCompanyReference fromRdfResource(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);
    final id = subject.value;
    final name = reader.require<String>(givenNamePredicate);
    final age = reader.require<int>(agePredicate);
    final address = reader.optional<Address>(addressPredicate);
    final employer = reader.optional<CompanyReference>(employerPredicate);

    return EmployeeWithCompanyReference(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    EmployeeWithCompanyReference person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(person.id))
        .addValue(givenNamePredicate, person.name)
        .addValue(agePredicate, person.age)
        .addValueIfNotNull(addressPredicate, person.address)
        .addValueIfNotNull(employerPredicate, person.employer)
        .build();
  }
}

class _PredefinedResultsParser extends RdfGraphDecoder {
  final RdfGraph graph;

  _PredefinedResultsParser({required this.graph});
  @override
  RdfGraph convert(String input, {String? documentUrl}) {
    return graph;
  }

  @override
  RdfGraphDecoder withOptions(RdfGraphDecoderOptions options) => this;
}

class _PredefinedResultsSerializer extends RdfGraphEncoder {
  final String serialized;

  _PredefinedResultsSerializer({required this.serialized});
  @override
  String convert(
    RdfGraph graph, {
    String? baseUri,
    Map<String, String> customPrefixes = const {},
  }) {
    return serialized;
  }

  @override
  RdfGraphEncoder withOptions(RdfGraphEncoderOptions options) => this;
}

class _PredefinedResultsCodec extends RdfGraphCodec {
  final String _contentType;

  final RdfGraph _parsedGraph;
  final String serialized;
  final bool _canParse;

  _PredefinedResultsCodec({
    required Iterable<Triple> parsed,
    required this.serialized,
    bool canParse = true,
    String contentType = 'application/predefined-results',
  })  : _canParse = canParse,
        _contentType = contentType,
        _parsedGraph = RdfGraph.fromTriples(parsed);

  @override
  bool canParse(String content) {
    return _canParse;
  }

  @override
  RdfGraphDecoder get decoder {
    return new _PredefinedResultsParser(graph: _parsedGraph);
  }

  @override
  RdfGraphEncoder get encoder {
    return _PredefinedResultsSerializer(serialized: serialized);
  }

  @override
  String get primaryMimeType => _contentType;

  @override
  Set<String> get supportedMimeTypes => {_contentType};

  @override
  RdfGraphCodec withOptions({
    RdfGraphEncoderOptions? encoder,
    RdfGraphDecoderOptions? decoder,
  }) =>
      this;
}

// Test model class
class TestPerson {
  final String id;
  final String name;
  final int age;
  final Address? address;
  final Company? employer;

  TestPerson({
    required this.id,
    required this.name,
    required this.age,
    this.address,
    this.employer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          address == other.address &&
          employer == other.employer;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      age.hashCode ^
      address.hashCode ^
      (employer?.hashCode ?? 0);
}

// Test mapper implementation
class TestPersonMapper implements GlobalResourceMapper<TestPerson> {
  @override
  final IriTerm typeIri = SchemaPerson.classIri;

  @override
  TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.value;
    final name = reader.require<String>(SchemaPerson.givenName);
    final age = reader.require<int>(SchemaPerson.foafAge);
    final address = reader.optional<Address>(SchemaPerson.address);
    final employer = reader.optional<Company>(SchemaPerson.worksFor);

    return TestPerson(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(person.id))
        .addValue(SchemaPerson.givenName, person.name)
        .addValue(SchemaPerson.foafAge, person.age)
        .addValueIfNotNull(SchemaPerson.address, person.address)
        .addValueIfNotNull(SchemaPerson.worksFor, person.employer)
        .build();
  }
}

// Implementation des Address-Mappers für Blank Nodes
class AddressMapper implements LocalResourceMapper<Address> {
  static final streetAddressPredicate = SchemaPostalAddress.streetAddress;
  static final addressLocalityPredicate = SchemaPostalAddress.addressLocality;
  static final postalCodePredicate = SchemaPostalAddress.postalCode;
  static final addressCountryPredicate = SchemaPostalAddress.addressCountry;

  @override
  final IriTerm typeIri = SchemaPostalAddress.classIri;

  @override
  Address fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    // Get address properties
    final street = reader.require<String>(streetAddressPredicate);
    final city = reader.require<String>(addressLocalityPredicate);
    final zipCode = reader.require<String>(postalCodePredicate);
    final country = reader.require<String>(addressCountryPredicate);

    return Address(
      street: street,
      city: city,
      zipCode: zipCode,
      country: country,
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Create a blank node subject
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(streetAddressPredicate, value.street)
        .addValue(addressLocalityPredicate, value.city)
        .addValue(postalCodePredicate, value.zipCode)
        .addValue(addressCountryPredicate, value.country)
        .build();
  }
}

// Address model class representing a postal address
class Address {
  final String street;
  final String city;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.zipCode,
    required this.country,
  });

  @override
  String toString() => 'Address($street, $city, $zipCode, $country)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          street == other.street &&
          city == other.city &&
          zipCode == other.zipCode &&
          country == other.country;

  @override
  int get hashCode =>
      street.hashCode ^ city.hashCode ^ zipCode.hashCode ^ country.hashCode;
}

// Simple test type for registration tests
class _TestType {
  final String value;
  _TestType(this.value);
}

// Test serializers and deserializers for registration tests
class _TestLiteralMapper implements LiteralTermMapper<_TestType> {
  final IriTerm datatype = Xsd.string;

  const _TestLiteralMapper();
  @override
  LiteralTerm toRdfTerm(_TestType value, SerializationContext context) {
    return LiteralTerm.string(value.value);
  }

  @override
  _TestType fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return _TestType(term.value);
  }
}

class _TestIriTermMapper implements IriTermMapper<_TestType> {
  @override
  IriTerm toRdfTerm(_TestType value, SerializationContext context) {
    return context.createIriTerm('http://example.org/${value.value}');
  }

  @override
  _TestType fromRdfTerm(IriTerm term, DeserializationContext context) {
    return _TestType(term.value.split('/').last);
  }
}

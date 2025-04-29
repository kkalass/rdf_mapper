import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
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
        final graph = rdfMapper.graph.serialize(person);

        // Check for the person name triple
        final nameTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: TestPersonMapper.givenNamePredicate,
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
          predicate: RdfPredicates.type,
        );
        // At least one type triple should exist
        expect(typeTriples.isNotEmpty, isTrue);

        // Find the type triple with the expected value
        final typeTriple = typeTriples.firstWhere(
          (t) =>
              t.object is IriTerm &&
              (t.object as IriTerm).iri == 'https://schema.org/Person',
          orElse: () => throw TestFailure('Expected type triple not found'),
        );
        expect(typeTriple, isNotNull);
      },
    );

    test('fromGraphBySubject should deserialize an RDF graph to an object', () {
      // Register a custom mapper
      rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

      // Create a test graph
      final subjectId = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            TestPersonMapper.givenNamePredicate,
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            TestPersonMapper.agePredicate,
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(
            subjectId,
            RdfPredicates.type,
            IriTerm('https://schema.org/Person'),
          ),
        ],
      );

      // Deserialize from graph
      final person = rdfMapper.graph.deserializeBySubject<TestPerson>(
        graph,
        subjectId,
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
      final subjectId = IriTerm('http://example.org/person/1');
      final graph = RdfGraph(
        triples: [
          Triple(
            subjectId,
            TestPersonMapper.givenNamePredicate,
            LiteralTerm.string('John Doe'),
          ),
          Triple(
            subjectId,
            TestPersonMapper.agePredicate,
            LiteralTerm.typed('30', 'integer'),
          ),
          Triple(subjectId, RdfPredicates.type, SchemaClasses.person),
        ],
      );

      // Deserialize from graph
      final person = rdfMapper.graph.deserialize<TestPerson>(graph);

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
        final graph = rdfMapper.graph.serialize(people);

        // Check for John's name property
        final johnNameTriples = graph.findTriples(
          subject: IriTerm('http://example.org/person/1'),
          predicate: TestPersonMapper.givenNamePredicate,
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
          predicate: TestPersonMapper.givenNamePredicate,
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
        rdfMapper.registerMapper<TestPerson>(TestPersonMapper());

        // Create a test graph with multiple subjects
        final graph = RdfGraph(
          triples: [
            // Person 1
            Triple(
              IriTerm('http://example.org/person/1'),
              RdfPredicates.type,
              SchemaClasses.person,
            ),
            Triple(
              IriTerm('http://example.org/person/1'),
              SchemaPersonProperties.givenName,
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
              SchemaClasses.person,
            ),
            Triple(
              IriTerm('http://example.org/person/2'),
              SchemaPersonProperties.givenName,
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
        final objects = rdfMapper.graph.deserializeAll(graph);

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
      final graph = rdfMapper.graph.serialize<TestPerson>(
        person,
        register: (registry) {
          registry.registerMapper<TestPerson>(TestPersonMapper());
        },
      );

      // Verify the serialization worked by checking for at least one name triple
      final nameTriples = graph.findTriples(
        subject: IriTerm('http://example.org/person/1'),
        predicate: SchemaPersonProperties.givenName,
      );
      expect(nameTriples.isNotEmpty, isTrue);

      // Verify the temporary registration didn't affect the original registry
      expect(rdfMapper.registry.hasNodeSerializerFor<TestPerson>(), isFalse);
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
        final turtle = rdfMapper.serialize(person);

        // Verify the Turtle string contains expected content
        expect(turtle, contains('<http://example.org/person/1>'));
        expect(turtle, contains('a schema:Person'));
        expect(turtle, contains('schema:givenName'));
        expect(turtle, contains('"John Doe"'));
        expect(turtle, contains('foaf:age'));
        expect(turtle, contains('"30"'));
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
        final turtle = rdfMapper.serialize(person);

        final expectedTurtle = """
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
        final person = rdfMapper.deserialize<TestPerson>(turtle);

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
        final person = rdfMapper.deserialize(turtle);

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
        final objects = rdfMapper.deserializeAll(
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
        final turtle = rdfMapper.serialize(people, contentType: 'text/turtle');

        // Verify the Turtle string contains content from both persons
        expect(turtle, contains('<http://example.org/person/1>'));
        expect(turtle, contains('<http://example.org/person/2>'));
        expect(turtle, contains('"John Doe"'));
        expect(turtle, contains('"Jane Smith"'));
        expect(turtle, contains('"30"'));
        expect(turtle, contains('"28"'));
      },
    );

    test('should use injected RdfCore instance', () {
      // Create RdfMapper with a real RdfCore
      final customRdfMapper = RdfMapper(
        registry: RdfMapperRegistry(),
        rdfCore:
            RdfCore.withStandardFormats()..registerFormat(
              _PredefinedResultsFormat(
                contentType: 'application/predefined-results',
                parsed: [
                  Triple(
                    IriTerm('http://example.org/testperson'),
                    RdfPredicates.type,
                    SchemaClasses.person,
                  ),
                  Triple(
                    IriTerm('http://example.org/testperson'),
                    TestPersonMapper.givenNamePredicate,
                    LiteralTerm.string('Test Person'),
                  ),
                  Triple(
                    IriTerm('http://example.org/testperson'),
                    TestPersonMapper.agePredicate,
                    LiteralTerm.typed("42", "integer"),
                  ),
                ],
                serialized: "TEST SERIALIZATION RESULT",
              ),
            ),
      );

      // Register mapper for testing
      customRdfMapper.registerMapper<TestPerson>(TestPersonMapper());

      // Test parsing using the mock
      final person = customRdfMapper.deserialize<TestPerson>(
        'THIS CONTENT IS IGNORED BY THE MOCK',
      );
      expect(person.name, equals('Test Person'));
      expect(person.age, equals(42));

      // Test serialization using the mock
      final serialized = customRdfMapper.serialize(
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
        expect(rdfMapper.registry.hasNodeSerializerFor<TestPerson>(), isFalse);
        expect(
          rdfMapper.registry.hasIriNodeDeserializerFor<TestPerson>(),
          isFalse,
        );

        // Register mapper through convenience method
        rdfMapper.registerMapper<TestPerson>(mapper);

        // Verify mapper is now registered
        expect(rdfMapper.registry.hasNodeSerializerFor<TestPerson>(), isTrue);
        expect(
          rdfMapper.registry.hasIriNodeDeserializerFor<TestPerson>(),
          isTrue,
        );

        // Test the registered mapper works for serialization
        final person = TestPerson(
          id: 'http://test.org/p1',
          name: 'Test',
          age: 25,
        );
        final graph = rdfMapper.graph.serialize(person);
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
          rdfMapper.registry.hasBlankNodeDeserializerFor<Address>(),
          isFalse,
        );
        expect(rdfMapper.registry.hasNodeSerializerFor<Address>(), isFalse);

        // Register deserializer through convenience method
        rdfMapper.registerMapper<Address>(mapper);

        // Verify deserializer is now registered
        expect(
          rdfMapper.registry.hasBlankNodeDeserializerFor<Address>(),
          isTrue,
        );
        expect(rdfMapper.registry.hasNodeSerializerFor<Address>(), isTrue);
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
        final objects = rdfMapper.deserializeAll(
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
        final objects = rdfMapper.deserializeAll(
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

const worksForPredicate = IriTerm.prevalidated('https://schema.org/worksFor');

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

class CompanyReferenceMapper implements IriTermMapper<CompanyReference> {
  @override
  CompanyReference fromRdfTerm(
    IriTerm subject,
    DeserializationContext context,
  ) {
    return CompanyReference(iri: subject.iri);
  }

  @override
  IriTerm toRdfTerm(CompanyReference company, SerializationContext context) {
    return IriTerm(company.iri);
  }
}

// Test mapper for Company class
class CompanyMapper implements IriNodeMapper<Company> {
  static final namePredicate = SchemaProperties.name;
  static final addressPredicate = SchemaPersonProperties.address;

  @override
  final IriTerm typeIri = SchemaClasses.organization;

  @override
  Company fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.iri;
    final name = reader.require<String>(namePredicate);
    final address = reader.get<Address>(addressPredicate);

    return Company(id: id, name: name, address: address);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Company company,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(company.id))
        .literal(namePredicate, company.name)
        .childNodeIfNotNull(addressPredicate, company.address)
        .build();
  }
}

// Update TestPersonMapper to include employer
class EmployeeMapper implements IriNodeMapper<Employee> {
  static final addressPredicate = SchemaPersonProperties.address;
  static final employerPredicate = worksForPredicate;
  static final givenNamePredicate = SchemaPersonProperties.givenName;
  static final agePredicate = IriTerm('http://xmlns.com/foaf/0.1/age');

  @override
  final IriTerm typeIri = SchemaClasses.person;

  @override
  Employee fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.iri;
    final name = reader.require<String>(givenNamePredicate);
    final age = reader.require<int>(agePredicate);
    final address = reader.get<Address>(addressPredicate);
    final employer = reader.get<Company>(employerPredicate);

    return Employee(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Employee person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(person.id))
        .literal(givenNamePredicate, person.name)
        .literal(agePredicate, person.age)
        .childNodeIfNotNull(addressPredicate, person.address)
        .childNodeIfNotNull(employerPredicate, person.employer)
        .build();
  }
}

class EmployeeWithCompanyReferenceMapper
    implements IriNodeMapper<EmployeeWithCompanyReference> {
  static final addressPredicate = SchemaPersonProperties.address;
  static final employerPredicate = worksForPredicate;
  static final givenNamePredicate = SchemaPersonProperties.givenName;
  static final agePredicate = IriTerm('http://xmlns.com/foaf/0.1/age');

  @override
  final IriTerm typeIri = SchemaClasses.person;

  @override
  EmployeeWithCompanyReference fromRdfNode(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);
    final id = subject.iri;
    final name = reader.require<String>(givenNamePredicate);
    final age = reader.require<int>(agePredicate);
    final address = reader.get<Address>(addressPredicate);
    final employer = reader.get<CompanyReference>(employerPredicate);

    return EmployeeWithCompanyReference(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    EmployeeWithCompanyReference person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(person.id))
        .literal(givenNamePredicate, person.name)
        .literal(agePredicate, person.age)
        .childNodeIfNotNull(addressPredicate, person.address)
        .iriIfNotNull(employerPredicate, person.employer)
        .build();
  }
}

class _PredefinedResultsParser implements RdfParser {
  final RdfGraph graph;

  _PredefinedResultsParser({required this.graph});
  @override
  RdfGraph parse(String input, {String? documentUrl}) {
    return graph;
  }
}

class _PredefinedResultsSerializer implements RdfSerializer {
  final String serialized;

  _PredefinedResultsSerializer({required this.serialized});
  @override
  String write(
    RdfGraph graph, {
    String? baseUri,
    Map<String, String> customPrefixes = const {},
  }) {
    return serialized;
  }
}

class _PredefinedResultsFormat implements RdfFormat {
  final String _contentType;

  final RdfGraph _parsedGraph;
  final String serialized;
  final bool _canParse;

  _PredefinedResultsFormat({
    required List<Triple> parsed,
    required this.serialized,
    bool canParse = true,
    String contentType = 'application/predefined-results',
  }) : _canParse = canParse,
       _contentType = contentType,
       _parsedGraph = RdfGraph(triples: parsed);

  @override
  bool canParse(String content) {
    return _canParse;
  }

  @override
  RdfParser createParser() {
    return new _PredefinedResultsParser(graph: _parsedGraph);
  }

  @override
  RdfSerializer createSerializer() {
    return _PredefinedResultsSerializer(serialized: serialized);
  }

  @override
  String get primaryMimeType => _contentType;

  @override
  Set<String> get supportedMimeTypes => {_contentType};
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
class TestPersonMapper implements IriNodeMapper<TestPerson> {
  static final addressPredicate = SchemaPersonProperties.address;
  static final employerPredicate = worksForPredicate;
  static final givenNamePredicate = SchemaPersonProperties.givenName;
  static final agePredicate = IriTerm('http://xmlns.com/foaf/0.1/age');

  @override
  final IriTerm typeIri = SchemaClasses.person;

  @override
  TestPerson fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final id = subject.iri;
    final name = reader.require<String>(givenNamePredicate);
    final age = reader.require<int>(agePredicate);
    final address = reader.get<Address>(addressPredicate);
    final employer = reader.get<Company>(employerPredicate);

    return TestPerson(
      id: id,
      name: name,
      age: age,
      address: address,
      employer: employer,
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    TestPerson person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(person.id))
        .literal(givenNamePredicate, person.name)
        .literal(agePredicate, person.age)
        .childNodeIfNotNull(addressPredicate, person.address)
        .childNodeIfNotNull(employerPredicate, person.employer)
        .build();
  }
}

// Implementation des Address-Mappers für Blank Nodes
class AddressMapper implements BlankNodeMapper<Address> {
  static final streetAddressPredicate = SchemaAddressProperties.streetAddress;
  static final addressLocalityPredicate =
      SchemaAddressProperties.addressLocality;
  static final postalCodePredicate = SchemaAddressProperties.postalCode;
  static final addressCountryPredicate = SchemaAddressProperties.addressCountry;

  @override
  final IriTerm typeIri = SchemaClasses.postalAddress;

  @override
  Address fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
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
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Create a blank node subject
    return context
        .nodeBuilder(BlankNodeTerm())
        .literal(streetAddressPredicate, value.street)
        .literal(addressLocalityPredicate, value.city)
        .literal(postalCodePredicate, value.zipCode)
        .literal(addressCountryPredicate, value.country)
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
  @override
  LiteralTerm toRdfTerm(_TestType value, SerializationContext context) {
    return LiteralTerm.string(value.value);
  }

  @override
  _TestType fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return _TestType(term.value);
  }
}

class _TestIriTermMapper implements IriTermMapper<_TestType> {
  @override
  IriTerm toRdfTerm(_TestType value, SerializationContext context) {
    return IriTerm('http://example.org/${value.value}');
  }

  @override
  _TestType fromRdfTerm(IriTerm term, DeserializationContext context) {
    return _TestType(term.iri.split('/').last);
  }
}

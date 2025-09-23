import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('RdfObjectCodec', () {
    late RdfMapperRegistry registry;
    late RdfMapper rdfMapper;
    setUp(() {
      registry = RdfMapperRegistry();
      registry.registerMapper(TestPersonMapper());
      rdfMapper = RdfMapper(registry: registry);
    });

    test('should encode and decode a single object', () {
      // Create a codec for the Person type, independent of the registry
      // or the rdfMapper created in the setUp.
      // This allows for more flexibility in testing.
      final codec = RdfObjectCodec<TestPerson>.forMappers(
        register: (registry) => registry.registerMapper(TestPersonMapper()),
      );

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Encode to graph
      final graph = codec.encode(person);

      // Verify graph contains expected triples
      expect(graph.triples, isNotEmpty);

      // Decode back to object
      final decoded = codec.decode(graph);

      // Verify object was correctly decoded
      expect(decoded.id, equals(person.id));
      expect(decoded.name, equals(person.name));
      expect(decoded.age, equals(person.age));
    });

    test('should handle temporary registration of mappers', () {
      // Create a test person with address (which doesn't have a registered mapper yet)
      final address = TestAddress(street: '123 Main St', city: 'Springfield');
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
        address: address,
      );

      // The person mapper is already registered, but the address mapper is not
      // Create a mapper for the address
      final addressMapper = TestAddressMapper();

      // Encode to graph with temporary registration
      final graph = rdfMapper.graph.encodeObject(
        person,
        register: (reg) {
          reg.registerMapper(addressMapper);
        },
      );

      // Verify graph contains expected triples
      expect(graph.triples, isNotEmpty);

      // Decode back to object, also with temporary registration
      final decoded = rdfMapper.graph.decodeObject(
        graph,
        register: (reg) {
          reg.registerMapper(addressMapper);
        },
      );

      // Verify object was correctly decoded, including address
      expect(decoded.id, equals(person.id));
      expect(decoded.name, equals(person.name));
      expect(decoded.age, equals(person.age));
      expect(decoded.address?.street, equals(address.street));
      expect(decoded.address?.city, equals(address.city));
    });
  });

  group('RdfObjectStringCodec', () {
    late RdfMapperRegistry registry;

    late RdfCore rdfCore;
    late RdfMapper rdfMapper;

    setUp(() {
      registry = RdfMapperRegistry();
      registry.registerMapper(TestPersonMapper());
      rdfCore = RdfCore.withStandardCodecs();
      rdfMapper = RdfMapper(registry: registry, rdfCore: rdfCore);
    });

    test('should encode and decode to/from Turtle string', () {
      // Create a codec for the Person type in Turtle format, independent of the registry, the rdfCore
      // or the rdfMapper created in the setUp.
      final codec = RdfObjectStringCodec<TestPerson>.forMappers(
        register: (reg) {
          reg.registerMapper(TestPersonMapper());
        },
        contentType: 'text/turtle',
      );

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/p1',
        name: 'John Doe',
        age: 30,
      );

      // Encode to Turtle string
      final turtle = codec.encode(person);

      // Verify string looks like Turtle
      expect(turtle, contains('@prefix'));
      expect(turtle, contains('person:p1'));
      expect(turtle, contains('John Doe'));

      // Decode back to object
      final decoded = codec.decode(turtle);

      // Verify object was correctly decoded
      expect(decoded.id, equals(person.id));
      expect(decoded.name, equals(person.name));
      expect(decoded.age, equals(person.age));
    });

    test('should encode and decode to/from JSON-LD', () {
      // Create a codec for the Person type in JSON-LD format fom the rdfMapper
      final codec = rdfMapper.objectCodec<TestPerson>(
        contentType: 'application/ld+json',
        register: (reg) {
          reg.registerMapper(TestPersonMapper());
        },
      );

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Encode to JSON-LD string
      final jsonLd = codec.encode(person);

      // Verify string looks like JSON-LD
      expect(jsonLd, contains('"@id"'));
      expect(jsonLd, contains('person:1'));
      expect(jsonLd, contains('John Doe'));

      // Decode back to object
      final decoded = codec.decode(jsonLd);

      // Verify object was correctly decoded
      expect(decoded.id, equals(person.id));
      expect(decoded.name, equals(person.name));
      expect(decoded.age, equals(person.age));
    });

    test('should customize output with baseUri and prefixes', () {
      // Custom prefixes
      final customPrefixes = {'ex': 'http://example.org/ns#'};

      // Create a codec for the Person type and configured turtle string serialization
      final codec = rdfMapper.objectCodec<TestPerson>(
        contentType: 'text/turtle',
        stringEncoderOptions: TurtleEncoderOptions(
          customPrefixes: customPrefixes,
        ),
      );

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      // Encode with base URI and custom prefixes
      final turtle = codec.encode(person, baseUri: 'http://example.org/');

      // Verify custom prefixes are used
      expect(turtle, contains('@prefix ex:'));
      expect(turtle, contains('@base <http://example.org/>'));

      // Decode with document URL
      final decoded = codec.decode(turtle, documentUrl: 'http://example.org/');

      // Verify object was correctly decoded
      expect(decoded.id, equals(person.id));
      expect(decoded.name, equals(person.name));
      expect(decoded.age, equals(person.age));
    });
  });

  group('RdfObjectCollectionStringCodec', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = RdfMapper.withMappers(
        (r) => r.registerMapper(TestPersonMapper()),
      );
    });

    test('should encode and decode a collection of mixed objects', () {
      // Create a codec for collections
      final codec = rdfMapper.objectsCodec<Object>(
        contentType: 'text/turtle',
        register: (reg) => reg
          ..registerMapper(TestPersonMapper())
          ..registerMapper(TestCompanyMapper()),
      );

      // Create a mixed collection
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final company = TestCompany(
        id: 'http://example.org/company/1',
        name: 'Acme Corp',
        foundedYear: 1947,
      );

      final collection = [person, company];

      // Encode to Turtle string
      final turtle = codec.encode(collection);

      // Verify string contains both entities
      expect(turtle, contains('<http://example.org/person/1>'));
      expect(turtle, contains('<http://example.org/company/1>'));
      expect(turtle, contains('John Doe'));
      expect(turtle, contains('Acme Corp'));

      // Decode back to objects
      final decoded = codec.decode(turtle);

      // Verify collection was correctly decoded
      expect(decoded.length, equals(2));

      final decodedPerson =
          decoded.firstWhere((e) => e is TestPerson) as TestPerson;
      expect(decodedPerson.id, equals(person.id));
      expect(decodedPerson.name, equals(person.name));

      final decodedCompany =
          decoded.firstWhere((e) => e is TestCompany) as TestCompany;
      expect(decodedCompany.id, equals(company.id));
      expect(decodedCompany.name, equals(company.name));
    });
  });
}

// Test data
class TestPerson {
  final String id;
  final String name;
  final int age;
  final TestAddress? address;

  TestPerson({
    required this.id,
    required this.name,
    required this.age,
    this.address,
  });
}

class TestAddress {
  final String street;
  final String city;

  TestAddress({required this.street, required this.city});
}

class TestCompany {
  final String id;
  final String name;
  final int foundedYear;

  TestCompany({
    required this.id,
    required this.name,
    required this.foundedYear,
  });
}

// Test mappers
class TestPersonMapper implements GlobalResourceMapper<TestPerson> {
  static final _ns = Namespace('http://example.org/ns#');

  @override
  IriTerm get typeIri => _ns('Person');

  @override
  TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestPerson(
      id: subject.value,
      name: reader.require<String>(_ns('name')),
      age: reader.require<int>(_ns('age')),
      address: reader.optional<TestAddress>(_ns('address')),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      context
          .resourceBuilder(context.createIriTerm(instance.id))
          .addValue<String>(Rdf.type, _ns('Person').value,
              // String value would default to Literal, so we need to specify
              // the IriTermSerializer to ensure it is serialized as an Iri
              serializer: const IriFullSerializer())
          .addValue<String>(_ns('name'), instance.name)
          .addValue<int>(_ns('age'), instance.age)
          .addValueIfNotNull<TestAddress>(_ns('address'), instance.address)
          .build();
}

class TestAddressMapper implements LocalResourceMapper<TestAddress> {
  static final _ns = Namespace('http://example.org/ns#');

  @override
  IriTerm get typeIri => _ns('Address');

  @override
  TestAddress fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestAddress(
      street: reader.require<String>(_ns('street')),
      city: reader.require<String>(_ns('city')),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    TestAddress instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      context
          .resourceBuilder(BlankNodeTerm())
          .addValue<String>(Rdf.type, _ns('Address').value,
              // String value would default to Literal, so we need to specify
              // the IriTermSerializer to ensure it is serialized as an Iri
              serializer: const IriFullSerializer())
          .addValue(_ns('street'), instance.street)
          .addValue(_ns('city'), instance.city)
          .build();
}

class TestCompanyMapper implements GlobalResourceMapper<TestCompany> {
  static final _ns = Namespace('http://example.org/ns#');

  @override
  IriTerm get typeIri => _ns('Company');

  @override
  TestCompany fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestCompany(
      id: subject.value,
      name: reader.require<String>(_ns('name')),
      foundedYear: reader.require<int>(_ns('foundedYear')),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestCompany instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      context
          .resourceBuilder(context.createIriTerm(instance.id))
          // IriTerm is automatically serialized as an IriTerm, we don't need to specify
          // the IriTermSerializer
          .addValue(Rdf.type, _ns('Company'))
          .addValue(_ns('name'), instance.name)
          .addValue(_ns('foundedYear'), instance.foundedYear)
          .build();
}

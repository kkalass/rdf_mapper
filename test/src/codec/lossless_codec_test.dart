import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

/// Tests for lossless RDF object and objects codecs
void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    rdfMapper = RdfMapper.withMappers((registry) {
      registry.registerMapper(TestPersonMapper());
      registry.registerMapper(TestCompanyMapper());
    });
  });

  group('RdfObjectLosslessCodec', () {
    test('should encode and decode single object with remainder graph', () {
      final codec = rdfMapper.graph.objectLosslessCodec<TestPerson>();

      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final remainderTriples = [
        Triple(
          const IriTerm('http://example.org/company/1'),
          Rdf.type,
          const IriTerm('http://example.org/Company'),
        ),
        Triple(
          const IriTerm('http://example.org/company/1'),
          const IriTerm('http://example.org/name'),
          LiteralTerm.string('Acme Corp'),
        ),
      ];
      final remainderGraph = RdfGraph(triples: remainderTriples);

      // Encode to graph
      final graph = codec.encode((person, remainderGraph));

      // Verify graph contains both person and remainder triples
      expect(graph.triples, hasLength(5)); // 3 person + 2 remainder
      expect(
        graph.triples.any((t) =>
            t.subject == const IriTerm('http://example.org/person/1') &&
            t.predicate == const IriTerm('http://example.org/name')),
        isTrue,
      );
      expect(
        graph.triples.any((t) =>
            t.subject == const IriTerm('http://example.org/company/1') &&
            t.predicate == const IriTerm('http://example.org/name')),
        isTrue,
      );

      // Decode back to object and remainder
      final (decodedPerson, decodedRemainder) = codec.decode(graph);

      // Verify person was correctly decoded
      expect(decodedPerson.id, equals(person.id));
      expect(decodedPerson.name, equals(person.name));
      expect(decodedPerson.age, equals(person.age));

      // Verify remainder contains expected triples
      expect(decodedRemainder.triples, hasLength(2));
      expect(
        decodedRemainder.triples.any((t) =>
            t.subject == const IriTerm('http://example.org/company/1') &&
            t.predicate == Rdf.type),
        isTrue,
      );
    });

    test('should handle empty remainder graph', () {
      final codec = rdfMapper.graph.objectLosslessCodec<TestPerson>();

      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final emptyRemainder = RdfGraph(triples: []);

      // Encode with empty remainder
      final graph = codec.encode((person, emptyRemainder));

      // Should only contain person triples
      expect(graph.triples, hasLength(3));

      // Decode back
      final (decodedPerson, decodedRemainder) = codec.decode(graph);

      expect(decodedPerson.name, equals('John Doe'));
      expect(decodedRemainder.triples, isEmpty);
    });

    test('should work with string codec conversion', () {
      final stringCodec = rdfMapper.objectLosslessCodec<TestPerson>(
        contentType: 'text/turtle',
      );

      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final remainderGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/other'),
          const IriTerm('http://example.org/property'),
          LiteralTerm.string('other value'),
        ),
      ]);

      // Encode to Turtle string
      final turtle = stringCodec.encode((person, remainderGraph));

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('other value'));
      expect(turtle, contains('<http://example.org/person/1>'));
      expect(
          turtle,
          anyOf(
            contains('<http://example.org/other>'),
            contains('ex:other'),
          ));

      // Decode back from string
      final (decodedPerson, decodedRemainder) = stringCodec.decode(turtle);

      expect(decodedPerson.name, equals('John Doe'));
      expect(decodedRemainder.triples, hasLength(1));
    });
  });

  group('RdfObjectsLosslessCodec', () {
    test('should encode and decode multiple objects with remainder graph', () {
      final codec = rdfMapper.graph.objectsLosslessCodec<TestPerson>();

      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
        TestPerson(
          id: 'http://example.org/person/2',
          name: 'Jane Smith',
          age: 25,
        ),
      ];

      final remainderTriples = [
        Triple(
          const IriTerm('http://example.org/company/1'),
          Rdf.type,
          const IriTerm('http://example.org/Company'),
        ),
        Triple(
          const IriTerm('http://example.org/company/1'),
          const IriTerm('http://example.org/name'),
          LiteralTerm.string('Acme Corp'),
        ),
      ];
      final remainderGraph = RdfGraph(triples: remainderTriples);

      // Encode to graph
      final graph = codec.encode((people, remainderGraph));

      // Verify graph contains both people and remainder triples
      expect(graph.triples, hasLength(8)); // 3*2 people + 2 remainder

      // Decode back to objects and remainder
      final (decodedPeople, decodedRemainder) = codec.decode(graph);

      // Verify people were correctly decoded
      expect(decodedPeople, hasLength(2));
      final johnDoe = decodedPeople.firstWhere((p) => p.name == 'John Doe');
      final janeSmith = decodedPeople.firstWhere((p) => p.name == 'Jane Smith');

      expect(johnDoe.age, equals(30));
      expect(janeSmith.age, equals(25));

      // Verify remainder contains expected triples
      expect(decodedRemainder.triples, hasLength(2));
      expect(
        decodedRemainder.triples.any((t) =>
            t.subject == const IriTerm('http://example.org/company/1') &&
            t.predicate == Rdf.type),
        isTrue,
      );
    });

    test('should handle mixed object types', () {
      final codec = rdfMapper.graph.objectsLosslessCodec<Object>();

      final objects = <Object>[
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
        TestCompany(
          id: 'http://example.org/company/1',
          name: 'Acme Corp',
          foundedYear: 1947,
        ),
      ];

      final remainderGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/other'),
          const IriTerm('http://example.org/property'),
          LiteralTerm.string('unrelated'),
        ),
      ]);

      // Encode mixed objects
      final graph = codec.encode((objects, remainderGraph));

      // Should contain triples from both objects plus remainder
      expect(graph.triples, hasLength(greaterThan(4)));

      // Decode back
      final (decodedObjects, decodedRemainder) = codec.decode(graph);

      expect(decodedObjects, hasLength(2));
      expect(decodedObjects.any((o) => o is TestPerson), isTrue);
      expect(decodedObjects.any((o) => o is TestCompany), isTrue);
      expect(decodedRemainder.triples, hasLength(1));
    });

    test('should work with string encoding for multiple objects', () {
      final stringCodec = rdfMapper.objectsLosslessCodec<TestPerson>(
        contentType: 'text/turtle',
      );

      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
        TestPerson(
          id: 'http://example.org/person/2',
          name: 'Jane Smith',
          age: 25,
        ),
      ];

      final remainderGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/metadata'),
          const IriTerm('http://example.org/created'),
          LiteralTerm.string('2025-07-09'),
        ),
      ]);

      // Encode to Turtle string
      final turtle = stringCodec.encode((people, remainderGraph));

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('Jane Smith'));
      expect(turtle, contains('2025-07-09'));

      // Decode back from string
      final (decodedPeople, decodedRemainder) = stringCodec.decode(turtle);

      expect(decodedPeople, hasLength(2));
      expect(decodedRemainder.triples, hasLength(1));
      expect(
        decodedRemainder.triples.first.object,
        equals(LiteralTerm.string('2025-07-09')),
      );
    });
  });

  group('Error handling', () {
    test('should handle invalid graphs gracefully', () {
      final codec = rdfMapper.graph.objectLosslessCodec<TestPerson>();

      final invalidGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/invalid'),
          const IriTerm('http://example.org/property'),
          LiteralTerm.string('value'),
        ),
      ]);

      expect(
        () => codec.decode(invalidGraph),
        throwsA(isA<PropertyValueNotFoundException>()),
      );
    });

    test('should handle objects without registered mappers', () {
      final codec = rdfMapper.objectLosslessCodec<UnmappedClass>();

      final unmappedObject = UnmappedClass(value: 'test');
      final remainderGraph = RdfGraph(triples: []);

      expect(
        () => codec.encode((unmappedObject, remainderGraph)),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });
  });
}

// Test classes
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({
    required this.id,
    required this.name,
    required this.age,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;
}

class TestPersonMapper implements GlobalResourceMapper<TestPerson> {
  static final _ns = Namespace('http://example.org/');

  @override
  IriTerm get typeIri => _ns('Person');

  @override
  TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestPerson(
      id: subject.value,
      name: reader.require<String>(_ns('name')),
      age: reader.require<int>(_ns('age')),
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
          .addValue(Rdf.type, _ns('Person'))
          .addValue(_ns('name'), instance.name)
          .addValue(_ns('age'), instance.age)
          .build();
}

class TestCompany {
  final String id;
  final String name;
  final int? foundedYear;

  TestCompany({
    required this.id,
    required this.name,
    this.foundedYear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCompany &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          foundedYear == other.foundedYear;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ foundedYear.hashCode;
}

class TestCompanyMapper implements GlobalResourceMapper<TestCompany> {
  static final _ns = Namespace('http://example.org/');

  @override
  IriTerm get typeIri => _ns('Company');

  @override
  TestCompany fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestCompany(
      id: subject.value,
      name: reader.require<String>(_ns('name')),
      foundedYear: reader.optional<int>(_ns('foundedYear')),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestCompany instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final builder = context
        .resourceBuilder(context.createIriTerm(instance.id))
        .addValue(Rdf.type, _ns('Company'))
        .addValue(_ns('name'), instance.name);

    if (instance.foundedYear != null) {
      builder.addValue(_ns('foundedYear'), instance.foundedYear!);
    }

    return builder.build();
  }
}

class UnmappedClass {
  final String value;
  UnmappedClass({required this.value});
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

/// Tests for lossless convenience methods on RdfMapper
void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    rdfMapper = RdfMapper.withMappers((registry) {
      registry.registerMapper(TestPersonMapper());
      registry.registerMapper(TestCompanyMapper());
    });
  });

  group('decodeObjectLossless convenience method', () {
    test('should decode single object with remainder from Turtle string', () {
      const turtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/company/1> rdf:type ex:Company ;
            ex:name "Acme Corp" ;
            ex:foundedYear 1947 .

        <http://example.org/unrelated> ex:property "some value" .
      ''';

      final (person, remainder) = rdfMapper.decodeObjectLossless<TestPerson>(
        turtle,
        contentType: 'text/turtle',
      );

      // Verify person was decoded correctly
      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));

      // Verify remainder contains company and unrelated triples
      expect(remainder.triples, hasLength(greaterThan(2)));
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/company/1')),
        isTrue,
      );
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/unrelated')),
        isTrue,
      );
    });

    test('should work with specific subject parameter', () {
      const turtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/person/2> rdf:type ex:Person ;
            ex:name "Jane Smith" ;
            ex:age 25 .
      ''';

      final (person, remainder) = rdfMapper.decodeObjectLossless<TestPerson>(
        turtle,
        subject: const IriTerm('http://example.org/person/2'),
        contentType: 'text/turtle',
      );

      // Should decode Jane, not John
      expect(person.name, equals('Jane Smith'));
      expect(person.age, equals(25));

      // Remainder should contain John's triples
      expect(remainder.triples, hasLength(3)); // John's type + name + age
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/person/1')),
        isTrue,
      );
    });

    test('should handle different content types', () {
      const jsonLd = '''
        {
          "@context": {
            "ex": "http://example.org/",
            "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          },
          "@graph": [
            {
              "@id": "http://example.org/person/1",
              "@type": "ex:Person",
              "ex:name": "John Doe",
              "ex:age": 30
            },
            {
              "@id": "http://example.org/other",
              "ex:property": "other value"
            }
          ]
        }
      ''';

      final (person, remainder) = rdfMapper.decodeObjectLossless<TestPerson>(
        jsonLd,
        contentType: 'application/ld+json',
      );

      expect(person.name, equals('John Doe'));
      expect(remainder.triples, isNotEmpty);
    });
  });

  group('encodeObjectLossless convenience method', () {
    test('should encode object with remainder to Turtle string', () {
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final remainderGraph = RdfGraph(triples: [
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
      ]);

      final turtle = rdfMapper.encodeObjectLossless(
        (person, remainderGraph),
        contentType: 'text/turtle',
      );

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('Acme Corp'));
      expect(turtle, contains('<http://example.org/person/1>'));
      expect(
          turtle,
          anyOf(
            contains('<http://example.org/company/1>'),
            contains('ex:company'),
          ));
    });

    test('should work with different content types', () {
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final remainderGraph = RdfGraph(triples: []);

      final jsonLd = rdfMapper.encodeObjectLossless(
        (person, remainderGraph),
        contentType: 'application/ld+json',
      );

      expect(jsonLd, contains('John Doe'));
      expect(jsonLd, contains('"@id"'));
      expect(jsonLd, contains('person:1'));
    });

    test('should handle empty remainder graph', () {
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
      );

      final emptyRemainder = RdfGraph(triples: []);

      final turtle = rdfMapper.encodeObjectLossless(
        (person, emptyRemainder),
        contentType: 'text/turtle',
      );

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('<http://example.org/person/1>'));
      // Should not contain any company information
      expect(turtle, isNot(contains('company')));
    });
  });

  group('decodeObjectsLossless convenience method', () {
    test('should decode multiple objects with remainder from Turtle string',
        () {
      const turtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/person/2> rdf:type ex:Person ;
            ex:name "Jane Smith" ;
            ex:age 25 .

        <http://example.org/company/1> rdf:type ex:Company ;
            ex:name "Acme Corp" ;
            ex:foundedYear 1947 .

        <http://example.org/unrelated> ex:property "some value" .
      ''';

      final (people, remainder) = rdfMapper.decodeObjectsLossless<TestPerson>(
        turtle,
        contentType: 'text/turtle',
      );

      // Should decode both people
      expect(people, hasLength(2));
      final names = people.map((p) => p.name).toSet();
      expect(names, containsAll(['John Doe', 'Jane Smith']));

      // Remainder should contain company and unrelated triples
      expect(remainder.triples, hasLength(greaterThan(3)));
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/company/1')),
        isTrue,
      );
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/unrelated')),
        isTrue,
      );
    });

    test('should work with mixed object types', () {
      const turtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/company/1> rdf:type ex:Company ;
            ex:name "Acme Corp" ;
            ex:foundedYear 1947 .

        <http://example.org/unrelated> ex:property "some value" .
      ''';

      // Decode all objects regardless of type
      final (objects, remainder) = rdfMapper.decodeObjectsLossless<Object>(
        turtle,
        contentType: 'text/turtle',
      );

      // Should decode both person and company
      expect(objects, hasLength(2));
      expect(objects.any((o) => o is TestPerson), isTrue);
      expect(objects.any((o) => o is TestCompany), isTrue);

      // Remainder should contain unrelated triple
      expect(remainder.triples, hasLength(1));
      expect(
        remainder.triples.any(
            (t) => t.subject == const IriTerm('http://example.org/unrelated')),
        isTrue,
      );
    });

    test('should handle empty results', () {
      const turtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/company/1> rdf:type ex:Company ;
            ex:name "Acme Corp" ;
            ex:foundedYear 1947 .
      ''';

      // Try to decode persons when there are none
      final (people, remainder) = rdfMapper.decodeObjectsLossless<TestPerson>(
        turtle,
        contentType: 'text/turtle',
      );

      expect(people, isEmpty);
      expect(
          remainder.triples, hasLength(3)); // All company triples in remainder
    });
  });

  group('encodeObjectsLossless convenience method', () {
    test('should encode multiple objects with remainder to Turtle string', () {
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

      final turtle = rdfMapper.encodeObjectsLossless(
        (people, remainderGraph),
        contentType: 'text/turtle',
      );

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('Jane Smith'));
      expect(turtle, contains('2025-07-09'));
      expect(turtle, contains('<http://example.org/person/1>'));
      expect(turtle, contains('<http://example.org/person/2>'));
    });

    test('should work with mixed object types', () {
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

      final remainderGraph = RdfGraph(triples: []);

      final turtle = rdfMapper.encodeObjectsLossless(
        (objects, remainderGraph),
        contentType: 'text/turtle',
      );

      expect(turtle, contains('John Doe'));
      expect(turtle, contains('Acme Corp'));
      expect(turtle, contains('1947'));
      expect(turtle, contains('<http://example.org/person/1>'));
      expect(turtle, contains('<http://example.org/company/1>'));
    });

    test('should handle empty object list', () {
      final emptyObjects = <TestPerson>[];
      final remainderGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/metadata'),
          const IriTerm('http://example.org/created'),
          LiteralTerm.string('2025-07-09'),
        ),
      ]);

      final turtle = rdfMapper.encodeObjectsLossless(
        (emptyObjects, remainderGraph),
        contentType: 'text/turtle',
      );

      expect(turtle, contains('2025-07-09'));
      expect(turtle, isNot(contains('person')));
    });

    test('should work with different content types', () {
      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
      ];

      final remainderGraph = RdfGraph(triples: []);

      final jsonLd = rdfMapper.encodeObjectsLossless(
        (people, remainderGraph),
        contentType: 'application/ld+json',
      );

      expect(jsonLd, contains('John Doe'));
      expect(jsonLd, contains('"@id"'));
      expect(jsonLd, contains('person:1'));
    });
    test('should work with different content types (relative IRIs)', () {
      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
      ];

      final remainderGraph = RdfGraph(triples: []);

      final jsonLd = rdfMapper.encodeObjectsLossless((people, remainderGraph),
          contentType: 'application/ld+json',
          baseUri: "http://example.org/person/",
          stringEncoderOptions:
              JsonLdEncoderOptions(includeBaseDeclaration: false));

      expect(jsonLd, contains('John Doe'));
      expect(jsonLd, contains('"@id"'));
      expect(jsonLd, contains('1'));
      expect(
          jsonLd.trim(),
          equals('''
{
  "@context": {
    "ex": "http://example.org/"
  },
  "@id": "1",
  "@type": "ex:Person",
  "ex:name": "John Doe",
  "ex:age": 30
}
'''
              .trim()));
    });
    test('should work with different content types (relative IRIs, encoder)',
        () {
      final people = [
        TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
        ),
      ];

      final remainderGraph = RdfGraph(triples: []);
      final codec = rdfMapper.objectsLosslessCodec<TestPerson>(
        contentType: 'application/ld+json',
        stringEncoderOptions:
            JsonLdEncoderOptions(includeBaseDeclaration: false),
      );
      final jsonLd = codec.encode(
        (people, remainderGraph),
        baseUri: "http://example.org/person/",
      );

      expect(jsonLd, contains('John Doe'));
      expect(jsonLd, contains('"@id"'));
      expect(jsonLd, contains('1'));
      expect(
          jsonLd.trim(),
          equals('''
{
  "@context": {
    "ex": "http://example.org/"
  },
  "@id": "1",
  "@type": "ex:Person",
  "ex:name": "John Doe",
  "ex:age": 30
}
'''
              .trim()));

      final decoded =
          codec.decode(jsonLd, documentUrl: "http://example.org/person/");
      expect(decoded, isNotNull);
      expect(decoded, isA<(List<TestPerson>, RdfGraph)>());
      expect(decoded.$2, equals(remainderGraph));
      expect(decoded.$1.length, equals(people.length));
      expect(decoded.$1.length, equals(1));
      expect(decoded.$1.first, equals(people.first));
      expect(decoded.$1.toList(), equals(people));
    });
  });

  group('round-trip compatibility', () {
    test('decodeObjectLossless and encodeObjectLossless should round-trip', () {
      const originalTurtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/company/1> rdf:type ex:Company ;
            ex:name "Acme Corp" ;
            ex:foundedYear 1947 .
      ''';

      // Decode
      final (person, remainder) = rdfMapper.decodeObjectLossless<TestPerson>(
        originalTurtle,
        contentType: 'text/turtle',
      );

      // Encode back
      final regeneratedTurtle = rdfMapper.encodeObjectLossless(
        (person, remainder),
        contentType: 'text/turtle',
      );

      // Should contain all the same information
      expect(regeneratedTurtle, contains('John Doe'));
      expect(regeneratedTurtle, contains('Acme Corp'));
      expect(regeneratedTurtle, contains('1947'));
    });

    test('decodeObjectsLossless and encodeObjectsLossless should round-trip',
        () {
      const originalTurtle = '''
        @prefix ex: <http://example.org/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

        <http://example.org/person/1> rdf:type ex:Person ;
            ex:name "John Doe" ;
            ex:age 30 .

        <http://example.org/person/2> rdf:type ex:Person ;
            ex:name "Jane Smith" ;
            ex:age 25 .

        <http://example.org/metadata> ex:timestamp "2025-07-09" .
      ''';

      // Decode
      final (people, remainder) = rdfMapper.decodeObjectsLossless<TestPerson>(
        originalTurtle,
        contentType: 'text/turtle',
      );

      // Encode back
      final regeneratedTurtle = rdfMapper.encodeObjectsLossless(
        (people, remainder),
        contentType: 'text/turtle',
      );

      // Should contain all the same information
      expect(regeneratedTurtle, contains('John Doe'));
      expect(regeneratedTurtle, contains('Jane Smith'));
      expect(regeneratedTurtle, contains('2025-07-09'));
    });
  });
}

// Test classes - reusing from lossless_codec_test.dart but with simpler structure
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

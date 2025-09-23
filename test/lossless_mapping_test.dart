import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

/// Test model for demonstrating lossless mapping with unmapped triples
class PersonWithUnmapped {
  final String id;
  final String name;
  final int age;
  final RdfGraph unmappedGraph;

  PersonWithUnmapped({
    required this.id,
    required this.name,
    required this.age,
    RdfGraph? unmappedGraph,
  }) : unmappedGraph = unmappedGraph ?? RdfGraph(triples: []);

  @override
  String toString() =>
      'PersonWithUnmapped($id, $name, $age, ${unmappedGraph.triples.length} unmapped triples)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonWithUnmapped &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          _graphsEqual(unmappedGraph, other.unmappedGraph);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;

  bool _graphsEqual(RdfGraph a, RdfGraph b) {
    return a.triples.toSet().difference(b.triples.toSet()).isEmpty &&
        b.triples.toSet().difference(a.triples.toSet()).isEmpty;
  }
}

/// Mapper that preserves unmapped triples in the object
class PersonWithUnmappedMapper
    implements GlobalResourceMapper<PersonWithUnmapped> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  static final namePredicate = const IriTerm('http://example.org/name');
  static final agePredicate = const IriTerm('http://example.org/age');
  final IriTermFactory _iriFactory;

  const PersonWithUnmappedMapper(
      {IriTermFactory iriFactory = IriTerm.validated})
      : _iriFactory = iriFactory;

  @override
  PersonWithUnmapped fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    final name = reader.require<String>(namePredicate);
    final age = reader.require<int>(agePredicate);

    // Get all unmapped triples for this subject
    final unmappedGraph = reader.getUnmapped<RdfGraph>();

    return PersonWithUnmapped(
      id: subject.value,
      name: name,
      age: age,
      unmappedGraph: unmappedGraph,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    PersonWithUnmapped value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(_iriFactory(value.id))
        .addValue(namePredicate, value.name)
        .addValue(agePredicate, value.age)
        .addUnmapped(value.unmappedGraph)
        .build();
  }
}

/// Simple test model without unmapped triples support
class SimplePerson {
  final String id;
  final String name;

  SimplePerson({required this.id, required this.name});

  @override
  String toString() => 'SimplePerson($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimplePerson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

/// Simple mapper that doesn't handle unmapped triples
class SimplePersonMapper implements GlobalResourceMapper<SimplePerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  static final namePredicate = const IriTerm('http://example.org/name');

  @override
  SimplePerson fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name = reader.require<String>(namePredicate);
    return SimplePerson(id: subject.value, name: name);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    SimplePerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(namePredicate, value.name)
        .build();
  }
}

void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    rdfMapper = RdfMapper.withDefaultRegistry();
  });

  group('CompletenessMode', () {
    setUp(() {
      rdfMapper.registerMapper<SimplePerson>(SimplePersonMapper());
    });

    test('strict mode throws exception for incomplete deserialization', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        ex:email "john@example.com" .
      ''';

      // SimplePerson mapper only handles name, so age and email remain unmapped
      expect(
        () => rdfMapper.decodeObject<SimplePerson>(turtle,
            completeness: CompletenessMode.strict),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });

    test('lenient mode allows incomplete deserialization', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        ex:email "john@example.com" .
      ''';

      // Should succeed even with unmapped triples
      final person = rdfMapper.decodeObject<SimplePerson>(turtle,
          completeness: CompletenessMode.lenient);

      expect(person.name, equals('John Doe'));
      expect(person.id, equals('http://example.org/person/1'));
    });

    test('warnOnly mode logs warnings but continues', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:unknownProperty "some value" .
      ''';

      // Should succeed with warnings logged
      final person = rdfMapper.decodeObject<SimplePerson>(turtle,
          completeness: CompletenessMode.warnOnly);

      expect(person.name, equals('John Doe'));
    });

    test('infoOnly mode logs info but continues', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:unknownProperty "some value" .
      ''';

      // Should succeed with info logs
      final person = rdfMapper.decodeObject<SimplePerson>(turtle,
          completeness: CompletenessMode.infoOnly);

      expect(person.name, equals('John Doe'));
    });

    test('decodeObjects respects completeness mode', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:unknownProperty "some value" .
        
      <http://example.org/person/2> a ex:Person ;
        ex:name "Jane Doe" ;
        ex:anotherUnknown "another value" .
      ''';

      // Strict mode should throw
      expect(
        () => rdfMapper.decodeObjects<SimplePerson>(turtle,
            completenessMode: CompletenessMode.strict),
        throwsA(isA<IncompleteDeserializationException>()),
      );

      // Lenient mode should succeed
      final people = rdfMapper.decodeObjects<SimplePerson>(turtle,
          completenessMode: CompletenessMode.lenient);

      expect(people, hasLength(2));
      expect(people.map((p) => p.name), containsAll(['John Doe', 'Jane Doe']));
    });
  });

  group('Lossless mapping with unmapped triples', () {
    setUp(() {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());
    });

    test('getUnmapped preserves unmapped triples in object', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      @prefix foaf: <http://xmlns.com/foaf/0.1/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        foaf:mbox "john@example.com" ;
        ex:website <http://johndoe.example.com> ;
        ex:birthYear "1993"^^<http://www.w3.org/2001/XMLSchema#gYear> .
      ''';

      final person = rdfMapper.decodeObject<PersonWithUnmapped>(turtle,
          completeness: CompletenessMode.lenient);

      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));
      expect(person.unmappedGraph.triples,
          hasLength(3)); // mbox, website, birthYear

      // Verify unmapped triples are preserved
      final unmappedTriples = person.unmappedGraph.triples;
      expect(
          unmappedTriples.any((t) =>
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/mbox')),
          isTrue);
      expect(
          unmappedTriples.any((t) =>
              t.predicate == const IriTerm('http://example.org/website')),
          isTrue);
      expect(
          unmappedTriples.any((t) =>
              t.predicate == const IriTerm('http://example.org/birthYear')),
          isTrue);
    });

    test('addUnmapped preserves unmapped triples during serialization', () {
      // Create a person with unmapped triples
      final unmappedGraph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/person/1'),
          const IriTerm('http://xmlns.com/foaf/0.1/mbox'),
          LiteralTerm.string('john@example.com'),
        ),
        Triple(
          const IriTerm('http://example.org/person/1'),
          const IriTerm('http://example.org/website'),
          const IriTerm('http://johndoe.example.com'),
        ),
      ]);

      final person = PersonWithUnmapped(
        id: 'http://example.org/person/1',
        name: 'John Doe',
        age: 30,
        unmappedGraph: unmappedGraph,
      );

      final graph = rdfMapper.graph.encodeObject(person);

      // Verify all triples are present
      expect(graph.triples, hasLength(5)); // type + name + age + 2 unmapped

      // Verify unmapped triples are included
      expect(
          graph.triples.any((t) =>
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/mbox')),
          isTrue);
      expect(
          graph.triples.any((t) =>
              t.predicate == const IriTerm('http://example.org/website')),
          isTrue);
    });

    test('roundtrip preserves all data including unmapped triples', () {
      final originalTurtle = '''
      @prefix ex: <http://example.org/> .
      @prefix foaf: <http://xmlns.com/foaf/0.1/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        foaf:mbox "john@example.com" ;
        ex:website <http://johndoe.example.com> ;
        ex:customProperty "custom value" .
      ''';

      // Decode with unmapped preservation
      final person = rdfMapper.decodeObject<PersonWithUnmapped>(originalTurtle,
          completeness: CompletenessMode.lenient);

      // Encode back to RDF
      final regeneratedGraph = rdfMapper.graph.encodeObject(person);

      // Parse original for comparison
      final rdfCore = RdfCore.withStandardCodecs();
      final codec = rdfCore.codec(contentType: 'text/turtle');
      final originalGraph = codec.decode(originalTurtle);

      // Both graphs should have the same number of triples
      expect(regeneratedGraph.triples.length,
          equals(originalGraph.triples.length));

      // All original triples should be preserved
      for (final originalTriple in originalGraph.triples) {
        expect(regeneratedGraph.triples.contains(originalTriple), isTrue,
            reason: 'Missing triple: $originalTriple');
      }
    });
  });

  group('Lossless decoding methods', () {
    setUp(() {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());
    });

    test('decodeObjectLossless returns object and remainder graph', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 .
        
      <http://example.org/organization/1> a ex:Organization ;
        ex:name "ACME Corp" ;
        ex:industry "Technology" .
        
      <http://example.org/unrelated> ex:property "some value" .
      ''';

      final (person, remainder) =
          rdfMapper.decodeObjectLossless<PersonWithUnmapped>(turtle);

      expect(person.name, equals('John Doe'));
      expect(person.age, equals(30));

      // Remainder should contain organization and unrelated triples
      expect(remainder.triples, hasLength(greaterThan(3)));

      // Verify organization triples are in remainder
      expect(
          remainder.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/organization/1')),
          isTrue);
      expect(
          remainder.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/unrelated')),
          isTrue);
    });

    test('decodeObjectLossless with unmapped triples combines both strategies',
        () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      @prefix foaf: <http://xmlns.com/foaf/0.1/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        foaf:mbox "john@example.com" .
        
      <http://example.org/organization/1> a ex:Organization ;
        ex:name "ACME Corp" .
      ''';

      final (person, remainder) =
          rdfMapper.decodeObjectLossless<PersonWithUnmapped>(turtle);

      // Person should have unmapped mbox triple
      expect(person.unmappedGraph.triples, hasLength(1));
      expect(person.unmappedGraph.triples.first.predicate,
          equals(const IriTerm('http://xmlns.com/foaf/0.1/mbox')));

      // Remainder should contain organization triples
      expect(
          remainder.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/organization/1')),
          isTrue);
    });

    test('lossless codec provides functional API', () {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());

      final codec = rdfMapper.objectLosslessCodec<PersonWithUnmapped>();

      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        ex:unknownProperty "unknown value" .
        
      <http://example.org/other> ex:property "other value" .
      ''';

      final (person, remainder) = codec.decode(turtle);

      expect(person.name, equals('John Doe'));
      expect(remainder.triples, isNotEmpty);

      // Test encoding back
      final regenerated = codec.encode((person, remainder));
      expect(regenerated, contains('John Doe'));
      expect(regenerated, contains('other value'));
    });
  });

  group('Error handling and edge cases', () {
    test('IncompleteDeserializationException provides detailed information',
        () {
      rdfMapper.registerMapper<SimplePerson>(SimplePersonMapper());

      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        ex:email "john@example.com" .
        
      <http://example.org/unknown/1> a ex:UnknownType ;
        ex:property "value" .
      ''';

      try {
        rdfMapper.decodeObject<SimplePerson>(turtle,
            completeness: CompletenessMode.strict);
        fail('Expected IncompleteDeserializationException');
      } catch (e) {
        expect(e, isA<IncompleteDeserializationException>());
        final exception = e as IncompleteDeserializationException;

        expect(exception.hasRemainingTriples, isTrue);
        expect(exception.remainingTripleCount, greaterThan(0));
        expect(exception.unmappedSubjects, isNotEmpty);
        expect(exception.unmappedTypes, isNotEmpty);

        final message = exception.toString();
        expect(message, contains('unprocessed triples'));
        expect(message, contains('CompletenessMode.lenient'));
      }
    });

    test('empty unmapped graph is handled correctly', () {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());

      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 .
      ''';

      final person = rdfMapper.decodeObject<PersonWithUnmapped>(turtle,
          completeness: CompletenessMode.lenient);

      expect(person.unmappedGraph.triples, isEmpty);

      // Serialization should still work
      final graph = rdfMapper.graph.encodeObject(person);
      expect(graph.triples, hasLength(3)); // type + name + age
    });

    test('blank nodes are included in unmapped triples when requested', () {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());

      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        ex:address [
          ex:street "123 Main St" ;
          ex:city "Example City"
        ] .
      ''';

      final person = rdfMapper.decodeObject<PersonWithUnmapped>(turtle,
          completeness: CompletenessMode.lenient);

      // Blank node and its properties should be in unmapped triples
      expect(person.unmappedGraph.triples,
          hasLength(3)); // address + street + city
      expect(
          person.unmappedGraph.triples.any((t) => t.subject is BlankNodeTerm),
          isTrue);
    });
  });

  group('Multiple objects and collections', () {
    setUp(() {
      rdfMapper.registerMapper<PersonWithUnmapped>(PersonWithUnmappedMapper());
    });

    test('decodeObjects with lossless preserves unmapped data per object', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      @prefix foaf: <http://xmlns.com/foaf/0.1/> .
      
      <http://example.org/person/1> a ex:Person ;
        ex:name "John Doe" ;
        ex:age 30 ;
        foaf:mbox "john@example.com" .
        
      <http://example.org/person/2> a ex:Person ;
        ex:name "Jane Doe" ;
        ex:age 25 ;
        ex:website <http://janedoe.example.com> .
      ''';

      final people = rdfMapper.decodeObjects<PersonWithUnmapped>(turtle,
          completenessMode: CompletenessMode.lenient);

      expect(people, hasLength(2));

      final john = people.firstWhere((p) => p.name == 'John Doe');
      final jane = people.firstWhere((p) => p.name == 'Jane Doe');

      // Each person should have their own unmapped triples
      expect(john.unmappedGraph.triples, hasLength(1));
      expect(john.unmappedGraph.triples.first.predicate.toString(),
          contains('mbox'));

      expect(jane.unmappedGraph.triples, hasLength(1));
      expect(jane.unmappedGraph.triples.first.predicate.toString(),
          contains('website'));
    });

    test('encodeObjects preserves all unmapped data', () {
      final people = [
        PersonWithUnmapped(
          id: 'http://example.org/person/1',
          name: 'John Doe',
          age: 30,
          unmappedGraph: RdfGraph(triples: [
            Triple(
              const IriTerm('http://example.org/person/1'),
              const IriTerm('http://xmlns.com/foaf/0.1/mbox'),
              LiteralTerm.string('john@example.com'),
            ),
          ]),
        ),
        PersonWithUnmapped(
          id: 'http://example.org/person/2',
          name: 'Jane Doe',
          age: 25,
          unmappedGraph: RdfGraph(triples: [
            Triple(
              const IriTerm('http://example.org/person/2'),
              const IriTerm('http://example.org/website'),
              const IriTerm('http://janedoe.example.com'),
            ),
          ]),
        ),
      ];

      final graph = rdfMapper.graph.encodeObjects(people);

      // Should have all mapped and unmapped triples
      expect(graph.triples, hasLength(8)); // 2*(type + name + age + unmapped)

      // Verify unmapped triples are present
      expect(
          graph.triples.any((t) =>
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/mbox')),
          isTrue);
      expect(
          graph.triples.any((t) =>
              t.predicate == const IriTerm('http://example.org/website')),
          isTrue);
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('PredicatesMapMapper tests', () {
    late PredicatesMapMapper mapper;

    setUp(() {
      mapper = const PredicatesMapMapper();
    });

    group('Properties', () {
      test('should have deep set to false', () {
        expect(mapper.deep, isFalse);
      });
    });

    group('fromUnmappedTriples', () {
      test('should handle empty triples', () {
        final result = mapper.fromUnmappedTriples([]);
        expect(result, isEmpty);
      });

      test('should handle single triple', () {
        final predicate = const IriTerm('http://example.org/name');
        final object = LiteralTerm('John');
        final triples = [
          Triple(
              const IriTerm('http://example.org/person1'), predicate, object),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result, hasLength(1));
        expect(result[predicate], equals([object]));
      });

      test('should handle multiple triples with same predicate', () {
        final predicate = const IriTerm('http://example.org/hobby');
        final object1 = LiteralTerm('Reading');
        final object2 = LiteralTerm('Swimming');
        final subject = const IriTerm('http://example.org/person1');
        final triples = [
          Triple(subject, predicate, object1),
          Triple(subject, predicate, object2),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result, hasLength(1));
        expect(result[predicate], hasLength(2));
        expect(result[predicate], contains(object1));
        expect(result[predicate], contains(object2));
      });

      test('should handle multiple predicates', () {
        final namePredicate = const IriTerm('http://example.org/name');
        final agePredicate = const IriTerm('http://example.org/age');
        final nameObject = LiteralTerm('John');
        final ageObject = LiteralTerm('30');
        final subject = const IriTerm('http://example.org/person1');
        final triples = [
          Triple(subject, namePredicate, nameObject),
          Triple(subject, agePredicate, ageObject),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result, hasLength(2));
        expect(result[namePredicate], equals([nameObject]));
        expect(result[agePredicate], equals([ageObject]));
      });

      test('should handle mixed object types', () {
        final namePredicate = const IriTerm('http://example.org/name');
        final friendPredicate = const IriTerm('http://example.org/friend');
        final nameObject = LiteralTerm('John');
        final friendObject = const IriTerm('http://example.org/person2');
        final blankNodeObject = BlankNodeTerm();
        final subject = const IriTerm('http://example.org/person1');
        final triples = [
          Triple(subject, namePredicate, nameObject),
          Triple(subject, friendPredicate, friendObject),
          Triple(subject, friendPredicate, blankNodeObject),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result, hasLength(2));
        expect(result[namePredicate], equals([nameObject]));
        expect(result[friendPredicate], hasLength(2));
        expect(result[friendPredicate], contains(friendObject));
        expect(result[friendPredicate], contains(blankNodeObject));
      });

      test('should ignore subject when grouping by predicate', () {
        final predicate = const IriTerm('http://example.org/name');
        final object1 = LiteralTerm('John');
        final object2 = LiteralTerm('Jane');
        final subject1 = const IriTerm('http://example.org/person1');
        final subject2 = const IriTerm('http://example.org/person2');
        final triples = [
          Triple(subject1, predicate, object1),
          Triple(subject2, predicate, object2),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result, hasLength(1));
        expect(result[predicate], hasLength(2));
        expect(result[predicate], contains(object1));
        expect(result[predicate], contains(object2));
      });

      test('should preserve order of objects for same predicate', () {
        final predicate = const IriTerm('http://example.org/item');
        final object1 = LiteralTerm('First');
        final object2 = LiteralTerm('Second');
        final object3 = LiteralTerm('Third');
        final subject = const IriTerm('http://example.org/list');
        final triples = [
          Triple(subject, predicate, object1),
          Triple(subject, predicate, object2),
          Triple(subject, predicate, object3),
        ];

        final result = mapper.fromUnmappedTriples(triples);

        expect(result[predicate], equals([object1, object2, object3]));
      });
    });

    group('toUnmappedTriples', () {
      test('should handle empty map', () {
        final subject = const IriTerm('http://example.org/person1');
        final map = <RdfPredicate, List<RdfObject>>{};

        final result = mapper.toUnmappedTriples(subject, map);

        expect(result, isEmpty);
      });

      test('should handle single predicate with single object', () {
        final subject = const IriTerm('http://example.org/person1');
        final predicate = const IriTerm('http://example.org/name');
        final object = LiteralTerm('John');
        final map = {
          predicate: [object]
        };

        final result = mapper.toUnmappedTriples(subject, map);

        expect(result, hasLength(1));
        final triple = result.first;
        expect(triple.subject, equals(subject));
        expect(triple.predicate, equals(predicate));
        expect(triple.object, equals(object));
      });

      test('should handle single predicate with multiple objects', () {
        final subject = const IriTerm('http://example.org/person1');
        final predicate = const IriTerm('http://example.org/hobby');
        final object1 = LiteralTerm('Reading');
        final object2 = LiteralTerm('Swimming');
        final map = {
          predicate: [object1, object2]
        };

        final result = mapper.toUnmappedTriples(subject, map).toList();

        expect(result, hasLength(2));
        expect(result[0].subject, equals(subject));
        expect(result[0].predicate, equals(predicate));
        expect(result[0].object, equals(object1));
        expect(result[1].subject, equals(subject));
        expect(result[1].predicate, equals(predicate));
        expect(result[1].object, equals(object2));
      });

      test('should handle multiple predicates', () {
        final subject = const IriTerm('http://example.org/person1');
        final namePredicate = const IriTerm('http://example.org/name');
        final agePredicate = const IriTerm('http://example.org/age');
        final nameObject = LiteralTerm('John');
        final ageObject = LiteralTerm('30');
        final map = {
          namePredicate: [nameObject],
          agePredicate: [ageObject]
        };

        final result = mapper.toUnmappedTriples(subject, map).toList();

        expect(result, hasLength(2));

        final nameTriple =
            result.firstWhere((t) => t.predicate == namePredicate);
        expect(nameTriple.subject, equals(subject));
        expect(nameTriple.object, equals(nameObject));

        final ageTriple = result.firstWhere((t) => t.predicate == agePredicate);
        expect(ageTriple.subject, equals(subject));
        expect(ageTriple.object, equals(ageObject));
      });

      test('should handle mixed object types', () {
        final subject = const IriTerm('http://example.org/person1');
        final predicate = const IriTerm('http://example.org/ref');
        final literalObject = LiteralTerm('SomeValue');
        final iriObject = const IriTerm('http://example.org/other');
        final blankObject = BlankNodeTerm();
        final map = {
          predicate: [literalObject, iriObject, blankObject]
        };

        final result = mapper.toUnmappedTriples(subject, map).toList();

        expect(result, hasLength(3));
        expect(result.map((t) => t.object), contains(literalObject));
        expect(result.map((t) => t.object), contains(iriObject));
        expect(result.map((t) => t.object), contains(blankObject));
      });

      test('should preserve order of objects', () {
        final subject = const IriTerm('http://example.org/list');
        final predicate = const IriTerm('http://example.org/item');
        final object1 = LiteralTerm('First');
        final object2 = LiteralTerm('Second');
        final object3 = LiteralTerm('Third');
        final map = {
          predicate: [object1, object2, object3]
        };

        final result = mapper.toUnmappedTriples(subject, map).toList();

        expect(result, hasLength(3));
        expect(result[0].object, equals(object1));
        expect(result[1].object, equals(object2));
        expect(result[2].object, equals(object3));
      });

      test('should handle empty object list for predicate', () {
        final subject = const IriTerm('http://example.org/person1');
        final predicate = const IriTerm('http://example.org/empty');
        final map = {predicate: <RdfObject>[]};

        final result = mapper.toUnmappedTriples(subject, map);

        expect(result, isEmpty);
      });

      test('should work with different subject types', () {
        final blankSubject = BlankNodeTerm();
        final predicate = const IriTerm('http://example.org/name');
        final object = LiteralTerm('BlankNodeSubject');
        final map = {
          predicate: [object]
        };

        final result = mapper.toUnmappedTriples(blankSubject, map);

        expect(result, hasLength(1));
        final triple = result.first;
        expect(triple.subject, equals(blankSubject));
        expect(triple.predicate, equals(predicate));
        expect(triple.object, equals(object));
      });
    });

    group('Round-trip consistency', () {
      test('should maintain consistency for simple case', () {
        final subject = const IriTerm('http://example.org/person1');
        final predicate = const IriTerm('http://example.org/name');
        final object = LiteralTerm('John');
        final originalTriples = [
          Triple(subject, predicate, object),
        ];

        final map = mapper.fromUnmappedTriples(originalTriples);
        final resultTriples = mapper.toUnmappedTriples(subject, map).toList();

        expect(resultTriples, hasLength(1));
        expect(resultTriples[0].subject, equals(subject));
        expect(resultTriples[0].predicate, equals(predicate));
        expect(resultTriples[0].object, equals(object));
      });

      test('should maintain consistency for complex case', () {
        final subject = const IriTerm('http://example.org/person1');
        final namePredicate = const IriTerm('http://example.org/name');
        final hobbyPredicate = const IriTerm('http://example.org/hobby');
        final friendPredicate = const IriTerm('http://example.org/friend');

        final nameObject = LiteralTerm('John');
        final hobby1Object = LiteralTerm('Reading');
        final hobby2Object = LiteralTerm('Swimming');
        final friendObject = const IriTerm('http://example.org/person2');

        final originalTriples = [
          Triple(subject, namePredicate, nameObject),
          Triple(subject, hobbyPredicate, hobby1Object),
          Triple(subject, hobbyPredicate, hobby2Object),
          Triple(subject, friendPredicate, friendObject),
        ];

        final map = mapper.fromUnmappedTriples(originalTriples);
        final resultTriples = mapper.toUnmappedTriples(subject, map).toSet();

        expect(resultTriples, hasLength(4));
        expect(resultTriples,
            contains(Triple(subject, namePredicate, nameObject)));
        expect(resultTriples,
            contains(Triple(subject, hobbyPredicate, hobby1Object)));
        expect(resultTriples,
            contains(Triple(subject, hobbyPredicate, hobby2Object)));
        expect(resultTriples,
            contains(Triple(subject, friendPredicate, friendObject)));
      });

      test(
          'should handle mixed subjects in fromUnmappedTriples but single subject in toUnmappedTriples',
          () {
        final subject1 = const IriTerm('http://example.org/person1');
        final subject2 = const IriTerm('http://example.org/person2');
        final predicate = const IriTerm('http://example.org/name');
        final object1 = LiteralTerm('John');
        final object2 = LiteralTerm('Jane');

        final originalTriples = [
          Triple(subject1, predicate, object1),
          Triple(subject2, predicate, object2),
        ];

        final map = mapper.fromUnmappedTriples(originalTriples);

        // The map should contain both objects under the same predicate
        expect(map[predicate], containsAll([object1, object2]));

        // When converting back, we use a single subject
        final targetSubject = const IriTerm('http://example.org/target');
        final resultTriples =
            mapper.toUnmappedTriples(targetSubject, map).toList();

        expect(resultTriples, hasLength(2));
        expect(resultTriples.every((t) => t.subject == targetSubject), isTrue);
        expect(resultTriples.every((t) => t.predicate == predicate), isTrue);
        expect(resultTriples.map((t) => t.object),
            containsAll([object1, object2]));
      });
    });

    group('Integration tests with RdfMapper for PredicateMapMapper', () {
      late RdfMapper rdfMapper;

      setUp(() {
        rdfMapper = RdfMapper.withDefaultRegistry();
        rdfMapper.registerMapper(const FooPredicateMapper());
      });

      test('should serialize and deserialize object with unmapped predicates',
          () {
        final data = <RdfPredicate, List<RdfObject>>{
          const IriTerm('http://example.org/name'): [LiteralTerm('John')],
          const IriTerm('http://example.org/age'): [LiteralTerm('30')],
          const IriTerm('http://example.org/hobby'): [
            LiteralTerm('Reading'),
            LiteralTerm('Swimming')
          ],
        };

        final foo = FooPredicate('http://example.org/person1', data);

        // Serialize to RDF
        final rdfString = rdfMapper.encodeObject(foo);
        expect(rdfString, isNotEmpty);

        // Deserialize back
        final decodedFoo = rdfMapper.decodeObject<FooPredicate>(rdfString);

        expect(decodedFoo.id, equals(foo.id));
        expect(decodedFoo.data, hasLength(3));
        expect(decodedFoo.data[const IriTerm('http://example.org/name')],
            equals([LiteralTerm('John')]));
        expect(decodedFoo.data[const IriTerm('http://example.org/age')],
            equals([LiteralTerm('30')]));
        expect(decodedFoo.data[const IriTerm('http://example.org/hobby')],
            containsAll([LiteralTerm('Reading'), LiteralTerm('Swimming')]));
      });
    });
    group('Integration tests with RdfMapper for IriTermMapMapper', () {
      late RdfMapper rdfMapper;

      setUp(() {
        rdfMapper = RdfMapper.withDefaultRegistry();
        rdfMapper.registerMapper(const FooMapper());
      });

      test('should serialize and deserialize object with unmapped predicates',
          () {
        final data = <IriTerm, List<RdfObject>>{
          const IriTerm('http://example.org/name'): [LiteralTerm('John')],
          const IriTerm('http://example.org/age'): [LiteralTerm('30')],
          const IriTerm('http://example.org/hobby'): [
            LiteralTerm('Reading'),
            LiteralTerm('Swimming')
          ],
        };

        final foo = Foo('http://example.org/person1', data);

        // Serialize to RDF
        final rdfString = rdfMapper.encodeObject(foo);
        expect(rdfString, isNotEmpty);

        // Deserialize back
        final decodedFoo = rdfMapper.decodeObject<Foo>(rdfString);

        expect(decodedFoo.id, equals(foo.id));
        expect(decodedFoo.data, hasLength(3));
        expect(decodedFoo.data[const IriTerm('http://example.org/name')],
            equals([LiteralTerm('John')]));
        expect(decodedFoo.data[const IriTerm('http://example.org/age')],
            equals([LiteralTerm('30')]));
        expect(decodedFoo.data[const IriTerm('http://example.org/hobby')],
            containsAll([LiteralTerm('Reading'), LiteralTerm('Swimming')]));
      });

      test('should handle empty unmapped data', () {
        final foo = Foo('http://example.org/person2', {});

        final rdfString = rdfMapper.encodeObject(foo);
        final decodedFoo = rdfMapper.decodeObject<Foo>(rdfString);

        expect(decodedFoo.id, equals(foo.id));
        expect(decodedFoo.data, isEmpty);
      });

      test('should handle mixed object types in unmapped data', () {
        final data = <IriTerm, List<RdfObject>>{
          const IriTerm('http://example.org/name'): [LiteralTerm('Alice')],
          const IriTerm('http://example.org/friend'): [
            const IriTerm('http://example.org/person2'),
            BlankNodeTerm()
          ],
          const IriTerm('http://example.org/score'): [LiteralTerm('95.5')],
        };

        final foo = Foo('http://example.org/person3', data);

        final rdfString = rdfMapper.encodeObject(foo);
        final decodedFoo = rdfMapper.decodeObject<Foo>(rdfString);

        expect(decodedFoo.id, equals(foo.id));
        expect(decodedFoo.data, hasLength(3));

        // Check that all object types are preserved
        final nameObjects =
            decodedFoo.data[const IriTerm('http://example.org/name')]!;
        expect(nameObjects, hasLength(1));
        expect(nameObjects.first, isA<LiteralTerm>());

        final friendObjects =
            decodedFoo.data[const IriTerm('http://example.org/friend')]!;
        expect(friendObjects, hasLength(2));
        expect(friendObjects.any((o) => o is IriTerm), isTrue);
        expect(friendObjects.any((o) => o is BlankNodeTerm), isTrue);
      });

      test('should preserve order of objects for same predicate', () {
        final data = <IriTerm, List<RdfObject>>{
          const IriTerm('http://example.org/item'): [
            LiteralTerm('First'),
            LiteralTerm('Second'),
            LiteralTerm('Third'),
          ],
        };

        final foo = Foo('http://example.org/list', data);

        final rdfString = rdfMapper.encodeObject(foo);
        final decodedFoo = rdfMapper.decodeObject<Foo>(rdfString);

        final items =
            decodedFoo.data[const IriTerm('http://example.org/item')]!;
        expect(items, hasLength(3));
        expect(items[0], equals(LiteralTerm('First')));
        expect(items[1], equals(LiteralTerm('Second')));
        expect(items[2], equals(LiteralTerm('Third')));
      });

      test('should work with multiple objects having unmapped data', () {
        final foo1 = Foo('http://example.org/person1', {
          const IriTerm('http://example.org/name'): [LiteralTerm('John')],
        });

        final foo2 = Foo('http://example.org/person2', {
          const IriTerm('http://example.org/name'): [LiteralTerm('Jane')],
          const IriTerm('http://example.org/age'): [LiteralTerm('25')],
        });

        final rdfString = rdfMapper.encodeObjects([foo1, foo2]);
        final decodedFoos = rdfMapper.decodeObjects<Foo>(rdfString).toList();

        expect(decodedFoos, hasLength(2));

        final decodedFoo1 = decodedFoos.firstWhere((f) => f.id == foo1.id);
        expect(decodedFoo1.data[const IriTerm('http://example.org/name')],
            equals([LiteralTerm('John')]));

        final decodedFoo2 = decodedFoos.firstWhere((f) => f.id == foo2.id);
        expect(decodedFoo2.data[const IriTerm('http://example.org/name')],
            equals([LiteralTerm('Jane')]));
        expect(decodedFoo2.data[const IriTerm('http://example.org/age')],
            equals([LiteralTerm('25')]));
      });
    });
  });
}

// Test domain class that uses PredicatesMapMapper for unmapped data
class Foo {
  final String id;
  final Map<IriTerm, List<RdfObject>> data;

  Foo(this.id, this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Foo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Foo(id: $id, data: $data)';
}

// Mapper for the test domain class
class FooMapper implements GlobalResourceMapper<Foo> {
  const FooMapper();

  @override
  Foo fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    final id = reader.require<String>(const IriTerm('http://example.org/id'));
    final unmappedData = reader.getUnmapped<Map<IriTerm, List<RdfObject>>>();

    return Foo(id, unmappedData);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      Foo value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(value.id);
    final builder = context.resourceBuilder(subject);

    builder.addValue(const IriTerm('http://example.org/id'), value.id);
    builder.addUnmapped(value.data);

    return builder.build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Foo');
}

class FooPredicate {
  final String id;
  final Map<RdfPredicate, List<RdfObject>> data;

  FooPredicate(this.id, this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FooPredicate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Foo(id: $id, data: $data)';
}

// Mapper for the test domain class
class FooPredicateMapper implements GlobalResourceMapper<FooPredicate> {
  const FooPredicateMapper();

  @override
  FooPredicate fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    final id = reader.require<String>(const IriTerm('http://example.org/id'));
    final unmappedData =
        reader.getUnmapped<Map<RdfPredicate, List<RdfObject>>>();

    return FooPredicate(id, unmappedData);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      FooPredicate value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(value.id);
    final builder = context.resourceBuilder(subject);

    builder.addValue(const IriTerm('http://example.org/id'), value.id);
    builder.addUnmapped(value.data);

    return builder.build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/FooPredicate');
}

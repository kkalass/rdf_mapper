import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('IncompleteDeserializationException', () {
    group('exception creation and properties', () {
      test('should create exception with all properties', () {
        final graph = RdfGraph(triples: [
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://example.org/ns#name'),
            LiteralTerm('John Doe'),
          ),
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://example.org/ns#Person'),
          ),
        ]);

        final unmappedSubjects = <RdfSubject>{
          const IriTerm('http://example.org/person/1')
        };
        final unmappedTypes = <IriTerm>{
          const IriTerm('http://example.org/ns#Person')
        };

        final exception = IncompleteDeserializationException(
          remainingGraph: graph,
        );

        expect(exception.remainingGraph, equals(graph));
        expect(exception.unmappedSubjects, equals(unmappedSubjects));
        expect(exception.unmappedTypes, equals(unmappedTypes));
        expect(exception.hasRemainingTriples, isTrue);
        expect(exception.remainingTripleCount, equals(2));
        expect(exception.unmappedSubjectCount, equals(1));
        expect(exception.unmappedTypeCount, equals(1));
      });

      test('should handle empty sets and graphs', () {
        final emptyGraph = RdfGraph(triples: []);
        final exception = IncompleteDeserializationException(
          remainingGraph: emptyGraph,
        );

        expect(exception.hasRemainingTriples, isFalse);
        expect(exception.remainingTripleCount, equals(0));
        expect(exception.unmappedSubjectCount, equals(0));
        expect(exception.unmappedTypeCount, equals(0));
      });
    });

    group('message formatting', () {
      test('should format message with single triple', () {
        final graph = RdfGraph(triples: [
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://example.org/ns#name'),
            LiteralTerm('John Doe'),
          ),
        ]);

        final exception = IncompleteDeserializationException(
          remainingGraph: graph,
        );

        final message = exception.toString();
        expect(message, contains('1 unprocessed triple found'));
        expect(message, contains('CompletenessMode.lenient'));
        expect(message, contains('decodeObjectsLossless'));
        expect(message, contains('Unprocessed Triples'));
        expect(message, contains('<http://example.org/person/1>'));
        expect(message, contains('John Doe'));
      });

      test('should format message with multiple triples', () {
        final graph = RdfGraph(triples: [
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://example.org/ns#name'),
            LiteralTerm('John Doe'),
          ),
          Triple(
            const IriTerm('http://example.org/person/1'),
            const IriTerm('http://example.org/ns#age'),
            LiteralTerm('30'),
          ),
        ]);

        final exception = IncompleteDeserializationException(
          remainingGraph: graph,
        );

        final message = exception.toString();
        expect(message, contains('2 unprocessed triples found'));
        expect(message, contains('CompletenessMode.warnOnly'));
        expect(message, contains('registerMapper'));
      });
    });

    group('integration with RDF mapper', () {
      test('should be thrown on incomplete deserialization with strict mode',
          () {
        final rdfMapper = RdfMapper.withMappers((registry) {
          registry.registerMapper(TestPersonMapper());
          // Note: Company mapper is NOT registered
        });

        final turtle = '''
@prefix ex: <http://example.org/ns#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://example.org/person/1> rdf:type ex:Person ;
    ex:name "John Doe" ;
    ex:age 30 .

<http://example.org/company/1> rdf:type ex:Company ;
    ex:name "Acme Corp" ;
    ex:foundedYear 1947 .
''';

        expect(
          () => rdfMapper.decodeObjects<Object>(turtle),
          throwsA(
            allOf(
              isA<IncompleteDeserializationException>(),
              predicate<IncompleteDeserializationException>((e) =>
                  e.remainingTripleCount == 3 && // Company's 3 triples
                  e.unmappedSubjectCount == 1 && // Company subject
                  e.unmappedTypeCount == 1), // Company type
            ),
          ),
        );
      });

      test('should not be thrown with lenient mode', () {
        final rdfMapper = RdfMapper.withMappers((registry) {
          registry.registerMapper(TestPersonMapper());
          // Note: Company mapper is NOT registered
        });

        final turtle = '''
@prefix ex: <http://example.org/ns#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://example.org/person/1> rdf:type ex:Person ;
    ex:name "John Doe" ;
    ex:age 30 .

<http://example.org/company/1> rdf:type ex:Company ;
    ex:name "Acme Corp" ;
    ex:foundedYear 1947 .
''';

        expect(
          () => rdfMapper.decodeObjects<Object>(turtle,
              completenessMode: CompletenessMode.lenient),
          returnsNormally,
        );

        final objects = rdfMapper.decodeObjects<Object>(turtle,
            completenessMode: CompletenessMode.lenient);
        expect(objects, hasLength(1)); // Only Person should be decoded
        expect(objects.first, isA<TestPerson>());
      });

      test('should work with lossless decode', () {
        final rdfMapper = RdfMapper.withMappers((registry) {
          registry.registerMapper(TestPersonMapper());
          // Note: Company mapper is NOT registered
        });

        final turtle = '''
@prefix ex: <http://example.org/ns#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://example.org/person/1> rdf:type ex:Person ;
    ex:name "John Doe" ;
    ex:age 30 .

<http://example.org/company/1> rdf:type ex:Company ;
    ex:name "Acme Corp" ;
    ex:foundedYear 1947 .
''';

        final (objects, remaining) =
            rdfMapper.decodeObjectsLossless<Object>(turtle);

        expect(objects, hasLength(1));
        expect(objects.first, isA<TestPerson>());
        expect(remaining.triples, hasLength(3)); // Company's 3 triples remain
      });
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

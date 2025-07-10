import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/mappers/unmapped/rdf_graph_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('RdfGraphResourceMapper _getSingleRootSubject tests', () {
    late RdfGraphGlobalResourceMapper mapper;

    setUp(() {
      mapper = const RdfGraphGlobalResourceMapper();
    });

    group('Valid single root scenarios', () {
      test('should handle single subject with only literals', () {
        final subject = IriTerm('http://example.org/person1');
        final triples = [
          Triple(
              subject, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(subject, IriTerm('http://example.org/age'), LiteralTerm('30')),
        ];

        final graph = RdfGraph(triples: triples);

        // This should work since there's only one subject and all objects are literals
        expect(() => mapper.toResource(graph, _createSerializationContext()),
            returnsNormally);
      });

      test('should handle hierarchical structure with clear root', () {
        final person = IriTerm('http://example.org/person1');
        final address = BlankNodeTerm();
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(person, IriTerm('http://example.org/address'), address),
          Triple(address, IriTerm('http://example.org/street'),
              LiteralTerm('Main St')),
          Triple(
              address, IriTerm('http://example.org/city'), LiteralTerm('NYC')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(person));
        expect(result.$2, hasLength(4));
      });

      test('should handle complex hierarchy with multiple levels', () {
        final person = IriTerm('http://example.org/person1');
        final address = BlankNodeTerm();
        final country = BlankNodeTerm();
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(person, IriTerm('http://example.org/address'), address),
          Triple(address, IriTerm('http://example.org/street'),
              LiteralTerm('Main St')),
          Triple(address, IriTerm('http://example.org/country'), country),
          Triple(
              country, IriTerm('http://example.org/code'), LiteralTerm('US')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(person));
      });
    });

    group('Invalid multiple root scenarios', () {
      test('should reject graph with multiple unrelated subjects', () {
        final person1 = IriTerm('http://example.org/person1');
        final person2 = IriTerm('http://example.org/person2');
        final triples = [
          Triple(
              person1, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(
              person2, IriTerm('http://example.org/name'), LiteralTerm('Jane')),
        ];

        final graph = RdfGraph(triples: triples);

        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('Multiple toplevel subjects'))));
      });

      test('should reject disconnected components', () {
        final person = IriTerm('http://example.org/person1');
        final company = IriTerm('http://example.org/company1');
        final address = BlankNodeTerm();
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(
              company, IriTerm('http://example.org/name'), LiteralTerm('ACME')),
          Triple(company, IriTerm('http://example.org/address'), address),
          Triple(address, IriTerm('http://example.org/street'),
              LiteralTerm('Business St')),
        ];

        final graph = RdfGraph(triples: triples);

        expect(() => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('Challenging cycle scenarios', () {
      test('should handle legitimate bidirectional references', () {
        final person = IriTerm('http://example.org/person1');
        final company = IriTerm('http://example.org/company1');
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(person, IriTerm('http://example.org/worksAt'), company),
          Triple(
              company, IriTerm('http://example.org/name'), LiteralTerm('ACME')),
          Triple(company, IriTerm('http://example.org/employee'), person),
        ];

        final graph = RdfGraph(triples: triples);

        // Should fail with improved error message for multiple IRI subjects in cycle
        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('Multiple IRI subjects'))));
      });

      test('should handle self-referencing subject', () {
        final person = IriTerm('http://example.org/person1');
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(person, IriTerm('http://example.org/friend'),
              person), // Self-reference
        ];

        final graph = RdfGraph(triples: triples);

        // This should work since person is still the only subject
        // The algorithm correctly identifies a single root subject
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(person));
        expect(result.$2, hasLength(2));
      });

      test('should handle blank node cycles with IRI root', () {
        final person = IriTerm('http://example.org/person1');
        final addr1 = BlankNodeTerm();
        final addr2 = BlankNodeTerm();
        final triples = [
          Triple(
              person, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(person, IriTerm('http://example.org/address'), addr1),
          Triple(addr1, IriTerm('http://example.org/nextAddress'), addr2),
          Triple(addr2, IriTerm('http://example.org/previousAddress'),
              addr1), // Cycle
          Triple(addr1, IriTerm('http://example.org/street'),
              LiteralTerm('Main St')),
          Triple(addr2, IriTerm('http://example.org/street'),
              LiteralTerm('Oak St')),
        ];

        final graph = RdfGraph(triples: triples);

        // This should work - person is clearly the root despite the blank node cycle
        // The algorithm correctly identifies person as the toplevel subject
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(person));
        expect(result.$2, hasLength(6));
      });
    });

    group('Blank node as root scenarios', () {
      test('should handle single blank node as root', () {
        final blank = BlankNodeTerm();
        final triples = [
          Triple(blank, IriTerm('http://example.org/name'),
              LiteralTerm('BlankRoot')),
          Triple(
              blank, IriTerm('http://example.org/type'), LiteralTerm('Test')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(blank));
        expect(result.$2, hasLength(2));
      });

      test('should handle blank node root with IRI objects', () {
        final blank = BlankNodeTerm();
        final iri = IriTerm('http://example.org/person1');
        final triples = [
          Triple(blank, IriTerm('http://example.org/name'),
              LiteralTerm('Container')),
          Triple(blank, IriTerm('http://example.org/contains'), iri),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(blank));
        expect(result.$2, hasLength(2));
      });

      test('should handle blank node root with nested blank nodes', () {
        final rootBlank = BlankNodeTerm();
        final childBlank1 = BlankNodeTerm();
        final childBlank2 = BlankNodeTerm();
        final triples = [
          Triple(rootBlank, IriTerm('http://example.org/name'),
              LiteralTerm('Root')),
          Triple(rootBlank, IriTerm('http://example.org/child1'), childBlank1),
          Triple(rootBlank, IriTerm('http://example.org/child2'), childBlank2),
          Triple(childBlank1, IriTerm('http://example.org/value'),
              LiteralTerm('Child1')),
          Triple(childBlank2, IriTerm('http://example.org/value'),
              LiteralTerm('Child2')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(rootBlank));
        expect(result.$2, hasLength(5));
      });

      test('should prefer IRI over blank node when both are toplevel', () {
        final blank = BlankNodeTerm();
        final iri = IriTerm('http://example.org/person1');
        final triples = [
          Triple(blank, IriTerm('http://example.org/name'),
              LiteralTerm('BlankNode')),
          Triple(
              iri, IriTerm('http://example.org/name'), LiteralTerm('IriNode')),
        ];

        final graph = RdfGraph(triples: triples);

        // Should fail because multiple toplevel subjects exist
        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('Multiple toplevel subjects'))));
      });

      test('should handle blank node as root with complex hierarchy', () {
        final rootBlank = BlankNodeTerm();
        final midBlank = BlankNodeTerm();
        final leafIri = IriTerm('http://example.org/leaf');
        final triples = [
          Triple(rootBlank, IriTerm('http://example.org/name'),
              LiteralTerm('Root')),
          Triple(rootBlank, IriTerm('http://example.org/child'), midBlank),
          Triple(midBlank, IriTerm('http://example.org/name'),
              LiteralTerm('Middle')),
          Triple(midBlank, IriTerm('http://example.org/child'), leafIri),
          Triple(
              leafIri, IriTerm('http://example.org/name'), LiteralTerm('Leaf')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(rootBlank));
        expect(result.$2, hasLength(5));
      });

      test('should handle blank node self-reference', () {
        final blank = BlankNodeTerm();
        final triples = [
          Triple(blank, IriTerm('http://example.org/name'),
              LiteralTerm('SelfRef')),
          Triple(blank, IriTerm('http://example.org/ref'),
              blank), // Self-reference
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(blank));
        expect(result.$2, hasLength(2));
      });

      test('should handle multiple blank nodes where one is clearly root', () {
        final rootBlank = BlankNodeTerm();
        final childBlank1 = BlankNodeTerm();
        final childBlank2 = BlankNodeTerm();
        final grandChildBlank = BlankNodeTerm();
        final triples = [
          Triple(rootBlank, IriTerm('http://example.org/name'),
              LiteralTerm('Root')),
          Triple(rootBlank, IriTerm('http://example.org/child'), childBlank1),
          Triple(rootBlank, IriTerm('http://example.org/child'), childBlank2),
          Triple(childBlank1, IriTerm('http://example.org/name'),
              LiteralTerm('Child1')),
          Triple(childBlank1, IriTerm('http://example.org/grandchild'),
              grandChildBlank),
          Triple(childBlank2, IriTerm('http://example.org/name'),
              LiteralTerm('Child2')),
          Triple(grandChildBlank, IriTerm('http://example.org/name'),
              LiteralTerm('GrandChild')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(rootBlank));
        expect(result.$2, hasLength(7));
      });

      test('should handle blank node with cycle to IRI that references back',
          () {
        final rootBlank = BlankNodeTerm();
        final iri = IriTerm('http://example.org/person1');
        final triples = [
          Triple(rootBlank, IriTerm('http://example.org/name'),
              LiteralTerm('Root')),
          Triple(rootBlank, IriTerm('http://example.org/references'), iri),
          Triple(iri, IriTerm('http://example.org/name'),
              LiteralTerm('Referenced')),
          Triple(iri, IriTerm('http://example.org/backref'),
              rootBlank), // Creates cycle
        ];

        final graph = RdfGraph(triples: triples);

        // Should use IRI as root since it's the only IRI in the cycle
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(iri));
        expect(result.$2, hasLength(4));
      });
    });

    group('Edge cases', () {
      test('should reject empty graph', () {
        final graph = RdfGraph(triples: []);

        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having(
                (e) => e.message, 'message', contains('empty triples'))));
      });

      test('should handle graph with only blank nodes', () {
        final blank1 = BlankNodeTerm();
        final blank2 = BlankNodeTerm();
        final triples = [
          Triple(blank1, IriTerm('http://example.org/name'),
              LiteralTerm('Value1')),
          Triple(blank1, IriTerm('http://example.org/ref'), blank2),
          Triple(blank2, IriTerm('http://example.org/name'),
              LiteralTerm('Value2')),
        ];

        final graph = RdfGraph(triples: triples);

        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(blank1));
      });

      test('should handle mixed IRI and blank node subjects', () {
        final iri = IriTerm('http://example.org/person1');
        final blank = BlankNodeTerm();
        final triples = [
          Triple(iri, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(iri, IriTerm('http://example.org/ref'), blank),
          Triple(
              blank, IriTerm('http://example.org/name'), LiteralTerm('Blank')),
          Triple(blank, IriTerm('http://example.org/backRef'),
              iri), // Creates cycle
        ];

        final graph = RdfGraph(triples: triples);

        // Should identify iri as root despite the cycle using improved heuristics
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(iri));
      });

      test('should handle complex interconnected blank node hierarchy', () {
        final iri = IriTerm('http://example.org/person1');
        final blank1 = BlankNodeTerm();
        final blank2 = BlankNodeTerm();
        final blank3 = BlankNodeTerm();
        final triples = [
          Triple(iri, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(iri, IriTerm('http://example.org/child'), blank1),
          Triple(blank1, IriTerm('http://example.org/sibling'), blank2),
          Triple(blank2, IriTerm('http://example.org/parent'), blank3),
          Triple(blank3, IriTerm('http://example.org/grandparent'),
              iri), // Creates cycle back to IRI
        ];

        final graph = RdfGraph(triples: triples);

        // Should now identify the IRI as root using improved heuristics
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(iri));
      });

      test('should handle all blank node cycle without any IRI', () {
        final blank1 = BlankNodeTerm();
        final blank2 = BlankNodeTerm();
        final blank3 = BlankNodeTerm();
        final triples = [
          Triple(blank1, IriTerm('http://example.org/next'), blank2),
          Triple(blank2, IriTerm('http://example.org/next'), blank3),
          Triple(blank3, IriTerm('http://example.org/next'),
              blank1), // Complete cycle
        ];

        final graph = RdfGraph(triples: triples);

        // Should fail with improved error message for blank node cycles
        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having(
                (e) => e.message, 'message', contains('cyclic blank nodes'))));
      });

      test('should handle subject that is object of a literal predicate', () {
        final subject1 = IriTerm('http://example.org/person1');
        final subject2 = IriTerm('http://example.org/person2');
        final triples = [
          Triple(subject1, IriTerm('http://example.org/name'),
              LiteralTerm('John')),
          Triple(subject2, IriTerm('http://example.org/friend'), subject1),
          Triple(subject2, IriTerm('http://example.org/name'),
              LiteralTerm('Jane')),
        ];

        final graph = RdfGraph(triples: triples);

        // Should identify subject2 as root since subject1 is in objects
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(subject2));
      });

      test('should handle same subject in different contexts', () {
        final subject = IriTerm('http://example.org/person1');
        final object = IriTerm('http://example.org/person2');
        final triples = [
          Triple(
              subject, IriTerm('http://example.org/name'), LiteralTerm('John')),
          Triple(subject, IriTerm('http://example.org/friend'), object),
          Triple(
              object, IriTerm('http://example.org/name'), LiteralTerm('Jane')),
        ];

        final graph = RdfGraph(triples: triples);

        // Should identify subject as root since it's not in objects
        final result = mapper.toResource(graph, _createSerializationContext());
        expect(result.$1, equals(subject));
      });

      test('should reject multiple IRI subjects in cyclic graph', () {
        final iri1 = IriTerm('http://example.org/person1');
        final iri2 = IriTerm('http://example.org/person2');
        final triples = [
          Triple(iri1, IriTerm('http://example.org/friend'), iri2),
          Triple(iri2, IriTerm('http://example.org/friend'), iri1), // Cycle
        ];

        final graph = RdfGraph(triples: triples);

        // Should fail because multiple IRIs exist in cycle
        expect(
            () => mapper.toResource(graph, _createSerializationContext()),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('Multiple IRI subjects'))));
      });
    });

    group('fromResource deserialization tests', () {
      test('should validate subject matches root in deserialization', () {
        final correctSubject = IriTerm('http://example.org/person1');
        final wrongSubject = IriTerm('http://example.org/person2');
        final triples = [
          Triple(correctSubject, IriTerm('http://example.org/name'),
              LiteralTerm('John')),
        ];

        final context = _createDeserializationContext(triples);

        // Should work with correct subject
        final result = mapper.fromResource(correctSubject, context);
        expect(result.triples, hasLength(1));
        expect(result.triples.first.subject, equals(correctSubject));

        // Should fail with wrong subject - context returns empty list for wrong subject
        expect(
            () => mapper.fromResource(wrongSubject, context),
            throwsA(isA<ArgumentError>().having(
                (e) => e.message, 'message', contains('empty triples'))));
      });

      test('should reject subject mismatch when root differs', () {
        final rootSubject = IriTerm('http://example.org/person1');
        final wrongSubject = IriTerm('http://example.org/person2');
        final triples = [
          Triple(rootSubject, IriTerm('http://example.org/name'),
              LiteralTerm('John')),
          Triple(wrongSubject, IriTerm('http://example.org/name'),
              LiteralTerm('Jane')),
        ];

        // Create context that returns both triples for rootSubject
        final context = _createDeserializationContextWithAllTriples(triples);

        // Should fail because there are multiple toplevel subjects
        expect(
            () => mapper.fromResource(wrongSubject, context),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('Multiple toplevel subjects'))));
      });
    });
  });
}

// Helper function to create a mock SerializationContext
SerializationContext _createSerializationContext() {
  final registry = RdfMapperRegistry();
  return SerializationContextImpl(registry);
}

// Helper function to create a mock DeserializationContext
DeserializationContext _createDeserializationContext(List<Triple> triples) {
  final registry = RdfMapperRegistry();
  final graph = RdfGraph(triples: triples);
  return DeserializationContextImpl(graph, registry);
}

// Helper function to create a mock DeserializationContext that returns all triples for any subject
DeserializationContext _createDeserializationContextWithAllTriples(
    List<Triple> triples) {
  final registry = RdfMapperRegistry();
  final graph = RdfGraph(triples: triples);
  return DeserializationContextAllTriplesImpl(graph, registry);
}

// Mock implementations for testing
class SerializationContextImpl extends SerializationContext {
  final RdfMapperRegistry registry;

  SerializationContextImpl(this.registry);

  @override
  List<Triple> resource<T>(T value, {ResourceSerializer<T>? serializer}) {
    throw UnimplementedError();
  }

  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    throw UnimplementedError();
  }

  @override
  LiteralTerm toLiteralTerm<T>(T value,
      {LiteralTermSerializer<T>? serializer}) {
    throw UnimplementedError();
  }
}

class DeserializationContextImpl extends DeserializationContext {
  final RdfGraph graph;
  final RdfMapperRegistry registry;

  DeserializationContextImpl(this.graph, this.registry);

  @override
  T fromLiteralTerm<T>(LiteralTerm term,
      {LiteralTermDeserializer<T>? deserializer,
      bool bypassDatatypeCheck = false}) {
    throw UnimplementedError();
  }

  @override
  List<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true}) {
    return graph.triples.where((t) => t.subject == subject).toList();
  }

  @override
  ResourceReader reader(RdfSubject subject) {
    throw UnimplementedError();
  }
}

class DeserializationContextAllTriplesImpl extends DeserializationContext {
  final RdfGraph graph;
  final RdfMapperRegistry registry;

  DeserializationContextAllTriplesImpl(this.graph, this.registry);

  @override
  T fromLiteralTerm<T>(LiteralTerm term,
      {LiteralTermDeserializer<T>? deserializer,
      bool bypassDatatypeCheck = false}) {
    throw UnimplementedError();
  }

  @override
  List<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true}) {
    // Return all triples to simulate the scenario where we get all triples for root detection
    return graph.triples.toList();
  }

  @override
  ResourceReader reader(RdfSubject subject) {
    throw UnimplementedError();
  }
}

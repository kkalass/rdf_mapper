import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('CompletenessMode', () {
    late RdfMapperRegistry registry;
    late RdfMapperService service;

    setUp(() {
      registry = RdfMapperRegistry();
      service = RdfMapperService(registry: registry);
    });

    test('strict mode throws exception when triples remain', () {
      // Create a graph with triples that can't be deserialized
      final graph = RdfGraph(triples: [
        Triple(
          IriTerm('http://example.org/person/1'),
          Rdf.type,
          IriTerm('http://xmlns.com/foaf/0.1/Person'),
        ),
        Triple(
          IriTerm('http://example.org/person/1'),
          IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('John Doe'),
        ),
      ]);

      // No mappers registered, so this should throw with strict mode
      expect(
        () => service.deserializeAll(graph,
            completeness: CompletenessMode.strict),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });

    test('lenient mode ignores remaining triples', () {
      // Create a graph with triples that can't be deserialized
      final graph = RdfGraph(triples: [
        Triple(
          IriTerm('http://example.org/person/1'),
          Rdf.type,
          IriTerm('http://xmlns.com/foaf/0.1/Person'),
        ),
        Triple(
          IriTerm('http://example.org/person/1'),
          IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('John Doe'),
        ),
      ]);

      // No mappers registered, but lenient mode should not throw
      final result =
          service.deserializeAll(graph, completeness: CompletenessMode.lenient);
      expect(result, isEmpty);
    });

    test('strict mode is the default', () {
      final graph = RdfGraph(triples: [
        Triple(
          IriTerm('http://example.org/person/1'),
          Rdf.type,
          IriTerm('http://xmlns.com/foaf/0.1/Person'),
        ),
      ]);

      // Should throw with default strict mode
      expect(
        () => service.deserializeAll(graph),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });

    test('IncompleteDeserializationException contains detailed information',
        () {
      final graph = RdfGraph(triples: [
        Triple(
          IriTerm('http://example.org/person/1'),
          Rdf.type,
          IriTerm('http://xmlns.com/foaf/0.1/Person'),
        ),
        Triple(
          IriTerm('http://example.org/person/1'),
          IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('John Doe'),
        ),
      ]);

      try {
        service.deserializeAll(graph, completeness: CompletenessMode.strict);
        fail('Expected IncompleteDeserializationException');
      } on IncompleteDeserializationException catch (e) {
        expect(e.hasRemainingTriples, isTrue);
        expect(e.remainingTripleCount, equals(2));
        expect(e.unmappedSubjects,
            contains(IriTerm('http://example.org/person/1')));
        expect(e.unmappedTypes,
            contains(IriTerm('http://xmlns.com/foaf/0.1/Person')));
      }
    });
  });
}

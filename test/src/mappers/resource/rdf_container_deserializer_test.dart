import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_container_deserializer.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

/// Custom deserializer for testing purposes
class UpperCaseStringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm datatype;

  UpperCaseStringDeserializer([this.datatype = Xsd.string]);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toUpperCase();
  }
}

/// Test class for resource deserialization
class TestPerson {
  final String iri;

  TestPerson(this.iri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          iri == other.iri;

  @override
  int get hashCode => iri.hashCode;

  @override
  String toString() => 'TestPerson($iri)';
}

class TestPersonDeserializer implements GlobalResourceDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://test.org/Person');

  @override
  TestPerson fromRdfResource(IriTerm term, DeserializationContext context) {
    return TestPerson(term.value);
  }
}

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
  });

  /// Helper to create RDF numbered property IRIs (rdf:_1, rdf:_2, etc.)
  IriTerm rdfLi(int number) =>
      IriTerm.validated('http://www.w3.org/1999/02/22-rdf-syntax-ns#_$number');

  group('RDF Container Deserializers', () {
    group('RdfSeqDeserializer', () {
      test('deserializes ordered sequence', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('Chapter 1')),
          Triple(container, rdfLi(2), LiteralTerm.string('Chapter 2')),
          Triple(container, rdfLi(3), LiteralTerm.string('Chapter 3')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['Chapter 1', 'Chapter 2', 'Chapter 3']));
      });

      test('preserves order even when properties are out of sequence', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(3), LiteralTerm.string('Third')),
          Triple(container, rdfLi(1), LiteralTerm.string('First')),
          Triple(container, rdfLi(5), LiteralTerm.string('Fifth')),
          Triple(container, rdfLi(2), LiteralTerm.string('Second')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['First', 'Second', 'Third', 'Fifth']));
      });

      test('deserializes with custom item deserializer', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('hello')),
          Triple(container, rdfLi(2), LiteralTerm.string('world')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>(
            itemDeserializer: UpperCaseStringDeserializer());
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['HELLO', 'WORLD']));
      });

      test('deserializes resource items', () {
        final container = BlankNodeTerm();
        final person1 = const IriTerm('http://test.org/person1');
        final person2 = const IriTerm('http://test.org/person2');

        registry.registerDeserializer(TestPersonDeserializer());

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), person1),
          Triple(container, rdfLi(2), person2),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<TestPerson>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result.length, equals(2));
        expect(result[0], equals(TestPerson('http://test.org/person1')));
        expect(result[1], equals(TestPerson('http://test.org/person2')));
      });

      test('handles gaps in numbered properties', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('First')),
          Triple(container, rdfLi(3), LiteralTerm.string('Third')),
          Triple(container, rdfLi(5), LiteralTerm.string('Fifth')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['First', 'Third', 'Fifth']));
      });

      test('returns empty list for container with no numbered properties', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, isEmpty);
      });

      test('throws ArgumentError when container type is wrong', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Bag), // Wrong type - should be Seq
          Triple(container, rdfLi(1), LiteralTerm.string('Item')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();

        expect(
          () => deserializer.fromRdfResource(container, context),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when no type is declared', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, rdfLi(1), LiteralTerm.string('Item')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();

        expect(
          () => deserializer.fromRdfResource(container, context),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('RdfBagDeserializer', () {
      test('deserializes unordered bag', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(1), LiteralTerm.string('Apple')),
          Triple(container, rdfLi(2), LiteralTerm.string('Banana')),
          Triple(container, rdfLi(3), LiteralTerm.string('Cherry')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfBagDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result.length, equals(3));
        expect(result, containsAll(['Apple', 'Banana', 'Cherry']));
      });

      test('preserves numerical order despite being unordered semantically',
          () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(3), LiteralTerm.string('Third')),
          Triple(container, rdfLi(1), LiteralTerm.string('First')),
          Triple(container, rdfLi(2), LiteralTerm.string('Second')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfBagDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        // Even though it's a bag (unordered), we preserve numerical order for consistency
        expect(result, equals(['First', 'Second', 'Third']));
      });

      test('allows duplicate values', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Bag),
          Triple(container, rdfLi(1), LiteralTerm.string('Apple')),
          Triple(container, rdfLi(2), LiteralTerm.string('Apple')),
          Triple(container, rdfLi(3), LiteralTerm.string('Banana')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfBagDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['Apple', 'Apple', 'Banana']));
      });

      test('throws ArgumentError when container type is wrong', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Alt), // Wrong type - should be Bag
          Triple(container, rdfLi(1), LiteralTerm.string('Item')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfBagDeserializer<String>();

        expect(
          () => deserializer.fromRdfResource(container, context),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('RdfAltDeserializer', () {
      test('deserializes alternative values', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(1), LiteralTerm.string('Primary choice')),
          Triple(container, rdfLi(2), LiteralTerm.string('Secondary choice')),
          Triple(container, rdfLi(3), LiteralTerm.string('Fallback choice')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfAltDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result,
            equals(['Primary choice', 'Secondary choice', 'Fallback choice']));
      });

      test('preserves preference order', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(3), LiteralTerm.string('Lowest preference')),
          Triple(container, rdfLi(1), LiteralTerm.string('Highest preference')),
          Triple(container, rdfLi(2), LiteralTerm.string('Medium preference')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfAltDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(
            result,
            equals([
              'Highest preference',
              'Medium preference',
              'Lowest preference'
            ]));
      });

      test('handles single alternative', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Alt),
          Triple(container, rdfLi(1), LiteralTerm.string('Only choice')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfAltDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        expect(result, equals(['Only choice']));
      });

      test('throws ArgumentError when container type is wrong', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq), // Wrong type - should be Alt
          Triple(container, rdfLi(1), LiteralTerm.string('Item')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfAltDeserializer<String>();

        expect(
          () => deserializer.fromRdfResource(container, context),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles invalid numbered properties (non-numeric)', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('Valid')),
          Triple(
              container,
              const IriTerm(
                  'http://www.w3.org/1999/02/22-rdf-syntax-ns#_invalid'),
              LiteralTerm.string('Invalid')),
          Triple(container, rdfLi(2), LiteralTerm.string('Also valid')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        // Should ignore invalid property and only process valid ones
        expect(result, equals(['Valid', 'Also valid']));
      });

      test('handles zero-indexed properties (should be ignored)', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(
              container,
              const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#_0'),
              LiteralTerm.string('Zero index')),
          Triple(container, rdfLi(1), LiteralTerm.string('First')),
          Triple(container, rdfLi(2), LiteralTerm.string('Second')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        // Should ignore zero-indexed property as RDF containers use 1-based indexing
        expect(result, equals(['First', 'Second']));
      });

      test('handles negative numbered properties (should be ignored)', () {
        final container = BlankNodeTerm();

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(
              container,
              const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#_-1'),
              LiteralTerm.string('Negative')),
          Triple(container, rdfLi(1), LiteralTerm.string('Positive')),
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();
        final result = deserializer.fromRdfResource(container, context);

        // Should ignore negative property
        expect(result, equals(['Positive']));
      });

      test('handles deserialization errors for individual items', () {
        final container = BlankNodeTerm();
        final invalidIri = const IriTerm('http://test.org/invalid');

        graph = RdfGraph(triples: [
          Triple(container, Rdf.type, Rdf.Seq),
          Triple(container, rdfLi(1), LiteralTerm.string('Valid item')),
          Triple(container, rdfLi(2),
              invalidIri), // This will fail to deserialize to String
        ]);
        context = DeserializationContextImpl(graph: graph, registry: registry);

        final deserializer = RdfSeqDeserializer<String>();

        expect(
          () => deserializer.fromRdfResource(container, context).toList(),
          throwsA(isA<DeserializerNotFoundException>()),
        );
      });
    });
  });
}

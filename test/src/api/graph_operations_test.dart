import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/graph_operations.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_service.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_vocabularies/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('GraphOperations', () {
    late RdfMapperRegistry registry;
    late GraphOperations operations;

    setUp(() {
      registry = RdfMapperRegistry();
      operations = GraphOperations(RdfMapperService(registry: registry));
    });

    test(
      'should serialize with runtime type when generic parameter is dynamic',
      () {
        // Register serializer for TestItem
        registry.registerSerializer<TestItem>(TestItemSerializer());

        // Create a test item
        final testItem = TestItem('test-id', 'Test Name');

        // Serialize in a way that makes the instance dynamic
        final Iterable items = [testItem];
        final instance = items.first; // This will be dynamic at runtime

        // This simulates what happens in GraphOperations.serialize when iterating
        // through instances of dynamic type
        final graph = operations.serialize(instance);

        // Verify that the serialization worked correctly
        expect(graph.triples.length, equals(2)); // Name triple + type triple

        // Check for specific expected triples
        final typeTriple = graph.triples.firstWhere(
          (t) => t.predicate == Rdf.type,
        );
        expect(
          typeTriple.subject,
          equals(IriTerm('http://example.org/item/test-id')),
        );
        expect(typeTriple.object, equals(TestItemSerializer().typeIri));

        final nameTriple = graph.triples.firstWhere(
          (t) => t.predicate == IriTerm('http://example.org/name'),
        );
        expect(
          nameTriple.subject,
          equals(IriTerm('http://example.org/item/test-id')),
        );
        expect(nameTriple.object, equals(LiteralTerm.string('Test Name')));
      },
    );
  });
}

// Test model
class TestItem {
  final String id;
  final String name;

  TestItem(this.id, this.name);
}

// Test serializer
class TestItemSerializer implements IriNodeSerializer<TestItem> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/TestItem');

  @override
  (IriTerm, List<Triple>) toRdfNode(
    TestItem value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm('http://example.org/item/${value.id}');
    final triples = <Triple>[
      Triple(
        subject,
        IriTerm('http://example.org/name'),
        LiteralTerm.string(value.name),
      ),
    ];
    return (subject, triples);
  }
}

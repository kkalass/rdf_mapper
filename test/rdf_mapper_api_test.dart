import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:test/test.dart';

void main() {
  group('API Structure Tests', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = RdfMapper.withDefaultRegistry();
    });

    test('should access graph operations via graph property', () {
      expect(rdfMapper.graph, isA<GraphOperations>());
    });

    test('should provide access to the registry', () {
      expect(rdfMapper.registry, isA<RdfMapperRegistry>());
    });

    test('should expose string-based operations at top level', () {
      // These methods should exist on the RdfMapper instance
      expect(rdfMapper.deserialize, isA<Function>);
      expect(rdfMapper.deserializeBySubject, isA<Function>);
      expect(rdfMapper.deserializeAll, isA<Function>);
      expect(rdfMapper.deserializeAllOfType, isA<Function>);
      expect(rdfMapper.serialize, isA<Function>);
      expect(rdfMapper.serializeList, isA<Function>);
    });

    test('should expose graph-based operations under graph property', () {
      // These methods should exist on the graph property
      expect(rdfMapper.graph.deserialize, isA<Function>);
      expect(rdfMapper.graph.deserializeBySubject, isA<Function>);
      expect(rdfMapper.graph.deserializeAll, isA<Function>);
      expect(rdfMapper.graph.deserializeAllOfType, isA<Function>);
      expect(rdfMapper.graph.serialize, isA<Function>);
      expect(rdfMapper.graph.serializeList, isA<Function>);
    });
  });

  group('API Integration Tests', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = RdfMapper.withDefaultRegistry();
      rdfMapper.registerMapper(TestEntityMapper());
    });

    test('should serialize and deserialize via string operations', () {
      final entity = TestEntity(
        id: 'http://example.org/entity/1',
        name: 'Test Entity',
        value: 42,
      );

      // String operations
      final turtle = rdfMapper.serialize(entity);
      expect(turtle, contains('http://example.org/entity/1'));
      expect(turtle, contains('Test Entity'));

      final deserialized = rdfMapper.deserialize<TestEntity>(turtle);
      expect(deserialized.id, equals(entity.id));
      expect(deserialized.name, equals(entity.name));
      expect(deserialized.value, equals(entity.value));
    });

    test('should serialize and deserialize via graph operations', () {
      final entity = TestEntity(
        id: 'http://example.org/entity/1',
        name: 'Test Entity',
        value: 42,
      );

      // Graph operations
      final graph = rdfMapper.graph.serialize(entity);
      expect(graph.size, greaterThan(0));

      final deserialized = rdfMapper.graph.deserialize<TestEntity>(graph);
      expect(deserialized.id, equals(entity.id));
      expect(deserialized.name, equals(entity.name));
      expect(deserialized.value, equals(entity.value));
    });

    test('should serialize and deserialize multiple entities', () {
      final entities = [
        TestEntity(
          id: 'http://example.org/entity/1',
          name: 'Entity 1',
          value: 42,
        ),
        TestEntity(
          id: 'http://example.org/entity/2',
          name: 'Entity 2',
          value: 84,
        ),
      ];

      // String operations with list
      final turtle = rdfMapper.serializeList(entities);
      expect(turtle, contains('http://example.org/entity/1'));
      expect(turtle, contains('http://example.org/entity/2'));

      final deserialized = rdfMapper.deserializeAllOfType<TestEntity>(turtle);
      expect(deserialized.length, equals(2));
      expect(deserialized[0].name, equals('Entity 1'));
      expect(deserialized[1].name, equals('Entity 2'));

      // Graph operations with list
      final graph = rdfMapper.graph.serializeList(entities);
      final deserializedFromGraph = rdfMapper.graph
          .deserializeAllOfType<TestEntity>(graph);
      expect(deserializedFromGraph.length, equals(2));
    });
  });
}

// Test domain model

class TestEntity {
  final String id;
  final String name;
  final int value;

  TestEntity({required this.id, required this.name, required this.value});
}

class TestEntityMapper implements SubjectMapper<TestEntity> {
  static final namePredicate = IriTerm('http://schema.org/name');
  static final valuePredicate = IriTerm('http://schema.org/value');

  @override
  final IriTerm typeIri = IriTerm('http://schema.org/TestEntity');

  @override
  TestEntity fromRdfTerm(IriTerm subject, DeserializationContext context) {
    return TestEntity(
      id: subject.iri,
      name: context.require<String>(subject, namePredicate),
      value: context.require<int>(subject, valuePredicate),
    );
  }

  @override
  (RdfSubject, List<Triple>) toRdfSubject(
    TestEntity entity,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm(entity.id);
    final triples = <Triple>[
      context.literal(subject, namePredicate, entity.name),
      context.literal<int>(subject, valuePredicate, entity.value),
    ];
    return (subject, triples);
  }
}

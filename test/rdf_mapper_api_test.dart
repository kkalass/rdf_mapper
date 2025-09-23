import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
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
      // These methods should exist and be callable on the RdfMapper instance
      // ignore: unnecessary_type_check
      expect(rdfMapper.decodeObject is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.decodeObjects is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.encodeObject is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.encodeObjects is Function, isTrue);

      // Additional verification that methods can be called without errors
      expect(() => rdfMapper.decodeObjects.runtimeType, returnsNormally);
    });

    test('should expose graph-based operations under graph property', () {
      // These methods should exist and be callable on the graph property
      // ignore: unnecessary_type_check
      expect(rdfMapper.graph.decodeObject is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.graph.decodeObjects is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.graph.encodeObject is Function, isTrue);
      // ignore: unnecessary_type_check
      expect(rdfMapper.graph.encodeObjects is Function, isTrue);

      // Additional verification that methods can be called without errors
      expect(() => rdfMapper.graph.decodeObjects.runtimeType, returnsNormally);
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
      final turtle = rdfMapper.encodeObject(entity);
      expect(turtle, contains('http://example.org/entity/1'));
      expect(turtle, contains('Test Entity'));

      final deserialized = rdfMapper.decodeObject<TestEntity>(turtle);
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
      final graph = rdfMapper.graph.encodeObject(entity);
      expect(graph.size, greaterThan(0));

      final deserialized = rdfMapper.graph.decodeObject<TestEntity>(graph);
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
      final turtle = rdfMapper.encodeObjects(entities);
      expect(turtle, contains('http://example.org/entity/1'));
      expect(turtle, contains('http://example.org/entity/2'));

      final deserialized = rdfMapper.decodeObjects<TestEntity>(turtle);
      expect(deserialized.length, equals(2));
      expect(deserialized[0].name, equals('Entity 1'));
      expect(deserialized[1].name, equals('Entity 2'));

      // Graph operations with list
      final graph = rdfMapper.graph.encodeObjects(entities);
      final deserializedFromGraph = rdfMapper.graph.decodeObjects<TestEntity>(
        graph,
      );
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

class TestEntityMapper implements GlobalResourceMapper<TestEntity> {
  static final namePredicate = const IriTerm('http://schema.org/name');
  static final valuePredicate = const IriTerm('http://schema.org/value');

  @override
  final IriTerm typeIri = const IriTerm('http://schema.org/TestEntity');

  @override
  TestEntity fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestEntity(
      id: subject.value,
      name: reader.require<String>(namePredicate),
      value: reader.require<int>(valuePredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestEntity entity,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(entity.id))
        .addValue(namePredicate, entity.name)
        .addValue(valuePredicate, entity.value)
        .build();
  }
}

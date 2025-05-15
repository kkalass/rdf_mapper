import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

/// Class A (Parent) contains references to class B (Child)
class ParentClass {
  final String id;
  final String name;
  final ChildClass child;

  ParentClass({required this.id, required this.name, required this.child});

  @override
  String toString() => 'ParentClass($id, $name, $child)';
}

/// Class B (Child) depends on context from Class A
class ChildClass {
  final String id;
  final String value;
  final String parentId; // Depends on parent context

  ChildClass({required this.id, required this.value, required this.parentId});

  @override
  String toString() => 'ChildClass($id, $value, parentId: $parentId)';
}

/// Mapper for ParentClass which dynamically provides a mapper for ChildClass
class ParentClassMapper implements IriNodeMapper<ParentClass> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/ParentClass');

  static final namePredicate = IriTerm('http://example.org/name');
  static final childPredicate = IriTerm('http://example.org/child');

  @override
  ParentClass fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name = reader.require<String>(namePredicate);

    final child = reader.require<ChildClass>(
      childPredicate,
      // Dynamically register a mapper for ChildClass that needs parent context
      // This simulates a scenario where the child mapper needs properties from the parent
      iriNodeDeserializer: ChildClassMapper(parentId: subject.iri),
    );

    return ParentClass(id: subject.iri, name: name, child: child);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    ParentClass value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(value.id))
        .literal(namePredicate, value.name)
        .childNode(
          childPredicate,
          value.child,
          // Dynamically register the child mapper for serialization
          serializer: ChildClassMapper(parentId: value.id),
        )
        .build();
  }
}

/// Mapper for ChildClass that requires context from parent
class ChildClassMapper implements IriNodeMapper<ChildClass> {
  final String parentId;

  ChildClassMapper({required this.parentId});

  @override
  final IriTerm typeIri = IriTerm('http://example.org/ChildClass');

  static final valuePredicate = IriTerm('http://example.org/value');
  static final parentIdPredicate = IriTerm('http://example.org/parentId');

  @override
  ChildClass fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final value = reader.require<String>(valuePredicate);

    // Use the parentId that was passed to the mapper constructor
    // This is why we need a dynamically created mapper

    return ChildClass(id: subject.iri, value: value, parentId: parentId);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    ChildClass value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(value.id))
        .literal(valuePredicate, value.value)
        .literal(parentIdPredicate, value.parentId)
        .build();
  }
}

void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    rdfMapper = RdfMapper.withDefaultRegistry();
    // Only register the parent mapper globally
    rdfMapper.registerMapper<ParentClass>(ParentClassMapper());
    // Note: We intentionally DON'T register the ChildClassMapper globally
  });

  group('Dynamic mapper tests', () {
    test('serialization works with dynamically provided mapper', () {
      // Create test objects
      final child = ChildClass(
        id: 'http://example.org/child/1',
        value: 'Child Value',
        parentId: 'http://example.org/parent/1',
      );

      final parent = ParentClass(
        id: 'http://example.org/parent/1',
        name: 'Parent Name',
        child: child,
      );

      // Serialization should work fine
      final graph = rdfMapper.graph.encodeObject(parent);
      expect(graph.triples.length, greaterThan(0));

      // Verify that the child was properly serialized
      final childTriples = graph.findTriples(
        subject: IriTerm('http://example.org/child/1'),
      );
      expect(childTriples.length, greaterThan(0));
    });

    test('deserialize works with dynamically provided mapper', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/parent/1> a ex:ParentClass ;
        ex:name "Parent Name" ;
        ex:child <http://example.org/child/1> .
        
      <http://example.org/child/1> a ex:ChildClass ;
        ex:value "Child Value" ;
        ex:parentId "http://example.org/parent/1" .
      ''';

      // Single object deserialization works fine
      final parent = rdfMapper.decodeObject<ParentClass>(turtle);
      expect(parent.name, equals('Parent Name'));
      expect(parent.child.value, equals('Child Value'));
    });

    test('deserializeAll fails with dynamically provided mapper', () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/parent/1> a ex:ParentClass ;
        ex:name "Parent Name" ;
        ex:child <http://example.org/child/1> .
        
      <http://example.org/child/1> a ex:ChildClass ;
        ex:value "Child Value" ;
        ex:parentId "http://example.org/parent/1" .
      ''';

      // This will fail because deserializeAll tries to deserialize all subjects,
      // including the child, but no ChildClassMapper is globally registered
      final result = rdfMapper.decodeObjects(turtle);
      expect(
        result.length,
        equals(1),
      ); // Only ParentClass should be deserialized
      expect(result[0], isA<ParentClass>());
      final parent = result[0] as ParentClass;
      expect(parent.name, equals('Parent Name'));
      expect(parent.child, isNotNull); // Child should be deserialized
      expect(parent.child.value, equals('Child Value'));
      expect(parent.child.parentId, equals('http://example.org/parent/1'));
    });
  });
}

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
class ParentClassMapper implements GlobalResourceMapper<ParentClass> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/ParentClass');

  static final namePredicate = const IriTerm('http://example.org/name');
  static final childPredicate = const IriTerm('http://example.org/child');

  @override
  ParentClass fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name = reader.require<String>(namePredicate);

    final child = reader.require<ChildClass>(
      childPredicate,
      // Dynamically register a mapper for ChildClass that needs parent context
      // This simulates a scenario where the child mapper needs properties from the parent
      deserializer: ChildClassMapper(parentId: subject.value),
    );

    return ParentClass(id: subject.value, name: name, child: child);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    ParentClass value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(namePredicate, value.name)
        .addValue(
          childPredicate,
          value.child,
          // Dynamically register the child mapper for serialization
          serializer: ChildClassMapper(parentId: value.id),
        )
        .build();
  }
}

/// Mapper for ChildClass that requires context from parent
class ChildClassMapper implements GlobalResourceMapper<ChildClass> {
  final String parentId;

  ChildClassMapper({required this.parentId});

  @override
  final IriTerm typeIri = const IriTerm('http://example.org/ChildClass');

  static final valuePredicate = const IriTerm('http://example.org/value');
  static final parentIdPredicate = const IriTerm('http://example.org/parentId');

  @override
  ChildClass fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final value = reader.require<String>(valuePredicate);

    // Use the parentId that was passed to the mapper constructor

    return ChildClass(id: subject.value, value: value, parentId: parentId);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    ChildClass value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(valuePredicate, value.value)
        .addValue(parentIdPredicate, value.parentId)
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
        subject: const IriTerm('http://example.org/child/1'),
      );
      expect(childTriples.length, greaterThan(0));
    });

    test(
        'deserialize works with dynamically provided mapper (fails due to strict mode)',
        () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/parent/1> a ex:ParentClass ;
        ex:name "Parent Name" ;
        ex:child <http://example.org/child/1> .
        
      <http://example.org/child/1> a ex:ChildClass ;
        ex:value "Child Value" ;
        ex:parentId "http://example.org/parent/1" .
      ''';

      // Should fail in strict mode due to incomplete deserialization
      expect(
        () => rdfMapper.decodeObject<ParentClass>(turtle,
            completeness: CompletenessMode.strict),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });

    test(
        'deserialize works with dynamically provided mapper (passes in lenient mode)',
        () {
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
      final parent = rdfMapper.decodeObject<ParentClass>(turtle,
          completeness: CompletenessMode.lenient);
      expect(parent.name, equals('Parent Name'));
      expect(parent.child.value, equals('Child Value'));
    });

    test(
        'deserialize works with dynamically provided mapper (works with lossless)',
        () {
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
      final (parent, remainder) =
          rdfMapper.decodeObjectLossless<ParentClass>(turtle);
      expect(parent.name, equals('Parent Name'));
      expect(parent.child.value, equals('Child Value'));
      expect(remainder.triples.isEmpty, isFalse);
      expect(remainder.triples.length, 1);
      expect(remainder.triples[0].subject,
          const IriTerm('http://example.org/child/1'));
      expect(remainder.triples[0].predicate,
          const IriTerm('http://example.org/parentId'));
      expect(remainder.triples[0].object,
          LiteralTerm('http://example.org/parent/1'));
    });
    test(
        'decodeObjects also works with dynamically registered mapper - in lenient mode',
        () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/parent/1> a ex:ParentClass ;
        ex:name "Parent Name" ;
        ex:child <http://example.org/child/1> .
        
      <http://example.org/child/1> a ex:ChildClass ;
        ex:value "Child Value" ;
        ex:parentId "http://example.org/parent/1" .
      ''';

      final result = rdfMapper.decodeObjects(turtle,
          completenessMode: CompletenessMode.lenient);
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

    test(
        'decodeObjects throws IncompleteDeserializationException with dynamically registered mapper in strict mode, because it serializes a property that it does not read back (parentId).',
        () {
      final turtle = '''
      @prefix ex: <http://example.org/> .
      
      <http://example.org/parent/1> a ex:ParentClass ;
        ex:name "Parent Name" ;
        ex:child <http://example.org/child/1> .
        
      <http://example.org/child/1> a ex:ChildClass ;
        ex:value "Child Value" ;
        ex:parentId "http://example.org/parent/1" .
      ''';

      expect(
        () => rdfMapper.decodeObjects(turtle,
            completenessMode: CompletenessMode.strict),
        throwsA(isA<IncompleteDeserializationException>()),
      );
    });
  });
}

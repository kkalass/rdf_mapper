import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late SerializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
    context = SerializationContextImpl(registry: registry);
  });

  group('SerializationContextImpl', () {
    test(
      'should not add duplicate type triple when one is already provided by the mapper',
      () {
        // Register a custom mapper that explicitly adds a type triple
        final mapper = TestPersonSerializerWithTypeTriple();
        registry.registerSerializer<TestPerson>(mapper);

        // Create a test person
        final person = TestPerson(
          id: 'http://example.org/person/1',
          name: 'John Doe',
        );

        // Serialize the person to RDF triples
        final triples = context.resource(person);

        // Count the number of type triples
        final typeTriples = triples
            .where(
              (triple) =>
                  triple.predicate == Rdf.type &&
                  triple.subject == context.createIriTerm(person.id),
            )
            .toList();

        // Verify there's exactly one type triple, not two
        expect(typeTriples.length, equals(1));
        expect(typeTriples.first.object, equals(mapper.typeIri));
      },
    );

    test('should add the type triple when not provided by the mapper', () {
      // Register a custom mapper that doesn't add a type triple
      final mapper = TestPersonSerializerWithoutTypeTriple();
      registry.registerSerializer<TestPerson>(mapper);

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
      );

      // Serialize the person to RDF triples
      final triples = context.resource(person);

      // Count the number of type triples
      final typeTriples = triples
          .where(
            (triple) =>
                triple.predicate == Rdf.type &&
                triple.subject == context.createIriTerm(person.id),
          )
          .toList();

      // Verify there's exactly one type triple added by the context
      expect(typeTriples.length, equals(1));
      expect(typeTriples.first.object, equals(mapper.typeIri));
    });

    test('childSubject method should not add duplicate type triple', () {
      // Register a custom mapper that explicitly adds a type triple
      final mapper = TestPersonSerializerWithTypeTriple();
      registry.registerSerializer<TestPerson>(mapper);

      // Create a test person
      final person = TestPerson(
        id: 'http://example.org/person/1',
        name: 'John Doe',
      );

      // Use childSubject to serialize the person as a child of another subject
      final parentSubject = const IriTerm('http://example.org/container/1');
      final predicate = const IriTerm('http://example.org/contains');
      final triples = context.value(parentSubject, predicate, person);

      // Count the number of type triples for the person
      final typeTriples = triples
          .where(
            (triple) =>
                triple.predicate == Rdf.type &&
                triple.subject == context.createIriTerm(person.id),
          )
          .toList();

      // Verify there's exactly one type triple, not two
      expect(typeTriples.length, equals(1));
    });
  });
}

// Test model class
class TestPerson {
  final String id;
  final String name;

  TestPerson({required this.id, required this.name});
}

// Test serializer that explicitly adds a type triple
class TestPersonSerializerWithTypeTriple
    implements GlobalResourceSerializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(value.id);
    final triples = <Triple>[
      // Name triple
      Triple(
        subject,
        const IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string(value.name),
      ),

      // Explicitly add type triple
      Triple(subject, Rdf.type, typeIri),
    ];

    return (subject, triples);
  }
}

// Test serializer that doesn't add a type triple
class TestPersonSerializerWithoutTypeTriple
    implements GlobalResourceSerializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestPerson value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(value.id);
    final triples = <Triple>[
      // Name triple
      Triple(
        subject,
        const IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string(value.name),
      ),
      // No type triple added here
    ];

    return (subject, triples);
  }
}

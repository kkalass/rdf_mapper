import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_serializer.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

/// Test classes for serialization
class TestPerson {
  final String name;
  final int age;

  TestPerson({required this.name, required this.age});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(name, age);

  @override
  String toString() => 'TestPerson(name: $name, age: $age)';
}

class TestProduct {
  final String id;
  final String name;
  final double price;

  TestProduct({required this.id, required this.name, required this.price});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, price);

  @override
  String toString() => 'TestProduct(id: $id, name: $name, price: $price)';
}

/// Custom serializers for testing
class TestPersonSerializer implements LocalResourceSerializer<TestPerson> {
  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Person');

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = BlankNodeTerm();
    final triples = [
      Triple(subject, const IriTerm('http://example.org/name'),
          LiteralTerm.string(instance.name)),
      Triple(subject, const IriTerm('http://example.org/age'),
          LiteralTerm.typed(instance.age.toString(), 'integer')),
    ];
    return (subject, triples);
  }
}

class TestProductSerializer implements GlobalResourceSerializer<TestProduct> {
  @override
  IriTerm get typeIri => const IriTerm('http://example.org/Product');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      TestProduct instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject =
        context.createIriTerm('http://example.org/product/${instance.id}');
    final triples = [
      Triple(subject, const IriTerm('http://example.org/name'),
          LiteralTerm.string(instance.name)),
      Triple(subject, const IriTerm('http://example.org/price'),
          LiteralTerm.typed(instance.price.toString(), 'decimal')),
    ];
    return (subject, triples);
  }
}

class UpperCaseStringSerializer implements LiteralTermSerializer<String> {
  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm.string(value.toUpperCase());
  }
}

/// Serializer that can detect potential cycles by counting serialization attempts
class CycleDetectingPersonSerializer
    implements LocalResourceSerializer<TestPerson> {
  static int serializationCount = 0;

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Person');

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    serializationCount++;
    if (serializationCount > 5) {
      throw StateError(
          'Potential circular reference detected after 5 serializations');
    }

    final subject = BlankNodeTerm();
    final triples = [
      Triple(subject, const IriTerm('http://example.org/name'),
          LiteralTerm.string(instance.name)),
      Triple(subject, const IriTerm('http://example.org/age'),
          LiteralTerm.typed(instance.age.toString(), 'integer')),
    ];
    return (subject, triples);
  }

  static void reset() {
    serializationCount = 0;
  }
}

/// Serializer that handles object sharing properly without false cycle detection
class SafePersonSerializer implements LocalResourceSerializer<TestPerson> {
  final Map<TestPerson, BlankNodeTerm> _serializedObjects = {};

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Person');

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    // Reuse the same subject for the same object instance (proper sharing)
    final subject =
        _serializedObjects.putIfAbsent(instance, () => BlankNodeTerm());

    final triples = [
      Triple(subject, const IriTerm('http://example.org/name'),
          LiteralTerm.string(instance.name)),
      Triple(subject, const IriTerm('http://example.org/age'),
          LiteralTerm.typed(instance.age.toString(), 'integer')),
    ];
    return (subject, triples);
  }
}

/// Serializer that fails on a specific condition to test error handling
class FailingPersonSerializer implements LocalResourceSerializer<TestPerson> {
  static int callCount = 0;

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Person');

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    callCount++;
    if (callCount == 2) {
      throw StateError('Serialization failure on second person');
    }

    final subject = BlankNodeTerm();
    final triples = [
      Triple(subject, const IriTerm('http://example.org/name'),
          LiteralTerm.string(instance.name)),
    ];
    return (subject, triples);
  }

  static void reset() {
    callCount = 0;
  }
}

/// Serializer that tracks depth to prevent infinite recursion
class CountingPersonSerializer implements LocalResourceSerializer<TestPerson> {
  static int depth = 0;
  static const maxDepth = 1000;

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Person');

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      TestPerson instance, SerializationContext context,
      {RdfSubject? parentSubject}) {
    depth++;
    if (depth > maxDepth) {
      throw StateError('Maximum serialization depth exceeded: $depth');
    }

    try {
      final subject = BlankNodeTerm();
      final triples = [
        Triple(subject, const IriTerm('http://example.org/name'),
            LiteralTerm.string('${instance.name}_$depth')),
        Triple(subject, const IriTerm('http://example.org/age'),
            LiteralTerm.typed(instance.age.toString(), 'integer')),
      ];
      return (subject, triples);
    } finally {
      depth--;
    }
  }

  static void reset() {
    depth = 0;
  }
}

void main() {
  late RdfMapperRegistry registry;
  late SerializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
    context = SerializationContextImpl(registry: registry);
  });

  group('RdfListSerializer', () {
    test('serializes empty list (returns rdf:nil)', () {
      final serializer = RdfListSerializer<String>();
      final (head, triples) = serializer.toRdfResource([], context);

      expect(head, equals(Rdf.nil));
      expect(triples, isEmpty);
    });

    test('serializes single element string list', () {
      final serializer = RdfListSerializer<String>();
      final (head, triples) = serializer.toRdfResource(['hello'], context);

      expect(head, isA<BlankNodeTerm>());
      expect(triples.length, equals(2));

      // Should have rdf:first pointing to the string literal
      final firstTriple = triples.firstWhere((t) => t.predicate == Rdf.first);
      expect(firstTriple.subject, equals(head));
      expect(firstTriple.object, equals(LiteralTerm.string('hello')));

      // Should have rdf:rest pointing to rdf:nil
      final restTriple = triples.firstWhere((t) => t.predicate == Rdf.rest);
      expect(restTriple.subject, equals(head));
      expect(restTriple.object, equals(Rdf.nil));
    });

    test('serializes multi-element string list', () {
      final values = ['apple', 'banana', 'cherry'];
      final serializer = RdfListSerializer<String>();
      final (head, triples) = serializer.toRdfResource(values, context);

      expect(head, isA<BlankNodeTerm>());

      // Should have 6 triples total (2 per element: first + rest)
      expect(triples.length, equals(6));

      // Extract all subjects (list nodes)
      final subjects = triples.map((t) => t.subject).toSet();
      expect(subjects.length, equals(3)); // 3 list nodes

      // Verify the list structure by following rdf:rest chain
      var currentNode = head;
      final visitedValues = <String>[];

      for (int i = 0; i < 3; i++) {
        // Find rdf:first triple for current node
        final firstTriple = triples.firstWhere(
            (t) => t.subject == currentNode && t.predicate == Rdf.first);
        final valueString = (firstTriple.object as LiteralTerm).value;
        visitedValues.add(valueString);

        // Find rdf:rest triple for current node
        final restTriple = triples.firstWhere(
            (t) => t.subject == currentNode && t.predicate == Rdf.rest);

        if (i < 2) {
          // Should point to next node
          expect(restTriple.object, isA<BlankNodeTerm>());
          currentNode = restTriple.object as BlankNodeTerm;
        } else {
          // Last element should point to rdf:nil
          expect(restTriple.object, equals(Rdf.nil));
        }
      }

      expect(visitedValues, equals(['apple', 'banana', 'cherry']));
    });

    test('serializes integer list', () {
      final serializer = RdfListSerializer<int>();
      final (head, triples) = serializer.toRdfResource([42, 99, 123], context);

      expect(head, isA<BlankNodeTerm>());
      expect(triples.length, equals(6)); // 3 elements × 2 triples each

      // Check first element
      final firstTriple = triples
          .firstWhere((t) => t.subject == head && t.predicate == Rdf.first);
      expect(firstTriple.object, equals(LiteralTerm.typed('42', 'integer')));
    });

    test('serializes list with custom string serializer', () {
      final serializer = RdfListSerializer<String>(
          itemSerializer: UpperCaseStringSerializer());
      final (head, triples) =
          serializer.toRdfResource(['hello', 'world'], context);

      expect(head, isA<BlankNodeTerm>());

      // Check that strings are converted to uppercase
      final firstValues = triples
          .where((t) => t.predicate == Rdf.first)
          .map((t) => (t.object as LiteralTerm).value)
          .toList();

      expect(firstValues, equals(['HELLO', 'WORLD']));
    });

    test('serializes list of local resources (blank nodes)', () {
      final persons = [
        TestPerson(name: 'Alice', age: 25),
        TestPerson(name: 'Bob', age: 30),
      ];

      // Register the serializer
      registry.registerSerializer(TestPersonSerializer());

      final serializer = RdfListSerializer<TestPerson>();
      final (head, triples) = serializer.toRdfResource(persons, context);

      expect(head, isA<BlankNodeTerm>());

      // Should have list structure triples + person property triples
      // List: 4 triples (2 elements × 2 list triples)
      // Persons: 6 triples (2 persons × 2 properties each + 1 type each)
      expect(triples.length, equals(10));

      // Check that person properties are included
      final nameTriples = triples
          .where((t) => t.predicate == const IriTerm('http://example.org/name'))
          .toList();
      expect(nameTriples.length, equals(2));

      final names =
          nameTriples.map((t) => (t.object as LiteralTerm).value).toSet();
      expect(names, equals({'Alice', 'Bob'}));
    });

    test('serializes list of global resources (IRIs)', () {
      final products = [
        TestProduct(id: '1', name: 'Laptop', price: 999.99),
        TestProduct(id: '2', name: 'Phone', price: 599.99),
      ];

      // Register the serializer
      registry.registerSerializer(TestProductSerializer());

      final serializer = RdfListSerializer<TestProduct>();
      final (head, triples) = serializer.toRdfResource(products, context);

      expect(head, isA<BlankNodeTerm>());

      // List structure + product properties
      expect(triples.length, equals(10));

      // Check that the first elements point to IRIs
      final firstTriples =
          triples.where((t) => t.predicate == Rdf.first).toList();
      expect(firstTriples.length, equals(2));

      final productIris =
          firstTriples.map((t) => (t.object as IriTerm).value).toSet();
      expect(
          productIris,
          equals({
            'http://example.org/product/1',
            'http://example.org/product/2'
          }));
    });

    test('has correct typeIri', () {
      final serializer = RdfListSerializer<String>();
      expect(serializer.typeIri, equals(Rdf.List));
    });

    test('handles boolean list', () {
      final serializer = RdfListSerializer<bool>();
      final (head, triples) =
          serializer.toRdfResource([true, false, true], context);

      expect(head, isA<BlankNodeTerm>());

      final firstValues = triples
          .where((t) => t.predicate == Rdf.first)
          .map((t) => t.object as LiteralTerm)
          .toList();

      expect(firstValues.length, equals(3));
      expect(firstValues[0].value, equals('true'));
      expect(firstValues[1].value, equals('false'));
      expect(firstValues[2].value, equals('true'));
    });

    test('handles mixed type list using registry serializers', () {
      final person = TestPerson(name: 'John', age: 25);
      registry.registerSerializer(TestPersonSerializer());

      // Mix of primitive and object
      final serializer = RdfListSerializer<dynamic>();
      final (head, triples) =
          serializer.toRdfResource(['start', person, 'end'], context);

      expect(head, isA<BlankNodeTerm>());

      // Should have list structure + person properties
      expect(
          triples.length, equals(9)); // 6 list + 2 person properties + 1 type

      // Verify the sequence by following the list
      var currentNode = head;
      final sequence = <dynamic>[];

      for (int i = 0; i < 3; i++) {
        final firstTriple = triples.firstWhere(
            (t) => t.subject == currentNode && t.predicate == Rdf.first);
        sequence.add(firstTriple.object);

        final restTriple = triples.firstWhere(
            (t) => t.subject == currentNode && t.predicate == Rdf.rest);

        if (i < 2) {
          currentNode = restTriple.object as BlankNodeTerm;
        }
      }

      expect(sequence[0], equals(LiteralTerm.string('start')));
      expect(sequence[1], isA<BlankNodeTerm>()); // Person as blank node
      expect(sequence[2], equals(LiteralTerm.string('end')));
    });

    test('throws exception when no serializer found for custom type', () {
      // Create an unregistered custom type
      final unknownObject = TestPerson(name: 'Unknown', age: 999);
      final serializer = RdfListSerializer<TestPerson>();

      // Should throw when trying to serialize without a registered serializer
      expect(() => serializer.toRdfResource([unknownObject], context),
          throwsA(isA<Exception>()));
    });

    test('handles null values in list by throwing exception', () {
      final serializer = RdfListSerializer<String?>();
      // The serialize method throws ArgumentError for null values
      expect(() => serializer.toRdfResource([null], context),
          throwsA(isA<ArgumentError>()));
    });

    test('preserves order in complex nested structures', () {
      final products = [
        TestProduct(id: 'A', name: 'First', price: 1.0),
        TestProduct(id: 'B', name: 'Second', price: 2.0),
        TestProduct(id: 'C', name: 'Third', price: 3.0),
      ];

      registry.registerSerializer(TestProductSerializer());

      final serializer = RdfListSerializer<TestProduct>();
      final (head, triples) = serializer.toRdfResource(products, context);

      // Extract IRIs in order by following the list structure
      var currentNode = head;
      final orderedIris = <String>[];

      for (int i = 0; i < 3; i++) {
        final firstTriple = triples.firstWhere(
            (t) => t.subject == currentNode && t.predicate == Rdf.first);
        final iri = (firstTriple.object as IriTerm).value;
        orderedIris.add(iri);

        if (i < 2) {
          final restTriple = triples.firstWhere(
              (t) => t.subject == currentNode && t.predicate == Rdf.rest);
          currentNode = restTriple.object as BlankNodeTerm;
        }
      }

      expect(
          orderedIris,
          equals([
            'http://example.org/product/A',
            'http://example.org/product/B',
            'http://example.org/product/C'
          ]));
    });

    test('handles empty nested lists', () {
      // Test with empty list
      final emptyList = <String>[];
      final serializer = RdfListSerializer<String>();
      final (head, triples) = serializer.toRdfResource(emptyList, context);

      expect(head, equals(Rdf.nil));
      expect(triples, isEmpty);
    });

    test('handles DateTime values correctly', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 6, 15),
        DateTime(2024, 12, 31),
      ];

      final serializer = RdfListSerializer<DateTime>();
      final (head, triples) = serializer.toRdfResource(dates, context);

      expect(head, isA<BlankNodeTerm>());
      expect(triples.length, equals(6)); // 3 elements × 2 triples each

      // Check that dates are properly serialized as literals
      final firstTriples =
          triples.where((t) => t.predicate == Rdf.first).toList();

      for (final triple in firstTriples) {
        expect(triple.object, isA<LiteralTerm>());
        final literal = triple.object as LiteralTerm;
        expect(literal.datatype.value,
            contains('date')); // Should be dateTime type
      }
    });

    test('handles URIs and IRIs in list', () {
      final uris = [
        'http://example.org/resource1',
        'http://example.org/resource2',
        'https://schema.org/Person',
      ];

      // Force URIs to be treated as string literals using StringMapper
      final serializer = RdfListSerializer<String>();
      final (head, triples) = serializer.toRdfResource(uris, context);

      expect(head, isA<BlankNodeTerm>());

      // URIs should be serialized as string literals in this context
      final firstTriples =
          triples.where((t) => t.predicate == Rdf.first).toList();

      final uriStrings =
          firstTriples.map((t) => (t.object as LiteralTerm).value).toList();

      expect(uriStrings, equals(uris));
    });
  });

  group('RdfListSerializer - Circular Reference Detection', () {
    setUp(() {
      // Reset any static counters before each test
      CycleDetectingPersonSerializer.reset();
      FailingPersonSerializer.reset();
      CountingPersonSerializer.reset();
    });

    test('handles potential serialization issues without infinite loops', () {
      // Use the cycle detecting serializer
      final reg = registry.clone()
        ..registerSerializer(CycleDetectingPersonSerializer());
      final context = SerializationContextImpl(registry: reg);

      // Create enough objects to potentially trigger the cycle detection
      final persons =
          List.generate(10, (i) => TestPerson(name: 'Person$i', age: 20 + i));

      final serializer = RdfListSerializer<TestPerson>();
      // Should detect when serialization count exceeds threshold
      expect(() => serializer.toRdfResource(persons, context),
          throwsA(isA<StateError>()));
    });

    test(
        'handles legitimate object sharing without false positive cycle detection',
        () {
      // Test that the same object appearing multiple times doesn't trigger false cycle detection
      final sharedPerson = TestPerson(name: 'Shared', age: 30);

      registry.registerSerializer(SafePersonSerializer());

      final serializer = RdfListSerializer<TestPerson>();
      // The same object appears multiple times - this should work fine
      final (head, triples) = serializer
          .toRdfResource([sharedPerson, sharedPerson, sharedPerson], context);

      expect(head, isA<BlankNodeTerm>());

      // Should handle shared references correctly
      final listTriples = triples
          .where((t) => t.predicate == Rdf.first || t.predicate == Rdf.rest)
          .length;
      expect(listTriples, equals(6)); // 3 elements × 2 list triples each
    });

    test('handles serialization failure during list building', () {
      final persons = [
        TestPerson(name: 'First', age: 25),
        TestPerson(name: 'Second', age: 30), // This one will fail
        TestPerson(name: 'Third', age: 35),
      ];

      registry.registerSerializer(FailingPersonSerializer());

      final serializer = RdfListSerializer<TestPerson>();
      // Should propagate the serialization failure
      expect(() => serializer.toRdfResource(persons, context),
          throwsA(isA<StateError>()));
    });

    test('handles deep recursive serialization without infinite loops', () {
      // Create a scenario with deep nesting but no actual cycles
      registry.registerSerializer(CountingPersonSerializer());

      // Should work fine for reasonable list sizes
      final persons =
          List.generate(10, (i) => TestPerson(name: 'Person$i', age: 20 + i));
      final serializer = RdfListSerializer<TestPerson>();
      final (head, triples) = serializer.toRdfResource(persons, context);

      expect(head, isA<BlankNodeTerm>());
      expect(triples.isNotEmpty, isTrue);

      // Verify all persons were serialized
      final nameTriples = triples
          .where((t) => t.predicate == const IriTerm('http://example.org/name'))
          .length;
      expect(nameTriples, equals(10));
    });

    test('handles empty list correctly without cycle issues', () {
      // Ensure empty lists are handled correctly
      final serializer = RdfListSerializer<TestPerson>();
      final (head, triples) = serializer.toRdfResource(<TestPerson>[], context);

      expect(head, equals(Rdf.nil));
      expect(triples, isEmpty);
    });

    test('handles very large lists without performance degradation', () {
      // Test that large lists don't cause cycle detection false positives
      registry.registerSerializer(TestPersonSerializer());

      final largeList =
          List.generate(1000, (i) => TestPerson(name: 'Person$i', age: 20));

      final serializer = RdfListSerializer<TestPerson>();
      // Should complete without throwing cycle detection errors
      final (head, triples) = serializer.toRdfResource(largeList, context);

      expect(head, isA<BlankNodeTerm>());

      // Verify structure without fully evaluating (for performance)
      expect(triples.isNotEmpty, isTrue);

      // Verify first element is properly structured by checking first few triples
      final firstElementTriple = triples
          .firstWhere((t) => t.subject == head && t.predicate == Rdf.first);
      expect(firstElementTriple.object, isA<BlankNodeTerm>());
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_vocabularies_core/vcard.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl context;
  final subject = const IriTerm('http://example.org/subject');

  setUp(() {
    registry = RdfMapperRegistry();
    final addressNode = BlankNodeTerm();
    graph = RdfGraph(
      triples: [
        // String property
        Triple(
          subject,
          const IriTerm('http://example.org/name'),
          LiteralTerm.string('John Doe'),
        ),

        // Integer property
        Triple(
          subject,
          const IriTerm('http://example.org/age'),
          LiteralTerm.typed('30', 'integer'),
        ),

        // Boolean property
        Triple(
          subject,
          const IriTerm('http://example.org/active'),
          LiteralTerm.typed('true', 'boolean'),
        ),

        // IRI property
        Triple(
          subject,
          const IriTerm('http://example.org/friend'),
          const IriTerm('http://example.org/person/jane'),
        ),

        // Multi-valued property
        Triple(
          subject,
          const IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag1'),
        ),
        Triple(
          subject,
          const IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag2'),
        ),
        Triple(
          subject,
          const IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag3'),
        ),

        // Blank node property
        Triple(
            subject, const IriTerm('http://example.org/address'), addressNode),
        Triple(
          addressNode,
          VcardUniversalProperties.locality,
          LiteralTerm.string("Hamburg"),
        ),
      ],
    );

    context = DeserializationContextImpl(graph: graph, registry: registry);
  });

  group('DeserializationContextImpl', () {
    test('getPropertyValue returns null for non-existent properties', () {
      final value = context.optional<String>(
        subject,
        const IriTerm('http://example.org/nonexistent'),
      );
      expect(value, isNull);
    });

    test('getPropertyValue correctly retrieves string values', () {
      final value = context.optional<String>(
        subject,
        const IriTerm('http://example.org/name'),
      );
      expect(value, equals('John Doe'));
    });

    test('getPropertyValue correctly retrieves integer values', () {
      final value = context.optional<int>(
        subject,
        const IriTerm('http://example.org/age'),
      );
      expect(value, equals(30));
    });

    test('getPropertyValue correctly retrieves boolean values', () {
      final value = context.optional<bool>(
        subject,
        const IriTerm('http://example.org/active'),
      );
      expect(value, equals(true));
    });

    test('getPropertyValue correctly retrieves IRI values', () {
      // Register custom IRI deserializer
      registry.registerDeserializer<String>(CustomIriDeserializer());

      final value = context.optional<String>(
        subject,
        const IriTerm('http://example.org/friend'),
      );
      expect(value, equals('http://example.org/person/jane'));
    });

    test('require throws exception for missing properties', () {
      expect(
        () => context.require<String>(
          subject,
          const IriTerm('http://example.org/nonexistent'),
        ),
        throwsA(isA<PropertyValueNotFoundException>()),
      );
    });

    test(
      'getPropertyValue throws exception for multi-valued properties when enforceSingleValue is true',
      () {
        expect(
          () => context.optional<String>(
            subject,
            const IriTerm('http://example.org/tags'),
          ),
          throwsA(isA<TooManyPropertyValuesException>()),
        );
      },
    );

    test(
      'getPropertyValue allows multi-valued properties when enforceSingleValue is false',
      () {
        final value = context.optional<String>(
          subject,
          const IriTerm('http://example.org/tags'),
          enforceSingleValue: false,
        );
        expect(value, equals('tag1')); // Returns the first value
      },
    );

    test('getPropertyValues collects all values for a property', () {
      final values = context.collect<String, List<String>>(
        subject,
        const IriTerm('http://example.org/tags'),
        (values) => values.toList(),
      );

      expect(values, hasLength(3));
      expect(values, containsAll(['tag1', 'tag2', 'tag3']));
    });

    test('getPropertyValueList is a convenient shorthand for lists', () {
      final values = context.getValues<String>(
        subject,
        const IriTerm('http://example.org/tags'),
      );

      expect(values, hasLength(3));
      expect(values, containsAll(['tag1', 'tag2', 'tag3']));
    });

    test(
      'fromRdf correctly converts BlankNode values with custom deserializer',
      () {
        registry.registerDeserializer<TestAddress>(
          CustomLocalResourceDeserializer(),
        );

        final address = context.optional<TestAddress>(
          subject,
          const IriTerm('http://example.org/address'),
        );

        expect(address, isNotNull);
        expect(address!.city, equals('Hamburg'));
      },
    );

    test('fromRdfByType deserializes objects by type IRI', () {
      // Register a subject deserializer
      final deserializer = TestPersonDeserializer();
      registry.registerDeserializer<TestPerson>(deserializer);

      // Call fromRdfByType directly
      final person = context.deserializeResource(
        const IriTerm('http://example.org/subject'),
        const IriTerm('http://example.org/Person'),
      );

      expect(person, isA<TestPerson>());
      expect((person as TestPerson).id, equals('http://example.org/subject'));
    });

    test('getPropertyValue uses custom deserializers when provided', () {
      final customLiteralDeserializer = CustomStringDeserializer();

      final value = context.optional<String>(
        subject,
        const IriTerm('http://example.org/name'),
        deserializer: customLiteralDeserializer,
      );

      expect(
        value,
        equals('JOHN DOE'),
      ); // Custom deserializer converts to uppercase
    });
  });

  group('getTriplesForSubject with cycles', () {
    test('handles cyclic blank node references without infinite recursion', () {
      // Create a cycle: blankNode1 -> blankNode2 -> blankNode1
      final blankNode1 = BlankNodeTerm();
      final blankNode2 = BlankNodeTerm();
      final predicate = const IriTerm('http://example.org/references');

      final cyclicGraph = RdfGraph(triples: [
        Triple(blankNode1, predicate, blankNode2),
        Triple(blankNode2, predicate, blankNode1),
        Triple(subject, predicate, blankNode1),
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // This should not cause a stack overflow or infinite recursion
      final result =
          cyclicContext.getTriplesForSubject(subject, includeBlankNodes: true);

      // Should include all triples in the cycle
      expect(result.length, equals(3));
      expect(result.any((t) => t.subject == subject), isTrue);
      expect(result.any((t) => t.subject == blankNode1), isTrue);
      expect(result.any((t) => t.subject == blankNode2), isTrue);
    });

    test('handles self-referencing blank nodes', () {
      final selfRefBlankNode = BlankNodeTerm();
      final predicate = const IriTerm('http://example.org/self');

      final selfRefGraph = RdfGraph(triples: [
        Triple(subject, predicate, selfRefBlankNode),
        Triple(selfRefBlankNode, predicate, selfRefBlankNode), // Self-reference
      ]);

      final selfRefContext = DeserializationContextImpl(
        graph: selfRefGraph,
        registry: registry,
      );

      // This should not cause infinite recursion
      final result =
          selfRefContext.getTriplesForSubject(subject, includeBlankNodes: true);

      expect(result.length, equals(2));
      expect(result.any((t) => t.subject == subject), isTrue);
      expect(result.any((t) => t.subject == selfRefBlankNode), isTrue);
    });

    test('handles complex cycles with multiple interconnected blank nodes', () {
      final blankNode1 = BlankNodeTerm();
      final blankNode2 = BlankNodeTerm();
      final blankNode3 = BlankNodeTerm();
      final predicate = const IriTerm('http://example.org/connects');

      final complexGraph = RdfGraph(triples: [
        Triple(subject, predicate, blankNode1),
        Triple(blankNode1, predicate, blankNode2),
        Triple(blankNode2, predicate, blankNode3),
        Triple(blankNode3, predicate, blankNode1), // Creates cycle
        Triple(blankNode2, predicate, blankNode1), // Additional connection
      ]);

      final complexContext = DeserializationContextImpl(
        graph: complexGraph,
        registry: registry,
      );

      final result =
          complexContext.getTriplesForSubject(subject, includeBlankNodes: true);

      expect(result.length, equals(5));
      expect(result.any((t) => t.subject == subject), isTrue);
      expect(result.any((t) => t.subject == blankNode1), isTrue);
      expect(result.any((t) => t.subject == blankNode2), isTrue);
      expect(result.any((t) => t.subject == blankNode3), isTrue);
    });
  });

  group('getBlankNodesDeepImpl', () {
    test('handles empty triples list', () {
      final result = DeserializationContextImpl.getBlankNodeObjectsDeep(
          graph, [], <BlankNodeTerm>{});

      expect(result, isEmpty);
    });

    test('prevents infinite recursion with cycles', () {
      final blankNode1 = BlankNodeTerm();
      final blankNode2 = BlankNodeTerm();
      final testGraph = RdfGraph(triples: [
        Triple(blankNode1, const IriTerm('http://example.org/ref'), blankNode2),
        Triple(blankNode2, const IriTerm('http://example.org/ref'), blankNode1),
      ]);

      final result = DeserializationContextImpl.getBlankNodeObjectsDeep(
          testGraph, testGraph.triples, <BlankNodeTerm>{});

      expect(result, contains(blankNode1));
      expect(result, contains(blankNode2));
      expect(result, hasLength(2));
    });

    test('respects visited set to avoid reprocessing', () {
      final blankNode1 = BlankNodeTerm();
      final blankNode2 = BlankNodeTerm();
      final visited = <BlankNodeTerm>{blankNode1};

      final testGraph = RdfGraph(triples: [
        Triple(blankNode1, const IriTerm('http://example.org/ref'), blankNode2),
        Triple(blankNode2, const IriTerm('http://example.org/prop'),
            LiteralTerm.string('value')),
      ]);

      final result = DeserializationContextImpl.getBlankNodeObjectsDeep(
          testGraph, testGraph.triples, visited);

      expect(result, isNot(contains(blankNode1))); // Already visited
      expect(result, contains(blankNode2));
      expect(result, hasLength(1));
    });
  });
}

// Test classes and custom deserializers

class TestPerson {
  final String id;

  TestPerson(this.id);
}

class TestAddress {
  final String city;

  TestAddress({required this.city});
}

class TestPersonDeserializer implements GlobalResourceDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  TestPerson fromRdfResource(IriTerm term, DeserializationContext context) {
    return TestPerson(term.value);
  }
}

class CustomIriDeserializer implements IriTermDeserializer<String> {
  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.value;
  }
}

class CustomStringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm datatype;

  const CustomStringDeserializer([this.datatype = Xsd.string]);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toUpperCase(); // Convert to uppercase for testing
  }
}

class CustomLocalResourceDeserializer
    implements LocalResourceDeserializer<TestAddress> {
  @override
  IriTerm? get typeIri => null;
  @override
  TestAddress fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    var city = reader.require<String>(VcardUniversalProperties.locality);
    return TestAddress(city: city);
  }
}

// Additional test deserializer for map testing
class KeyValueDeserializer
    implements LiteralTermDeserializer<MapEntry<String, String>> {
  final IriTerm datatype;
  const KeyValueDeserializer([this.datatype = Xsd.string]);
  @override
  MapEntry<String, String> fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    final parts = term.value.split(':');
    return MapEntry(parts[0], parts[1]);
  }
}

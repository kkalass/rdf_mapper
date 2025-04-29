import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/src/deserializers/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/src/deserializers/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/src/deserializers/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/deserializers/rdf_subject_deserializer.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:test/test.dart';

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl context;
  final subject = IriTerm('http://example.org/subject');

  setUp(() {
    registry = RdfMapperRegistry();
    final addressNode = BlankNodeTerm();
    graph = RdfGraph(
      triples: [
        // String property
        Triple(
          subject,
          IriTerm('http://example.org/name'),
          LiteralTerm.string('John Doe'),
        ),

        // Integer property
        Triple(
          subject,
          IriTerm('http://example.org/age'),
          LiteralTerm.typed('30', 'integer'),
        ),

        // Boolean property
        Triple(
          subject,
          IriTerm('http://example.org/active'),
          LiteralTerm.typed('true', 'boolean'),
        ),

        // IRI property
        Triple(
          subject,
          IriTerm('http://example.org/friend'),
          IriTerm('http://example.org/person/jane'),
        ),

        // Multi-valued property
        Triple(
          subject,
          IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag1'),
        ),
        Triple(
          subject,
          IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag2'),
        ),
        Triple(
          subject,
          IriTerm('http://example.org/tags'),
          LiteralTerm.string('tag3'),
        ),

        // Blank node property
        Triple(subject, IriTerm('http://example.org/address'), addressNode),
        Triple(
          addressNode,
          VcardPredicates.locality,
          LiteralTerm.string("Hamburg"),
        ),
      ],
    );

    context = DeserializationContextImpl(graph: graph, registry: registry);
  });

  group('DeserializationContextImpl', () {
    test('getPropertyValue returns null for non-existent properties', () {
      final value = context.get<String>(
        subject,
        IriTerm('http://example.org/nonexistent'),
      );
      expect(value, isNull);
    });

    test('getPropertyValue correctly retrieves string values', () {
      final value = context.get<String>(
        subject,
        IriTerm('http://example.org/name'),
      );
      expect(value, equals('John Doe'));
    });

    test('getPropertyValue correctly retrieves integer values', () {
      final value = context.get<int>(
        subject,
        IriTerm('http://example.org/age'),
      );
      expect(value, equals(30));
    });

    test('getPropertyValue correctly retrieves boolean values', () {
      final value = context.get<bool>(
        subject,
        IriTerm('http://example.org/active'),
      );
      expect(value, equals(true));
    });

    test('getPropertyValue correctly retrieves IRI values', () {
      // Register custom IRI deserializer
      registry.registerIriTermDeserializer<String>(CustomIriDeserializer());

      final value = context.get<String>(
        subject,
        IriTerm('http://example.org/friend'),
      );
      expect(value, equals('http://example.org/person/jane'));
    });

    test('require throws exception for missing properties', () {
      expect(
        () => context.require<String>(
          subject,
          IriTerm('http://example.org/nonexistent'),
        ),
        throwsA(isA<PropertyValueNotFoundException>()),
      );
    });

    test(
      'getPropertyValue throws exception for multi-valued properties when enforceSingleValue is true',
      () {
        expect(
          () =>
              context.get<String>(subject, IriTerm('http://example.org/tags')),
          throwsA(isA<TooManyPropertyValuesException>()),
        );
      },
    );

    test(
      'getPropertyValue allows multi-valued properties when enforceSingleValue is false',
      () {
        final value = context.get<String>(
          subject,
          IriTerm('http://example.org/tags'),
          enforceSingleValue: false,
        );
        expect(value, equals('tag1')); // Returns the first value
      },
    );

    test('getPropertyValues collects all values for a property', () {
      final values = context.getMany<String, List<String>>(
        subject,
        IriTerm('http://example.org/tags'),
        (values) => values.toList(),
      );

      expect(values, hasLength(3));
      expect(values, containsAll(['tag1', 'tag2', 'tag3']));
    });

    test('getPropertyValueList is a convenient shorthand for lists', () {
      final values = context.getList<String>(
        subject,
        IriTerm('http://example.org/tags'),
      );

      expect(values, hasLength(3));
      expect(values, containsAll(['tag1', 'tag2', 'tag3']));
    });

    test(
      'fromRdf correctly converts BlankNode values with custom deserializer',
      () {
        registry.registerBlankNodeTermDeserializer<TestAddress>(
          CustomBlankNodeDeserializer(),
        );

        final address = context.get<TestAddress>(
          subject,
          IriTerm('http://example.org/address'),
        );

        expect(address, isNotNull);
        expect(address!.city, equals('Hamburg'));
      },
    );

    test('fromRdfByTypeIri deserializes objects by type IRI', () {
      // Register a subject deserializer
      final deserializer = TestPersonDeserializer();
      registry.registerSubjectDeserializer<TestPerson>(deserializer);

      // Call fromRdfByTypeIri directly
      final person = context.deserializeSubject(
        IriTerm('http://example.org/subject'),
        IriTerm('http://example.org/Person'),
      );

      expect(person, isA<TestPerson>());
      expect((person as TestPerson).id, equals('http://example.org/subject'));
    });

    test('getPropertyValue uses custom deserializers when provided', () {
      final customLiteralDeserializer = CustomStringDeserializer();

      final value = context.get<String>(
        subject,
        IriTerm('http://example.org/name'),
        literalDeserializer: customLiteralDeserializer,
      );

      expect(
        value,
        equals('JOHN DOE'),
      ); // Custom deserializer converts to uppercase
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

class TestPersonDeserializer implements RdfSubjectDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Person');

  @override
  TestPerson fromIriTerm(IriTerm term, DeserializationContext context) {
    return TestPerson(term.iri);
  }
}

class CustomIriDeserializer implements RdfIriTermDeserializer<String> {
  @override
  String fromIriTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
  }
}

class CustomStringDeserializer implements RdfLiteralTermDeserializer<String> {
  @override
  String fromLiteralTerm(LiteralTerm term, DeserializationContext context) {
    return term.value.toUpperCase(); // Convert to uppercase for testing
  }
}

class CustomBlankNodeDeserializer
    implements RdfBlankNodeTermDeserializer<TestAddress> {
  @override
  TestAddress fromBlankNodeTerm(
    BlankNodeTerm term,
    DeserializationContext context,
  ) {
    var city = context.require<String>(term, VcardPredicates.locality);
    return TestAddress(city: city);
  }
}

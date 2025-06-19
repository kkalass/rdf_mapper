import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_vocabularies/vcard.dart';
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
        IriTerm('http://example.org/nonexistent'),
      );
      expect(value, isNull);
    });

    test('getPropertyValue correctly retrieves string values', () {
      final value = context.optional<String>(
        subject,
        IriTerm('http://example.org/name'),
      );
      expect(value, equals('John Doe'));
    });

    test('getPropertyValue correctly retrieves integer values', () {
      final value = context.optional<int>(
        subject,
        IriTerm('http://example.org/age'),
      );
      expect(value, equals(30));
    });

    test('getPropertyValue correctly retrieves boolean values', () {
      final value = context.optional<bool>(
        subject,
        IriTerm('http://example.org/active'),
      );
      expect(value, equals(true));
    });

    test('getPropertyValue correctly retrieves IRI values', () {
      // Register custom IRI deserializer
      registry.registerDeserializer<String>(CustomIriDeserializer());

      final value = context.optional<String>(
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
          () => context.optional<String>(
            subject,
            IriTerm('http://example.org/tags'),
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
          IriTerm('http://example.org/tags'),
          enforceSingleValue: false,
        );
        expect(value, equals('tag1')); // Returns the first value
      },
    );

    test('getPropertyValues collects all values for a property', () {
      final values = context.collect<String, List<String>>(
        subject,
        IriTerm('http://example.org/tags'),
        (values) => values.toList(),
      );

      expect(values, hasLength(3));
      expect(values, containsAll(['tag1', 'tag2', 'tag3']));
    });

    test('getPropertyValueList is a convenient shorthand for lists', () {
      final values = context.getValues<String>(
        subject,
        IriTerm('http://example.org/tags'),
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
          IriTerm('http://example.org/address'),
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
        IriTerm('http://example.org/subject'),
        IriTerm('http://example.org/Person'),
      );

      expect(person, isA<TestPerson>());
      expect((person as TestPerson).id, equals('http://example.org/subject'));
    });

    test('getPropertyValue uses custom deserializers when provided', () {
      final customLiteralDeserializer = CustomStringDeserializer();

      final value = context.optional<String>(
        subject,
        IriTerm('http://example.org/name'),
        literalTermDeserializer: customLiteralDeserializer,
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

class TestPersonDeserializer implements GlobalResourceDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Person');

  @override
  TestPerson fromRdfResource(IriTerm term, DeserializationContext context) {
    return TestPerson(term.iri);
  }
}

class CustomIriDeserializer implements IriTermDeserializer<String> {
  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
  }
}

class CustomStringDeserializer implements LiteralTermDeserializer<String> {
  const CustomStringDeserializer();
  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context) {
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

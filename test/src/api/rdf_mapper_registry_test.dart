import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperRegistry', () {
    late RdfMapperRegistry registry;

    setUp(() {
      registry = RdfMapperRegistry();
    });

    test('registry is initialized with standard mappers', () {
      // Verify built-in deserializers are registered
      expect(registry.hasLiteralTermDeserializerFor<String>(), isTrue);
      expect(registry.hasLiteralTermDeserializerFor<int>(), isTrue);
      expect(registry.hasLiteralTermDeserializerFor<double>(), isTrue);
      expect(registry.hasLiteralTermDeserializerFor<bool>(), isTrue);
      expect(registry.hasLiteralTermDeserializerFor<DateTime>(), isTrue);

      // Verify built-in serializers are registered
      expect(registry.hasLiteralTermSerializerFor<String>(), isTrue);
      expect(registry.hasLiteralTermSerializerFor<int>(), isTrue);
      expect(registry.hasLiteralTermSerializerFor<double>(), isTrue);
      expect(registry.hasLiteralTermSerializerFor<bool>(), isTrue);
      expect(registry.hasLiteralTermSerializerFor<DateTime>(), isTrue);

      // Verify IRI serializers/deserializers (IriFullDeserializer is for String type)
      expect(registry.hasIriTermDeserializerFor<String>(), isTrue);
      expect(registry.hasIriTermSerializerFor<String>(), isTrue);
    });

    test('registerDeserializer registers a new IRI deserializer', () {
      // Register custom deserializer
      registry.registerDeserializer(TestIriDeserializer());

      // Verify registration
      expect(registry.hasIriTermDeserializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var deserializer = registry.getIriTermDeserializer<CustomType>();
      expect(deserializer, isA<TestIriDeserializer>());
    });

    test('registerSerializer registers a new IRI serializer', () {
      // Register custom serializer
      registry.registerSerializer(TestIriSerializer());

      // Verify registration
      expect(registry.hasIriTermSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var serializer = registry.getIriTermSerializer<CustomType>();
      expect(serializer, isA<TestIriSerializer>());
    });

    test('registerDeserializer registers a new literal deserializer', () {
      // Register custom deserializer
      registry.registerDeserializer(TestLiteralDeserializer());

      // Verify registration
      expect(registry.hasLiteralTermDeserializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var deserializer = registry.getLiteralTermDeserializer<CustomType>();
      expect(deserializer, isA<TestLiteralDeserializer>());
    });

    test('registerSerializer registers a new literal serializer', () {
      // Register custom serializer
      registry.registerSerializer(TestLiteralSerializer());

      // Verify registration
      expect(registry.hasLiteralTermSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var serializer = registry.getLiteralTermSerializer<CustomType>();
      expect(serializer, isA<TestLiteralSerializer>());
    });

    test(
      'registerDeserializer registers subject deserializer by type and typeIri',
      () {
        final deserializer = TestSubjectDeserializer();
        registry.registerDeserializer<CustomType>(deserializer);

        // Verify registration by type
        expect(registry.hasIriNodeDeserializerFor<CustomType>(), isTrue);
        expect(
          registry.getIriNodeDeserializer<CustomType>(),
          equals(deserializer),
        );

        // Verify registration by typeIri
        expect(
          registry.hasIriNodeDeserializerForType(deserializer.typeIri),
          isTrue,
        );
        expect(
          registry.getIriNodeDeserializerByType(deserializer.typeIri),
          equals(deserializer),
        );
      },
    );

    test('registerSerializer registers a new subject serializer', () {
      final serializer = TestSubjectSerializer();
      registry.registerSerializer<CustomType>(serializer);

      // Verify registration
      expect(registry.hasNodeSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      expect(registry.getNodeSerializer<CustomType>(), equals(serializer));
    });

    test('registerMapper registers both serializer and deserializer', () {
      final mapper = TestSubjectMapper();
      registry.registerMapper<CustomType>(mapper);

      // Verify serializer registration
      expect(registry.hasNodeSerializerFor<CustomType>(), isTrue);
      expect(registry.getNodeSerializer<CustomType>(), equals(mapper));

      // Verify deserializer registration
      expect(registry.hasIriNodeDeserializerFor<CustomType>(), isTrue);
      expect(registry.getIriNodeDeserializer<CustomType>(), equals(mapper));

      // Verify typeIri registration
      expect(registry.hasIriNodeDeserializerForType(mapper.typeIri), isTrue);
      expect(
        registry.getIriNodeDeserializerByType(mapper.typeIri),
        equals(mapper),
      );
    });

    test('getIriTermDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getIriTermDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getSubjectDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getIriNodeDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getSubjectDeserializerByType throws when deserializer not found', () {
      expect(
        () => registry.getIriNodeDeserializerByType(
          IriTerm('http://example.org/UnknownType'),
        ),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getIriTermSerializer throws when serializer not found', () {
      expect(
        () => registry.getIriTermSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('getLiteralTermDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getLiteralTermDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getLiteralTermSerializer throws when serializer not found', () {
      expect(
        () => registry.getLiteralTermSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('getBlankNodeTermDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getBlankNodeDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getSubjectSerializer throws when serializer not found', () {
      expect(
        () => registry.getNodeSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('clone creates a deep copy with all registered mappers', () {
      // Register custom mappers
      registry.registerMapper<CustomType>(TestSubjectMapper());
      registry.registerSerializer(TestLiteralSerializer());
      registry.registerDeserializer(TestLiteralDeserializer());

      // Clone the registry
      final clonedRegistry = registry.clone();

      // Verify all mappers were copied
      expect(clonedRegistry.hasNodeSerializerFor<CustomType>(), isTrue);
      expect(clonedRegistry.hasIriNodeDeserializerFor<CustomType>(), isTrue);
      expect(clonedRegistry.hasLiteralTermSerializerFor<CustomType>(), isTrue);
      expect(
        clonedRegistry.hasLiteralTermDeserializerFor<CustomType>(),
        isTrue,
      );

      // Verify that changing the clone doesn't affect the original
      final newMapper = AnotherTestSubjectMapper();
      clonedRegistry.registerMapper<AnotherCustomType>(newMapper);

      expect(clonedRegistry.hasNodeSerializerFor<AnotherCustomType>(), isTrue);
      expect(registry.hasNodeSerializerFor<AnotherCustomType>(), isFalse);
    });
  });
}

// Test types and mappers

class CustomType {
  final String value;
  CustomType(this.value);
}

class AnotherCustomType {
  final String value;
  AnotherCustomType(this.value);
}

class TestIriDeserializer implements IriTermDeserializer<CustomType> {
  @override
  CustomType fromRdfTerm(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }
}

class TestIriSerializer implements IriTermSerializer<CustomType> {
  @override
  IriTerm toRdfTerm(CustomType value, SerializationContext context) {
    return IriTerm(value.value);
  }
}

class TestLiteralDeserializer implements LiteralTermDeserializer<CustomType> {
  @override
  CustomType fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return CustomType(term.value);
  }
}

class TestLiteralSerializer implements LiteralTermSerializer<CustomType> {
  @override
  LiteralTerm toRdfTerm(CustomType value, SerializationContext context) {
    return LiteralTerm.string(value.value);
  }
}

class TestSubjectDeserializer implements IriNodeDeserializer<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  CustomType fromRdfNode(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }
}

class TestSubjectSerializer implements IriNodeSerializer<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  (IriTerm, List<Triple>) toRdfNode(
    CustomType value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm('http://example.org/instance/${value.value}');
    final triples = <Triple>[
      Triple(
        subject,
        IriTerm('http://example.org/value'),
        LiteralTerm.string(value.value),
      ),
    ];
    return (subject, triples);
  }
}

class TestSubjectMapper implements IriNodeMapper<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  CustomType fromRdfNode(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    CustomType value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm('http://example.org/instance/${value.value}');
    final triples = <Triple>[
      Triple(
        subject,
        IriTerm('http://example.org/value'),
        LiteralTerm.string(value.value),
      ),
    ];
    return (subject, triples);
  }
}

class AnotherTestSubjectMapper implements IriNodeMapper<AnotherCustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/AnotherCustomType');

  @override
  AnotherCustomType fromRdfNode(IriTerm term, DeserializationContext context) {
    return AnotherCustomType(term.iri);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    AnotherCustomType value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm('http://example.org/another/${value.value}');
    final triples = <Triple>[
      Triple(
        subject,
        IriTerm('http://example.org/value'),
        LiteralTerm.string(value.value),
      ),
    ];
    return (subject, triples);
  }
}

import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_mapper/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/rdf_literal_term_serializer.dart';
import 'package:rdf_mapper/rdf_mapper_registry.dart';
import 'package:rdf_mapper/rdf_subject_deserializer.dart';
import 'package:rdf_mapper/rdf_subject_mapper.dart';
import 'package:rdf_mapper/rdf_subject_serializer.dart';
import 'package:rdf_mapper/serialization_context.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperRegistry', () {
    late RdfMapperRegistry registry;

    setUp(() {
      registry = RdfMapperRegistry();
    });

    test('registry is initialized with standard mappers', () {
      // Verify built-in deserializers are registered
      expect(registry.hasLiteralDeserializerFor<String>(), isTrue);
      expect(registry.hasLiteralDeserializerFor<int>(), isTrue);
      expect(registry.hasLiteralDeserializerFor<double>(), isTrue);
      expect(registry.hasLiteralDeserializerFor<bool>(), isTrue);
      expect(registry.hasLiteralDeserializerFor<DateTime>(), isTrue);

      // Verify built-in serializers are registered
      expect(registry.hasLiteralSerializerFor<String>(), isTrue);
      expect(registry.hasLiteralSerializerFor<int>(), isTrue);
      expect(registry.hasLiteralSerializerFor<double>(), isTrue);
      expect(registry.hasLiteralSerializerFor<bool>(), isTrue);
      expect(registry.hasLiteralSerializerFor<DateTime>(), isTrue);

      // Verify IRI serializers/deserializers (IriFullDeserializer is for String type)
      expect(registry.hasIriDeserializerFor<String>(), isTrue);
      expect(registry.hasIriSerializerFor<String>(), isTrue);
    });

    test('registerIriDeserializer registers a new IRI deserializer', () {
      // Register custom deserializer
      registry.registerIriDeserializer(TestIriDeserializer());

      // Verify registration
      expect(registry.hasIriDeserializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var deserializer = registry.getIriDeserializer<CustomType>();
      expect(deserializer, isA<TestIriDeserializer>());
    });

    test('registerIriSerializer registers a new IRI serializer', () {
      // Register custom serializer
      registry.registerIriSerializer(TestIriSerializer());

      // Verify registration
      expect(registry.hasIriSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var serializer = registry.getIriSerializer<CustomType>();
      expect(serializer, isA<TestIriSerializer>());
    });

    test(
      'registerLiteralDeserializer registers a new literal deserializer',
      () {
        // Register custom deserializer
        registry.registerLiteralDeserializer(TestLiteralDeserializer());

        // Verify registration
        expect(registry.hasLiteralDeserializerFor<CustomType>(), isTrue);

        // Verify retrieval works
        var deserializer = registry.getLiteralDeserializer<CustomType>();
        expect(deserializer, isA<TestLiteralDeserializer>());
      },
    );

    test('registerLiteralSerializer registers a new literal serializer', () {
      // Register custom serializer
      registry.registerLiteralSerializer(TestLiteralSerializer());

      // Verify registration
      expect(registry.hasLiteralSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      var serializer = registry.getLiteralSerializer<CustomType>();
      expect(serializer, isA<TestLiteralSerializer>());
    });

    test(
      'registerBlankNodeDeserializer registers a new blank node deserializer',
      () {
        // Register custom deserializer
        registry.registerBlankNodeDeserializer(TestBlankNodeDeserializer());

        // Verify registration
        expect(registry.hasBlankNodeDeserializerFor<CustomType>(), isTrue);

        // Verify retrieval works
        var deserializer = registry.getBlankNodeDeserializer<CustomType>();
        expect(deserializer, isA<TestBlankNodeDeserializer>());
      },
    );

    test(
      'registerSubjectDeserializer registers deserializer by type and typeIri',
      () {
        final deserializer = TestSubjectDeserializer();
        registry.registerSubjectDeserializer<CustomType>(deserializer);

        // Verify registration by type
        expect(registry.hasSubjectDeserializerFor<CustomType>(), isTrue);
        expect(
          registry.getSubjectDeserializer<CustomType>(),
          equals(deserializer),
        );

        // Verify registration by typeIri
        expect(
          registry.hasSubjectDeserializerForType(deserializer.typeIri),
          isTrue,
        );
        expect(
          registry.getSubjectDeserializerByTypeIri(deserializer.typeIri),
          equals(deserializer),
        );
      },
    );

    test('registerSubjectSerializer registers a new subject serializer', () {
      final serializer = TestSubjectSerializer();
      registry.registerSubjectSerializer<CustomType>(serializer);

      // Verify registration
      expect(registry.hasSubjectSerializerFor<CustomType>(), isTrue);

      // Verify retrieval works
      expect(registry.getSubjectSerializer<CustomType>(), equals(serializer));
    });

    test(
      'registerSubjectMapper registers both serializer and deserializer',
      () {
        final mapper = TestSubjectMapper();
        registry.registerSubjectMapper<CustomType>(mapper);

        // Verify serializer registration
        expect(registry.hasSubjectSerializerFor<CustomType>(), isTrue);
        expect(registry.getSubjectSerializer<CustomType>(), equals(mapper));

        // Verify deserializer registration
        expect(registry.hasSubjectDeserializerFor<CustomType>(), isTrue);
        expect(registry.getSubjectDeserializer<CustomType>(), equals(mapper));

        // Verify typeIri registration
        expect(registry.hasSubjectDeserializerForType(mapper.typeIri), isTrue);
        expect(
          registry.getSubjectDeserializerByTypeIri(mapper.typeIri),
          equals(mapper),
        );
      },
    );

    test('getIriDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getIriDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getSubjectDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getSubjectDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test(
      'getSubjectDeserializerByTypeIri throws when deserializer not found',
      () {
        expect(
          () => registry.getSubjectDeserializerByTypeIri(
            IriTerm('http://example.org/UnknownType'),
          ),
          throwsA(isA<DeserializerNotFoundException>()),
        );
      },
    );

    test('getIriSerializer throws when serializer not found', () {
      expect(
        () => registry.getIriSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('getLiteralDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getLiteralDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getLiteralSerializer throws when serializer not found', () {
      expect(
        () => registry.getLiteralSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('getBlankNodeDeserializer throws when deserializer not found', () {
      expect(
        () => registry.getBlankNodeDeserializer<CustomType>(),
        throwsA(isA<DeserializerNotFoundException>()),
      );
    });

    test('getSubjectSerializer throws when serializer not found', () {
      expect(
        () => registry.getSubjectSerializer<CustomType>(),
        throwsA(isA<SerializerNotFoundException>()),
      );
    });

    test('clone creates a deep copy with all registered mappers', () {
      // Register custom mappers
      registry.registerSubjectMapper<CustomType>(TestSubjectMapper());
      registry.registerLiteralSerializer(TestLiteralSerializer());
      registry.registerLiteralDeserializer(TestLiteralDeserializer());

      // Clone the registry
      final clonedRegistry = registry.clone();

      // Verify all mappers were copied
      expect(clonedRegistry.hasSubjectSerializerFor<CustomType>(), isTrue);
      expect(clonedRegistry.hasSubjectDeserializerFor<CustomType>(), isTrue);
      expect(clonedRegistry.hasLiteralSerializerFor<CustomType>(), isTrue);
      expect(clonedRegistry.hasLiteralDeserializerFor<CustomType>(), isTrue);

      // Verify that changing the clone doesn't affect the original
      final newMapper = AnotherTestSubjectMapper();
      clonedRegistry.registerSubjectMapper<AnotherCustomType>(newMapper);

      expect(
        clonedRegistry.hasSubjectSerializerFor<AnotherCustomType>(),
        isTrue,
      );
      expect(registry.hasSubjectSerializerFor<AnotherCustomType>(), isFalse);
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

class TestIriDeserializer implements RdfIriTermDeserializer<CustomType> {
  @override
  CustomType fromIriTerm(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }
}

class TestIriSerializer implements RdfIriTermSerializer<CustomType> {
  @override
  IriTerm toIriTerm(CustomType value, SerializationContext context) {
    return IriTerm(value.value);
  }
}

class TestLiteralDeserializer
    implements RdfLiteralTermDeserializer<CustomType> {
  @override
  CustomType fromLiteralTerm(LiteralTerm term, DeserializationContext context) {
    return CustomType(term.value);
  }
}

class TestLiteralSerializer implements RdfLiteralTermSerializer<CustomType> {
  @override
  LiteralTerm toLiteralTerm(CustomType value, SerializationContext context) {
    return LiteralTerm.string(value.value);
  }
}

class TestBlankNodeDeserializer
    implements RdfBlankNodeTermDeserializer<CustomType> {
  @override
  CustomType fromBlankNodeTerm(
    BlankNodeTerm term,
    DeserializationContext context,
  ) {
    return CustomType(term.label);
  }
}

class TestSubjectDeserializer implements RdfSubjectDeserializer<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  CustomType fromIriTerm(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }
}

class TestSubjectSerializer implements RdfSubjectSerializer<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  (RdfSubject, List<Triple>) toRdfSubject(
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

class TestSubjectMapper implements RdfSubjectMapper<CustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/CustomType');

  @override
  CustomType fromIriTerm(IriTerm term, DeserializationContext context) {
    return CustomType(term.iri);
  }

  @override
  (RdfSubject, List<Triple>) toRdfSubject(
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

class AnotherTestSubjectMapper implements RdfSubjectMapper<AnotherCustomType> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/AnotherCustomType');

  @override
  AnotherCustomType fromIriTerm(IriTerm term, DeserializationContext context) {
    return AnotherCustomType(term.iri);
  }

  @override
  (RdfSubject, List<Triple>) toRdfSubject(
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

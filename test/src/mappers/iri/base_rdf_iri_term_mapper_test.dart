import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

enum TestEnum { value1, value2, specialValue }

class SimpleTestMapper extends BaseRdfIriTermMapper<TestEnum> {
  const SimpleTestMapper() : super('https://example.org/test/{value}', 'value');

  @override
  String convertToString(TestEnum value) => value.name;

  @override
  TestEnum convertFromString(String value) {
    return TestEnum.values.firstWhere((e) => e.name == value);
  }
}

class AdvancedTestMapper extends BaseRdfIriTermMapper<TestEnum> {
  final String Function() baseProvider;

  AdvancedTestMapper(this.baseProvider)
      : super('{+base}/ns/{type}/{value}', 'value');

  @override
  String resolvePlaceholder(String placeholderName) =>
      switch (placeholderName) {
        'base' => baseProvider(),
        'type' => 'enums',
        _ => super.resolvePlaceholder(placeholderName),
      };

  @override
  String convertToString(TestEnum value) => value.name;

  @override
  TestEnum convertFromString(String value) {
    return TestEnum.values.firstWhere((e) => e.name == value);
  }
}

void main() {
  group('BaseRdfIriTermMapper', () {
    late SerializationContext serializationContext;
    late DeserializationContext deserializationContext;

    setUp(() {
      serializationContext = MockSerializationContext();
      deserializationContext = MockDeserializationContext();
    });

    group('Simple template', () {
      late SimpleTestMapper mapper;

      setUp(() {
        mapper = SimpleTestMapper();
      });

      test('should serialize enum to IRI', () {
        final iri = mapper.toRdfTerm(TestEnum.value1, serializationContext);
        expect(iri.value, equals('https://example.org/test/value1'));
      });

      test('should deserialize IRI to enum', () {
        final iri = const IriTerm('https://example.org/test/specialValue');
        final value = mapper.fromRdfTerm(iri, deserializationContext);
        expect(value, equals(TestEnum.specialValue));
      });

      test('should handle roundtrip correctly', () {
        for (final originalValue in TestEnum.values) {
          final iri = mapper.toRdfTerm(originalValue, serializationContext);
          final deserializedValue =
              mapper.fromRdfTerm(iri, deserializationContext);
          expect(deserializedValue, equals(originalValue));
        }
      });

      test('should throw on invalid IRI format', () {
        final invalidIri = const IriTerm('https://other.org/test/value1');
        expect(
          () => mapper.fromRdfTerm(invalidIri, deserializationContext),
          throwsArgumentError,
        );
      });
    });

    group('Advanced template with providers', () {
      late AdvancedTestMapper mapper;
      late String baseUri;

      setUp(() {
        baseUri = 'https://mycompany.com/ontology';
        mapper = AdvancedTestMapper(() => baseUri);
      });

      test('should serialize with providers', () {
        final iri = mapper.toRdfTerm(TestEnum.value2, serializationContext);
        expect(iri.value,
            equals('https://mycompany.com/ontology/ns/enums/value2'));
      });

      test('should deserialize with providers', () {
        final iri =
            const IriTerm('https://mycompany.com/ontology/ns/enums/value1');
        final value = mapper.fromRdfTerm(iri, deserializationContext);
        expect(value, equals(TestEnum.value1));
      });

      test('should handle different base URIs', () {
        baseUri = 'http://different.org';
        final newMapper = AdvancedTestMapper(() => baseUri);

        final iri =
            newMapper.toRdfTerm(TestEnum.specialValue, serializationContext);
        expect(iri.value, equals('http://different.org/ns/enums/specialValue'));
      });
    });

    group('Validation', () {
      test('should throw when value variable not in template', () {
        const mapper = SimpleTestMapperWithBadVariable();
        final iri = const IriTerm('https://example.org/test/somevalue');
        expect(
          () => mapper.fromRdfTerm(iri, MockDeserializationContext()),
          throwsArgumentError,
        );
      });

      test('should throw when extra value missing during serialization', () {
        const mapper = TestMapperWithMissingProvider();
        expect(
          () => mapper.toRdfTerm(TestEnum.value1, MockSerializationContext()),
          throwsArgumentError,
        );
      });
    });
  });
}

class SimpleTestMapperWithBadVariable extends BaseRdfIriTermMapper<TestEnum> {
  const SimpleTestMapperWithBadVariable()
      : super('https://example.org/test/{wrong}', 'value');

  @override
  String convertToString(TestEnum value) => value.name;

  @override
  TestEnum convertFromString(String value) {
    return TestEnum.values.firstWhere((e) => e.name == value);
  }
}

class TestMapperWithMissingProvider extends BaseRdfIriTermMapper<TestEnum> {
  const TestMapperWithMissingProvider()
      : super('https://example.org/{missing}/{value}', 'value');

  @override
  String convertToString(TestEnum value) => value.name;

  @override
  TestEnum convertFromString(String value) {
    return TestEnum.values.firstWhere((e) => e.name == value);
  }
}

class MockSerializationContext implements SerializationContext {
  @override
  IriTerm createIriTerm(String value) => IriTerm(value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeserializationContext implements DeserializationContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

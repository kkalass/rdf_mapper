import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

/// Test entity with double values for testing custom datatype registration
class TestEntityWithDouble {
  final String id;
  final double temperature;
  final double weight;

  const TestEntityWithDouble({
    required this.id,
    required this.temperature,
    required this.weight,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEntityWithDouble &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          temperature == other.temperature &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(id, temperature, weight);

  @override
  String toString() =>
      'TestEntityWithDouble(id: $id, temperature: $temperature, weight: $weight)';
}

/// Wrapper types for testing multiple custom datatypes
class Temperature {
  final double celsius;
  const Temperature(this.celsius);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Temperature && celsius == other.celsius;

  @override
  int get hashCode => celsius.hashCode;

  @override
  String toString() => 'Temperature($celsius°C)';
}

class Weight {
  final double kilograms;
  const Weight(this.kilograms);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Weight && kilograms == other.kilograms;

  @override
  int get hashCode => kilograms.hashCode;

  @override
  String toString() => 'Weight(${kilograms}kg)';
}

/// Entity that uses wrapper types for different custom datatypes
class TypedEntity {
  final String id;
  final Temperature temperature;
  final Weight weight;

  const TypedEntity({
    required this.id,
    required this.temperature,
    required this.weight,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypedEntity &&
          id == other.id &&
          temperature == other.temperature &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(id, temperature, weight);

  @override
  String toString() =>
      'TypedEntity(id: $id, temperature: $temperature, weight: $weight)';
}

/// Mappers for wrapper types
const celsiusDatatype = const IriTerm('http://qudt.org/vocab/unit/CEL');
const kilogramDatatype = const IriTerm('http://qudt.org/vocab/unit/KiloGM');

class TemperatureMapper
    extends DelegatingRdfLiteralTermMapper<Temperature, double> {
  const TemperatureMapper() : super(const DoubleMapper(), celsiusDatatype);

  @override
  Temperature convertFrom(double value) => Temperature(value);

  @override
  double convertTo(Temperature value) => value.celsius;
}

class WeightMapper extends DelegatingRdfLiteralTermMapper<Weight, double> {
  const WeightMapper() : super(const DoubleMapper(), kilogramDatatype);

  @override
  Weight convertFrom(double value) => Weight(value);

  @override
  double convertTo(Weight value) => value.kilograms;
}

/// Custom mapper for TestEntityWithDouble
class TestEntityWithDoubleMapper
    implements GlobalResourceMapper<TestEntityWithDouble> {
  static final temperaturePredicate =
      const IriTerm('http://example.org/temperature');
  static final weightPredicate = const IriTerm('http://example.org/weight');

  @override
  final IriTerm typeIri =
      const IriTerm('http://example.org/TestEntityWithDouble');

  @override
  TestEntityWithDouble fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TestEntityWithDouble(
      id: subject.value,
      temperature: reader.require<double>(temperaturePredicate),
      weight: reader.require<double>(weightPredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestEntityWithDouble entity,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(entity.id))
        .addValue(temperaturePredicate, entity.temperature)
        .addValue(weightPredicate, entity.weight)
        .build();
  }
}

/// Mapper for typed entity that uses wrapper types
class TypedEntityMapper implements GlobalResourceMapper<TypedEntity> {
  static final temperaturePredicate =
      const IriTerm('http://example.org/temperature');
  static final weightPredicate = const IriTerm('http://example.org/weight');

  @override
  final IriTerm typeIri = const IriTerm('http://example.org/TypedEntity');

  @override
  TypedEntity fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return TypedEntity(
      id: subject.value,
      temperature: reader.require<Temperature>(temperaturePredicate),
      weight: reader.require<Weight>(weightPredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TypedEntity entity,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(entity.id))
        .addValue(temperaturePredicate, entity.temperature)
        .addValue(weightPredicate, entity.weight)
        .build();
  }
}

void main() {
  group('Global Mapper Registration Integration Tests', () {
    test('should handle xsd:double datatype with global registration', () {
      // Create RDF data that uses xsd:double instead of the default xsd:decimal
      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        ex:entity1 ex:temperature "23.5"^^xsd:double ;
                   ex:weight "70.2"^^xsd:double .
      ''';

      // Create mapper with custom double mapper registered globally
      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper())
        ..registerMapper<double>(
            DoubleMapper(Xsd.double))); // Use xsd:double instead of xsd:decimal

      // This should work without throwing DeserializerDatatypeMismatchException
      final entity = rdfMapper.decodeObject<TestEntityWithDouble>(rdfData);

      // Verify the values were parsed correctly
      expect(entity.id, equals('http://example.org/entity1'));
      expect(entity.temperature, equals(23.5));
      expect(entity.weight, equals(70.2));

      // Verify roundtrip consistency - should serialize back with xsd:double
      final serialized = rdfMapper.encodeObject(entity);
      expect(serialized, contains('xsd:double'));
      expect(serialized, contains('23.5'));
      expect(serialized, contains('70.2'));

      // Verify complete roundtrip
      final roundtripEntity =
          rdfMapper.decodeObject<TestEntityWithDouble>(serialized);
      expect(roundtripEntity, equals(entity));
    });

    test(
        'should throw DeserializerDatatypeMismatchException without global registration',
        () {
      // Create RDF data that uses xsd:double
      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        ex:entity1 ex:temperature "23.5"^^xsd:double ;
                   ex:weight "70.2"^^xsd:double .
      ''';

      // Create mapper WITHOUT custom double mapper registration
      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper()));
      // Note: No custom DoubleMapper registration - using default xsd:decimal

      // This should throw DeserializerDatatypeMismatchException
      expect(
        () => rdfMapper.decodeObject<TestEntityWithDouble>(rdfData),
        throwsA(isA<DeserializerDatatypeMismatchException>()),
      );
    });

    test(
        'should verify exception message contains the exact registration pattern',
        () {
      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        ex:entity1 ex:temperature "23.5"^^xsd:double .
      ''';

      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper()));

      try {
        rdfMapper.decodeObject<TestEntityWithDouble>(rdfData);
        fail('Expected DeserializerDatatypeMismatchException');
      } catch (e) {
        expect(e, isA<DeserializerDatatypeMismatchException>());
        final exception = e as DeserializerDatatypeMismatchException;
        final message = exception.toString();

        // Verify the exception message contains the exact pattern from our documentation
        expect(message,
            contains('registerMapper<double>(DoubleMapper(Xsd.double))'));
        expect(message, contains('Quick Fix during initialization'));
        expect(message, contains('affects ALL double instances'));
      }
    });

    test('should demonstrate limitation when mixing multiple custom datatypes',
        () {
      final customTempType = const IriTerm('http://qudt.org/vocab/unit/CEL');
      // Note: We're only registering one custom datatype to demonstrate the limitation

      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix unit: <http://qudt.org/vocab/unit/> .

        ex:entity1 ex:temperature "23.5"^^unit:CEL ;
                   ex:weight "70.2"^^unit:KiloGM .
      ''';

      // Test showing that global registration can only handle one datatype per Dart type
      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper())
        ..registerMapper<double>(DoubleMapper(
            customTempType))); // This will only handle CEL, not KiloGM

      // This should fail for the weight property since we only registered one custom datatype
      // This demonstrates why wrapper types are recommended for complex scenarios
      expect(
        () => rdfMapper.decodeObject<TestEntityWithDouble>(rdfData),
        throwsA(isA<DeserializerDatatypeMismatchException>()),
      );
    });

    test(
        'should demonstrate why wrapper types are recommended over global registration',
        () {
      // This test shows the problem that wrapper types solve:
      // mixing different datatypes in the same entity is problematic with global registration

      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        ex:entity1 ex:temperature "23.5"^^xsd:double ;
                   ex:weight "70.2"^^xsd:decimal .
      ''';

      // Using default registration (no custom double mapper)
      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper()));

      // This demonstrates that mixing different datatypes in the same entity
      // is problematic with global registration - the wrapper type approach
      // would be better for this scenario
      expect(
        () => rdfMapper.decodeObject<TestEntityWithDouble>(rdfData),
        throwsA(isA<DeserializerDatatypeMismatchException>()),
      );
    });

    test('should handle edge cases in global registration', () {
      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        ex:entity1 ex:temperature "0.0"^^xsd:double ;
                   ex:weight "-1.5"^^xsd:double .
      ''';

      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TestEntityWithDouble>(TestEntityWithDoubleMapper())
        ..registerMapper<double>(DoubleMapper(Xsd.double)));

      final entity = rdfMapper.decodeObject<TestEntityWithDouble>(rdfData);

      expect(entity.temperature, equals(0.0));
      expect(entity.weight, equals(-1.5));

      // Verify roundtrip with edge values
      final serialized = rdfMapper.encodeObject(entity);
      final roundtripEntity =
          rdfMapper.decodeObject<TestEntityWithDouble>(serialized);
      expect(roundtripEntity, equals(entity));
    });

    test('should work with multiple custom datatypes using wrapper types', () {
      // This test demonstrates the recommended approach for handling multiple custom datatypes

      final rdfData = '''
        @prefix ex: <http://example.org/> .
        @prefix unit: <http://qudt.org/vocab/unit/> .

        ex:entity1 ex:temperature "23.5"^^unit:CEL ;
                   ex:weight "70.2"^^unit:KiloGM .
      ''';

      // Register all the wrapper type mappers
      final rdfMapper = RdfMapper.withMappers((registry) => registry
        ..registerMapper<TypedEntity>(TypedEntityMapper())
        ..registerMapper<Temperature>(TemperatureMapper())
        ..registerMapper<Weight>(WeightMapper()));

      // This should work because each wrapper type has its own specific datatype
      final entity = rdfMapper.decodeObject<TypedEntity>(rdfData);

      expect(entity.id, equals('http://example.org/entity1'));
      expect(entity.temperature.celsius, equals(23.5));
      expect(entity.weight.kilograms, equals(70.2));

      // Verify roundtrip with different datatypes
      final serialized = rdfMapper.encodeObject(entity);
      expect(serialized, contains('unit:CEL'));
      expect(serialized, contains('unit:KiloGM'));

      final roundtripEntity = rdfMapper.decodeObject<TypedEntity>(serialized);
      expect(roundtripEntity, equals(entity));
    });
  });
}

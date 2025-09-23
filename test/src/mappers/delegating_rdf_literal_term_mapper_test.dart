import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

/// Example custom wrapper class for testing
class MyCustomDouble {
  final double value;
  const MyCustomDouble(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyCustomDouble &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MyCustomDouble($value)';
}

/// Example delegating mapper implementation
class MyCustomDoubleMapper
    extends DelegatingRdfLiteralTermMapper<MyCustomDouble, double> {
  const MyCustomDoubleMapper([IriTerm? datatype])
      : super(const DoubleMapper(), datatype ?? Xsd.double);

  @override
  MyCustomDouble convertFrom(double value) => MyCustomDouble(value);

  @override
  double convertTo(MyCustomDouble value) => value.value;
}

void main() {
  group('DelegatingRdfLiteralTermMapper', () {
    late MyCustomDoubleMapper mapper;
    late MockDeserializationContext deserializationContext;
    late MockSerializationContext serializationContext;

    setUp(() {
      mapper = const MyCustomDoubleMapper();
      deserializationContext = MockDeserializationContext();
      serializationContext = MockSerializationContext();
    });

    group('deserialization', () {
      test('successfully deserializes with correct datatype', () {
        final term = LiteralTerm('3.14159', datatype: Xsd.double);

        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(MyCustomDouble(3.14159)));
        expect(result.value, equals(3.14159));
      });

      test('throws DeserializerDatatypeMismatchException on wrong datatype',
          () {
        final term = LiteralTerm('3.14159', datatype: Xsd.string);

        expect(
          () => mapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == Xsd.double &&
                  e.targetType == MyCustomDouble &&
                  e.mapperRuntimeType == MyCustomDoubleMapper),
            ),
          ),
        );
      });

      test('bypasses datatype check when bypassDatatypeCheck=true', () {
        final term = LiteralTerm('2.71828', datatype: Xsd.string);

        // Should not throw when bypassing datatype check
        expect(
          () => mapper.fromRdfTerm(term, deserializationContext,
              bypassDatatypeCheck: true),
          returnsNormally,
        );

        // Should return the converted value
        final result = mapper.fromRdfTerm(term, deserializationContext,
            bypassDatatypeCheck: true);
        expect(result, equals(MyCustomDouble(2.71828)));
      });

      test('throws DeserializationException on conversion failure', () {
        final term = LiteralTerm('not-a-number', datatype: Xsd.double);

        expect(
          () => mapper.fromRdfTerm(term, deserializationContext),
          throwsA(isA<DeserializationException>()),
        );
      });
    });

    group('serialization', () {
      test('successfully serializes custom type to RDF term', () {
        final customValue = MyCustomDouble(42.0);

        final result = mapper.toRdfTerm(customValue, serializationContext);

        expect(result.value, equals('42.0'));
        expect(result.datatype, equals(Xsd.double));
      });

      test('preserves custom datatype during serialization', () {
        final customDatatype =
            const IriTerm('http://example.org/my-double-type');
        final customMapper = MyCustomDoubleMapper(customDatatype);
        final customValue = MyCustomDouble(123.456);

        final result =
            customMapper.toRdfTerm(customValue, serializationContext);

        expect(result.value, equals('123.456'));
        expect(result.datatype, equals(customDatatype));
      });
    });

    group('custom datatype handling', () {
      test('works with custom datatype for deserialization', () {
        final customDatatype =
            const IriTerm('http://example.org/my-double-type');
        final customMapper = MyCustomDoubleMapper(customDatatype);
        final term = LiteralTerm('9.876', datatype: customDatatype);

        final result = customMapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(MyCustomDouble(9.876)));
      });

      test('throws exception with wrong custom datatype', () {
        final customDatatype =
            const IriTerm('http://example.org/my-double-type');
        final otherDatatype =
            const IriTerm('http://example.org/other-double-type');
        final customMapper = MyCustomDoubleMapper(customDatatype);
        final term = LiteralTerm('9.876', datatype: otherDatatype);

        expect(
          () => customMapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == otherDatatype &&
                  e.expected == customDatatype &&
                  e.targetType == MyCustomDouble),
            ),
          ),
        );
      });
    });

    group('roundtrip consistency', () {
      test('maintains value through serialize-deserialize cycle', () {
        final originalValue = MyCustomDouble(3.141592653589793);

        // Serialize to RDF term
        final term = mapper.toRdfTerm(originalValue, serializationContext);

        // Deserialize back to custom type
        final deserializedValue =
            mapper.fromRdfTerm(term, deserializationContext);

        expect(deserializedValue, equals(originalValue));
        expect(deserializedValue.value, equals(originalValue.value));
      });

      test('maintains custom datatype through roundtrip', () {
        final customDatatype =
            const IriTerm('http://example.org/my-special-double');
        final customMapper = MyCustomDoubleMapper(customDatatype);
        final originalValue = MyCustomDouble(2.718281828);

        // Serialize to RDF term
        final term =
            customMapper.toRdfTerm(originalValue, serializationContext);
        expect(term.datatype, equals(customDatatype));

        // Deserialize back to custom type
        final deserializedValue =
            customMapper.fromRdfTerm(term, deserializationContext);

        expect(deserializedValue, equals(originalValue));
        expect(deserializedValue.value, equals(originalValue.value));
      });
    });

    group('edge cases', () {
      test('handles zero value correctly', () {
        final zeroValue = MyCustomDouble(0.0);

        final term = mapper.toRdfTerm(zeroValue, serializationContext);
        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(zeroValue));
      });

      test('handles negative values correctly', () {
        final negativeValue = MyCustomDouble(-42.5);

        final term = mapper.toRdfTerm(negativeValue, serializationContext);
        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(negativeValue));
      });

      test('handles very large values correctly', () {
        final largeValue = MyCustomDouble(1.7976931348623157e+308);

        final term = mapper.toRdfTerm(largeValue, serializationContext);
        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(largeValue));
      });

      test('handles very small values correctly', () {
        final smallValue = MyCustomDouble(2.2250738585072014e-308);

        final term = mapper.toRdfTerm(smallValue, serializationContext);
        final result = mapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(smallValue));
      });
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/literal/bool_mapper.dart';
import 'package:rdf_mapper/src/mappers/literal/date_mapper.dart';
import 'package:rdf_mapper/src/mappers/literal/date_time_mapper.dart';
import 'package:rdf_mapper/src/mappers/literal/double_mapper.dart';
import 'package:rdf_mapper/src/mappers/literal/int_mapper.dart';
import 'package:rdf_mapper/src/mappers/literal/string_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

void main() {
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
    deserializationContext = MockDeserializationContext();
  });

  group('Standard Mappers', () {
    group('String Mapper', () {
      test('StringSerializer correctly serializes strings to RDF literals', () {
        final serializer = const StringMapper();

        final literal = serializer.toRdfTerm(
          'Hello, World!',
          serializationContext,
        );

        expect(literal, isA<LiteralTerm>());
        expect(literal.value, equals('Hello, World!'));
        expect(literal.datatype, equals(Xsd.string));
        expect(literal.language, isNull);
      });

      test(
        'StringDeserializer correctly deserializes RDF literals to strings',
        () {
          final deserializer = const StringMapper();

          final string = deserializer.fromRdfTerm(
            LiteralTerm.string('Hello, World!'),
            deserializationContext,
          );

          expect(string, equals('Hello, World!'));
        },
      );

      test(
        'StringDeserializer by default rejects language-tagged literals',
        () {
          final deserializer = const StringMapper();

          expect(
            () => deserializer.fromRdfTerm(
              LiteralTerm.withLanguage('Hallo, Welt!', 'de'),
              deserializationContext,
            ),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        'StringDeserializer with acceptLangString=true handles language-tagged literals',
        () {
          final deserializer =
              const StringMapper(null, /*acceptLangString:*/ true);

          final string = deserializer.fromRdfTerm(
            LiteralTerm.withLanguage('Hallo, Welt!', 'de'),
            deserializationContext,
          );

          expect(string, equals('Hallo, Welt!'));
        },
      );

      test(
        'StringDeserializer with custom datatype accepts only that datatype',
        () {
          const customDatatype =
              const IriTerm('http://example.org/customString');
          final deserializer = const StringMapper(customDatatype);

          final customLiteral = LiteralTerm(
            'Custom string',
            datatype: customDatatype,
          );

          expect(
            deserializer.fromRdfTerm(customLiteral, deserializationContext),
            equals('Custom string'),
          );

          expect(
            () => deserializer.fromRdfTerm(
              LiteralTerm.string('Standard string'),
              deserializationContext,
            ),
            throwsA(isA<Exception>()),
          );
        },
      );
    });

    group('Integer Mapper', () {
      test('IntSerializer correctly serializes integers to RDF literals', () {
        final serializer = const IntMapper();

        final literal = serializer.toRdfTerm(42, serializationContext);

        expect(literal, isA<LiteralTerm>());
        expect(literal.value, equals('42'));
        expect(literal.datatype, equals(Xsd.integer));
      });

      test(
        'IntDeserializer correctly deserializes RDF literals to integers',
        () {
          final deserializer = const IntMapper();

          final int1 = deserializer.fromRdfTerm(
            LiteralTerm.typed('42', 'integer'),
            deserializationContext,
          );

          final int2 = deserializer.fromRdfTerm(
            LiteralTerm.typed('-123', 'integer'),
            deserializationContext,
          );

          expect(int1, equals(42));
          expect(int2, equals(-123));
        },
      );
    });

    group('Boolean Mapper', () {
      test('BoolSerializer correctly serializes booleans to RDF literals', () {
        final serializer = const BoolMapper();

        final trueLiteral = serializer.toRdfTerm(true, serializationContext);
        final falseLiteral = serializer.toRdfTerm(false, serializationContext);

        expect(trueLiteral.value, equals('true'));
        expect(trueLiteral.datatype, equals(Xsd.boolean));

        expect(falseLiteral.value, equals('false'));
        expect(falseLiteral.datatype, equals(Xsd.boolean));
      });

      test(
        'BoolDeserializer correctly deserializes RDF literals to booleans',
        () {
          final deserializer = const BoolMapper();

          final trueValue = deserializer.fromRdfTerm(
            LiteralTerm.typed('true', 'boolean'),
            deserializationContext,
          );

          final falseValue = deserializer.fromRdfTerm(
            LiteralTerm.typed('false', 'boolean'),
            deserializationContext,
          );

          // Test for "1" and "0" as boolean values
          final oneValue = deserializer.fromRdfTerm(
            LiteralTerm.typed('1', 'boolean'),
            deserializationContext,
          );

          final zeroValue = deserializer.fromRdfTerm(
            LiteralTerm.typed('0', 'boolean'),
            deserializationContext,
          );

          expect(trueValue, isTrue);
          expect(falseValue, isFalse);
          expect(oneValue, isTrue);
          expect(zeroValue, isFalse);
        },
      );
    });

    group('Double Mapper', () {
      test('DoubleSerializer correctly serializes doubles to RDF literals', () {
        final serializer = const DoubleMapper();

        final literal1 = serializer.toRdfTerm(3.14159, serializationContext);
        final literal2 = serializer.toRdfTerm(-0.5, serializationContext);

        expect(literal1.value, equals('3.14159'));
        expect(literal1.datatype, equals(Xsd.decimal));

        expect(literal2.value, equals('-0.5'));
        expect(literal2.datatype, equals(Xsd.decimal));
      });

      test(
        'DoubleDeserializer correctly deserializes RDF literals to doubles',
        () {
          final deserializer = const DoubleMapper();

          final double1 = deserializer.fromRdfTerm(
            LiteralTerm.typed('3.14159', 'decimal'),
            deserializationContext,
          );

          final double2 = deserializer.fromRdfTerm(
            LiteralTerm.typed('-0.5', 'decimal'),
            deserializationContext,
          );

          expect(double1, equals(3.14159));
          expect(double2, equals(-0.5));
        },
      );
    });

    group('DateTime Mapper', () {
      test(
        'DateTimeSerializer correctly serializes DateTimes to RDF literals',
        () {
          final serializer = const DateTimeMapper();

          final dateTime = DateTime.utc(2023, 4, 1, 12, 30, 45);
          final literal = serializer.toRdfTerm(dateTime, serializationContext);

          expect(literal.value, equals('2023-04-01T12:30:45.000Z'));
          expect(literal.datatype, equals(Xsd.dateTime));
        },
      );

      test(
        'DateTimeDeserializer correctly deserializes RDF literals to DateTimes',
        () {
          final deserializer = const DateTimeMapper();

          final dateTime = deserializer.fromRdfTerm(
            LiteralTerm.typed('2023-04-01T12:30:45.000Z', 'dateTime'),
            deserializationContext,
          );

          expect(dateTime, equals(DateTime.utc(2023, 4, 1, 12, 30, 45)));
        },
      );
    });

    group('Date Mapper', () {
      test(
        'DateSerializer correctly serializes Dates to RDF literals',
        () {
          final serializer = const DateMapper();

          final dateTime = DateTime.utc(2023, 4, 1, 12, 30, 45);
          final literal = serializer.toRdfTerm(dateTime, serializationContext);

          expect(literal.value, equals('2023-04-01'));
          expect(literal.datatype, equals(Xsd.date));
        },
      );

      test(
        'DateDeserializer correctly deserializes RDF literals to DateTimes',
        () {
          final deserializer = const DateMapper();

          final dateTime = deserializer.fromRdfTerm(
            LiteralTerm.typed('2023-04-01', 'date'),
            deserializationContext,
          );

          expect(dateTime, equals(DateTime.utc(2023, 4, 1)));
        },
      );
    });
  });
}

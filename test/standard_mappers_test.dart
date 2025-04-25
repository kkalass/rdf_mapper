import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/serialization_context.dart';
import 'package:rdf_mapper/standard_mappers/bool_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/bool_serializer.dart';
import 'package:rdf_mapper/standard_mappers/date_time_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/date_time_serializer.dart';
import 'package:rdf_mapper/standard_mappers/double_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/double_serializer.dart';
import 'package:rdf_mapper/standard_mappers/int_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/int_serializer.dart';
import 'package:rdf_mapper/standard_mappers/string_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/string_serializer.dart';
import 'package:test/test.dart';

// Mock implementation of SerializationContext for testing
class MockSerializationContext extends SerializationContext {
  @override
  List<Triple> childSubject<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    serializer,
  }) {
    throw UnimplementedError();
  }

  @override
  Triple constant(
    RdfSubject subject,
    RdfPredicate predicate,
    RdfObject object,
  ) {
    throw UnimplementedError();
  }

  @override
  Triple iri<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    serializer,
  }) {
    throw UnimplementedError();
  }

  @override
  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    serializer,
  }) {
    throw UnimplementedError();
  }

  @override
  (RdfSubject, List<Triple>) subject<T>(T instance, {serializer}) {
    throw UnimplementedError();
  }
}

// Mock implementation of DeserializationContext for testing
class MockDeserializationContext extends DeserializationContext {
  @override
  T getRequiredPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    subjectDeserializer,
    iriDeserializer,
    literalDeserializer,
    blankNodeDeserializer,
  }) {
    throw UnimplementedError();
  }

  @override
  T? getPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    subjectDeserializer,
    iriDeserializer,
    literalDeserializer,
    blankNodeDeserializer,
  }) {
    throw UnimplementedError();
  }

  @override
  R getPropertyValues<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    subjectDeserializer,
    iriDeserializer,
    literalDeserializer,
    blankNodeDeserializer,
  }) {
    throw UnimplementedError();
  }
}

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
        final serializer = StringSerializer();

        final literal = serializer.toLiteralTerm(
          'Hello, World!',
          serializationContext,
        );

        expect(literal, isA<LiteralTerm>());
        expect(literal.value, equals('Hello, World!'));
        expect(literal.datatype, equals(XsdConstants.stringIri));
        expect(literal.language, isNull);
      });

      test(
        'StringDeserializer correctly deserializes RDF literals to strings',
        () {
          final deserializer = StringDeserializer();

          final string = deserializer.fromLiteralTerm(
            LiteralTerm.string('Hello, World!'),
            deserializationContext,
          );

          expect(string, equals('Hello, World!'));
        },
      );

      test(
        'StringDeserializer by default rejects language-tagged literals',
        () {
          final deserializer = StringDeserializer();

          expect(
            () => deserializer.fromLiteralTerm(
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
          final deserializer = StringDeserializer(acceptLangString: true);

          final string = deserializer.fromLiteralTerm(
            LiteralTerm.withLanguage('Hallo, Welt!', 'de'),
            deserializationContext,
          );

          expect(string, equals('Hallo, Welt!'));
        },
      );

      test(
        'StringDeserializer with custom datatype accepts only that datatype',
        () {
          final customDatatype = IriTerm('http://example.org/customString');
          final deserializer = StringDeserializer(datatype: customDatatype);

          final customLiteral = LiteralTerm(
            'Custom string',
            datatype: customDatatype,
          );

          expect(
            deserializer.fromLiteralTerm(customLiteral, deserializationContext),
            equals('Custom string'),
          );

          expect(
            () => deserializer.fromLiteralTerm(
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
        final serializer = IntSerializer();

        final literal = serializer.toLiteralTerm(42, serializationContext);

        expect(literal, isA<LiteralTerm>());
        expect(literal.value, equals('42'));
        expect(literal.datatype, equals(XsdConstants.integerIri));
      });

      test(
        'IntDeserializer correctly deserializes RDF literals to integers',
        () {
          final deserializer = IntDeserializer();

          final int1 = deserializer.fromLiteralTerm(
            LiteralTerm.typed('42', 'integer'),
            deserializationContext,
          );

          final int2 = deserializer.fromLiteralTerm(
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
        final serializer = BoolSerializer();

        final trueLiteral = serializer.toLiteralTerm(
          true,
          serializationContext,
        );
        final falseLiteral = serializer.toLiteralTerm(
          false,
          serializationContext,
        );

        expect(trueLiteral.value, equals('true'));
        expect(trueLiteral.datatype, equals(XsdConstants.booleanIri));

        expect(falseLiteral.value, equals('false'));
        expect(falseLiteral.datatype, equals(XsdConstants.booleanIri));
      });

      test(
        'BoolDeserializer correctly deserializes RDF literals to booleans',
        () {
          final deserializer = BoolDeserializer();

          final trueValue = deserializer.fromLiteralTerm(
            LiteralTerm.typed('true', 'boolean'),
            deserializationContext,
          );

          final falseValue = deserializer.fromLiteralTerm(
            LiteralTerm.typed('false', 'boolean'),
            deserializationContext,
          );

          // Test for "1" and "0" as boolean values
          final oneValue = deserializer.fromLiteralTerm(
            LiteralTerm.typed('1', 'boolean'),
            deserializationContext,
          );

          final zeroValue = deserializer.fromLiteralTerm(
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
        final serializer = DoubleSerializer();

        final literal1 = serializer.toLiteralTerm(
          3.14159,
          serializationContext,
        );
        final literal2 = serializer.toLiteralTerm(-0.5, serializationContext);

        expect(literal1.value, equals('3.14159'));
        expect(literal1.datatype, equals(XsdConstants.decimalIri));

        expect(literal2.value, equals('-0.5'));
        expect(literal2.datatype, equals(XsdConstants.decimalIri));
      });

      test(
        'DoubleDeserializer correctly deserializes RDF literals to doubles',
        () {
          final deserializer = DoubleDeserializer();

          final double1 = deserializer.fromLiteralTerm(
            LiteralTerm.typed('3.14159', 'decimal'),
            deserializationContext,
          );

          final double2 = deserializer.fromLiteralTerm(
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
          final serializer = DateTimeSerializer();

          final dateTime = DateTime.utc(2023, 4, 1, 12, 30, 45);
          final literal = serializer.toLiteralTerm(
            dateTime,
            serializationContext,
          );

          expect(literal.value, equals('2023-04-01T12:30:45.000Z'));
          expect(literal.datatype, equals(XsdConstants.dateTimeIri));
        },
      );

      test(
        'DateTimeDeserializer correctly deserializes RDF literals to DateTimes',
        () {
          final deserializer = DateTimeDeserializer();

          final dateTime = deserializer.fromLiteralTerm(
            LiteralTerm.typed('2023-04-01T12:30:45.000Z', 'dateTime'),
            deserializationContext,
          );

          expect(dateTime, equals(DateTime.utc(2023, 4, 1, 12, 30, 45)));
        },
      );
    });
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/mappers/literal/date_mapper.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
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

  group('DateMapper', () {
    group('Serialization', () {
      test('serializes DateTime to xsd:date format (YYYY-MM-DD)', () {
        final mapper = const DateMapper();
        final dateTime = DateTime.utc(2023, 12, 25);

        final literal = mapper.toRdfTerm(dateTime, serializationContext);

        expect(literal, isA<LiteralTerm>());
        expect(literal.value, equals('2023-12-25'));
        expect(literal.datatype, equals(Xsd.date));
        expect(literal.language, isNull);
      });

      test('serializes DateTime with time components to date-only format', () {
        final mapper = const DateMapper();
        final dateTime = DateTime.utc(2023, 5, 15, 14, 30, 45);

        final literal = mapper.toRdfTerm(dateTime, serializationContext);

        expect(literal.value, equals('2023-05-15'));
        expect(literal.datatype, equals(Xsd.date));
      });

      test('handles single-digit months and days with zero padding', () {
        final mapper = const DateMapper();
        final dateTime = DateTime.utc(2023, 1, 5);

        final literal = mapper.toRdfTerm(dateTime, serializationContext);

        expect(literal.value, equals('2023-01-05'));
      });

      test('converts non-UTC DateTime to UTC before serialization', () {
        final mapper = const DateMapper();
        // Create a DateTime in a different timezone (should be converted to UTC)
        final localDateTime = DateTime(2023, 12, 25, 15, 30);

        final literal = mapper.toRdfTerm(localDateTime, serializationContext);

        // Should extract date from UTC representation
        final expectedDate = localDateTime.toUtc();
        final year = expectedDate.year.toString().padLeft(4, '0');
        final month = expectedDate.month.toString().padLeft(2, '0');
        final day = expectedDate.day.toString().padLeft(2, '0');
        expect(literal.value, equals('$year-$month-$day'));
      });

      test('handles year padding for years less than 1000', () {
        final mapper = const DateMapper();
        final dateTime = DateTime.utc(123, 5, 15);

        final literal = mapper.toRdfTerm(dateTime, serializationContext);

        expect(literal.value, equals('0123-05-15'));
      });
    });

    group('Deserialization', () {
      test('deserializes valid xsd:date format to DateTime', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-12-25', datatype: Xsd.date);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(2023, 12, 25)));
        expect(dateTime.isUtc, isTrue);
        expect(dateTime.hour, equals(0));
        expect(dateTime.minute, equals(0));
        expect(dateTime.second, equals(0));
        expect(dateTime.millisecond, equals(0));
      });

      test('handles single-digit months and days correctly', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-01-05', datatype: Xsd.date);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(2023, 1, 5)));
      });

      test('handles leap year dates correctly', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2024-02-29', datatype: Xsd.date);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(2024, 2, 29)));
      });

      test('handles years with leading zeros', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('0123-05-15', datatype: Xsd.date);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(123, 5, 15)));
      });

      test('handles dates with whitespace correctly', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('  2023-12-25  ', datatype: Xsd.date);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(2023, 12, 25)));
      });
    });

    group('Error Handling', () {
      test('throws DeserializationException for invalid date format', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('invalid-date', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid date format'),
          )),
        );
      });

      test('throws DeserializationException for wrong number of date parts',
          () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-12', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid date format'),
          )),
        );
      });

      test('throws DeserializationException for non-numeric date parts', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-ab-25', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Failed to parse date'),
          )),
        );
      });

      test('throws DeserializationException for invalid date values', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-13-32', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid month'),
          )),
        );
      });

      test('throws DeserializationException for February 30th', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-02-30', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Date does not exist in calendar'),
          )),
        );
      });

      test('throws DeserializationException for February 29th in non-leap year',
          () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-02-29', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Date does not exist in calendar'),
          )),
        );
      });

      test('throws DeserializationException for month 0', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-00-15', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid month'),
          )),
        );
      });

      test('throws DeserializationException for day 0', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-05-00', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid day'),
          )),
        );
      });

      test('throws DeserializationException for day 32', () {
        final mapper = const DateMapper();
        final literal = LiteralTerm('2023-05-32', datatype: Xsd.date);

        expect(
          () => mapper.fromRdfTerm(literal, deserializationContext),
          throwsA(isA<DeserializationException>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid day'),
          )),
        );
      });
    });

    group('Custom Datatype', () {
      test('works with custom datatype', () {
        const customDatatype = const IriTerm('http://example.org/customDate');
        final mapper = const DateMapper(customDatatype);

        final dateTime = DateTime.utc(2023, 12, 25);
        final literal = mapper.toRdfTerm(dateTime, serializationContext);

        expect(literal.value, equals('2023-12-25'));
        expect(literal.datatype, equals(customDatatype));
      });

      test('deserializes with custom datatype', () {
        const customDatatype = const IriTerm('http://example.org/customDate');
        final mapper = const DateMapper(customDatatype);
        final literal = LiteralTerm('2023-12-25', datatype: customDatatype);

        final dateTime = mapper.fromRdfTerm(literal, deserializationContext);

        expect(dateTime, equals(DateTime.utc(2023, 12, 25)));
      });
    });

    group('Roundtrip Tests', () {
      test('serialization and deserialization are consistent', () {
        final mapper = const DateMapper();
        final originalDate = DateTime.utc(2023, 12, 25);

        // Serialize
        final literal = mapper.toRdfTerm(originalDate, serializationContext);

        // Deserialize
        final deserializedDate =
            mapper.fromRdfTerm(literal, deserializationContext);

        expect(deserializedDate, equals(originalDate));
      });

      test('roundtrip works with various dates', () {
        final mapper = const DateMapper();
        final testDates = [
          DateTime.utc(1, 1, 1),
          DateTime.utc(123, 5, 15),
          DateTime.utc(1999, 12, 31),
          DateTime.utc(2000, 1, 1),
          DateTime.utc(2024, 2, 29), // Leap year
          DateTime.utc(2023, 7, 4),
          DateTime.utc(9999, 12, 31),
        ];

        for (final testDate in testDates) {
          final literal = mapper.toRdfTerm(testDate, serializationContext);
          final deserializedDate =
              mapper.fromRdfTerm(literal, deserializationContext);

          expect(
            deserializedDate,
            equals(testDate),
            reason: 'Failed roundtrip for date: $testDate',
          );
        }
      });

      test('roundtrip ignores time components', () {
        final mapper = const DateMapper();
        final dateTimeWithTime = DateTime.utc(2023, 12, 25, 14, 30, 45, 123);
        final expectedDate = DateTime.utc(2023, 12, 25);

        // Serialize (should strip time)
        final literal =
            mapper.toRdfTerm(dateTimeWithTime, serializationContext);
        expect(literal.value, equals('2023-12-25'));

        // Deserialize (should create date at midnight)
        final deserializedDate =
            mapper.fromRdfTerm(literal, deserializationContext);
        expect(deserializedDate, equals(expectedDate));
      });
    });
  });
}

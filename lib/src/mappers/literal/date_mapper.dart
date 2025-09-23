import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

/// Mapper for converting between Dart `DateTime` values and RDF date literals.
///
/// This mapper handles the conversion between Dart's `DateTime` type and RDF literals
/// with `xsd:date` datatype by default. It represents dates without time components
/// in the format YYYY-MM-DD.
///
/// ## Important Notes
/// - **Dart Type**: `DateTime` (time components are normalized to midnight UTC)
/// - **Default RDF Datatype**: `xsd:date`
/// - **Format**: YYYY-MM-DD (ISO 8601 date format without time)
/// - **Timezone Handling**: All dates are normalized to UTC midnight
///
/// ## Usage Considerations
///
/// Since Dart doesn't have a dedicated Date-only type, this mapper uses `DateTime`
/// but normalizes all time components to midnight UTC. When deserializing, the
/// resulting `DateTime` will always have time set to 00:00:00.000Z.
///
/// ```dart
/// final mapper = DateMapper();
///
/// // Serialization: DateTime -> "2023-12-25"
/// final dateTime = DateTime(2023, 12, 25);
/// final rdfTerm = mapper.toRdfTerm(dateTime, context);
/// print(rdfTerm.value); // "2023-12-25"
///
/// // Deserialization: "2023-12-25" -> DateTime
/// final literal = LiteralTerm("2023-12-25", datatype: Xsd.date);
/// final parsed = mapper.fromRdfTerm(literal, context);
/// print(parsed); // 2023-12-25 00:00:00.000Z
/// ```
///
/// ## Custom Datatype Usage
///
/// For RDF data using custom date datatypes:
///
/// ```dart
/// final customDatatype = const IriTerm('http://example.org/custom-date');
/// final customMapper = DateMapper(customDatatype);
/// ```
///
/// ## Example RDF Mapping
///
/// ```turtle
/// @prefix ex: <http://example.org/> .
/// @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
///
/// ex:birthDate "1990-05-15"^^xsd:date .
/// ex:eventDate "2023-12-31"^^xsd:date .
/// ```
final class DateMapper extends BaseRdfLiteralTermMapper<DateTime> {
  /// Creates a date mapper with the specified datatype.
  ///
  /// [datatype] The RDF datatype to use. Defaults to `xsd:date`.
  const DateMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.date,
        );

  @override
  convertFromLiteral(term, _) {
    final dateString = term.value.trim();

    // Parse xsd:date format: YYYY-MM-DD
    final dateParts = dateString.split('-');
    if (dateParts.length != 3) {
      throw DeserializationException(
        'Invalid date format: ${term.value}. Expected YYYY-MM-DD format.',
      );
    }

    try {
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Validate month range
      if (month < 1 || month > 12) {
        throw DeserializationException(
          'Invalid month: $month. Must be between 1 and 12.',
        );
      }

      // Validate day range
      if (day < 1 || day > 31) {
        throw DeserializationException(
          'Invalid day: $day. Must be between 1 and 31.',
        );
      }

      // Create DateTime at midnight UTC
      final dateTime = DateTime.utc(year, month, day);

      // Validate that the date wasn't rolled over (e.g., Feb 30 -> Mar 2)
      if (dateTime.year != year ||
          dateTime.month != month ||
          dateTime.day != day) {
        throw DeserializationException(
          'Invalid date: ${term.value}. Date does not exist in calendar.',
        );
      }

      return dateTime;
    } catch (e) {
      if (e is DeserializationException) {
        rethrow;
      }
      throw DeserializationException(
        'Failed to parse date: ${term.value}. Error: $e',
      );
    }
  }

  @override
  convertToString(dateTime) {
    // Convert to UTC and format as YYYY-MM-DD
    final utc = dateTime.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

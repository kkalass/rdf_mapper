import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

/// Standard serializer for converting Dart DateTime objects to RDF dateTime literals.
///
/// This serializer creates RDF literals with the xsd:dateTime datatype by default.
/// It converts DateTime values to ISO 8601 formatted strings in UTC timezone to
/// ensure consistent representation across different systems.
///
/// This serializer is pre-registered in the default registry and is automatically
/// used for serializing DateTime objects to RDF.
///
/// Example:
/// ```dart
/// // Default usage with xsd:dateTime datatype
/// final dateTimeSerializer = DateTimeSerializer();
///
/// // Using xsd:date datatype instead (will still use full ISO format)
/// final dateSerializer = DateTimeSerializer(
///   datatype: Xsd.date
/// );
/// ```
final class DateTimeSerializer extends BaseRdfLiteralTermSerializer<DateTime> {
  /// Creates a new DateTime serializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:dateTime)
  DateTimeSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? Xsd.dateTime,
        convertToString: (dateTime) => dateTime.toUtc().toIso8601String(),
      );
}

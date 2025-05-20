import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';
import 'package:rdf_vocabularies/xsd.dart';

/// Standard deserializer for converting RDF dateTime literals to Dart DateTime objects.
///
/// This deserializer processes RDF literals with the xsd:dateTime datatype by default.
/// It parses ISO 8601 formatted date strings and converts them to DateTime objects
/// in UTC timezone to ensure consistent behavior across systems.
///
/// This deserializer is pre-registered in the default registry and is automatically
/// used for deserializing dateTime literals in RDF data.
///
/// Example:
/// ```dart
/// // Default usage - accepts xsd:dateTime
/// final dateTimeDeserializer = DateTimeDeserializer();
///
/// // Accept xsd:date instead
/// final dateDeserializer = DateTimeDeserializer(datatype: Xsd.date);
/// ```
final class DateTimeDeserializer
    extends BaseRdfLiteralTermDeserializer<DateTime> {
  /// Creates a new DateTime deserializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:dateTime)
  DateTimeDeserializer({IriTerm? datatype})
      : super(
          datatype: datatype ?? Xsd.dateTime,
          convertFromLiteral: (term, _) => DateTime.parse(term.value).toUtc(),
        );
}

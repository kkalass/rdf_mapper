import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';

/// Standard deserializer for converting RDF decimal/double literals to Dart double values.
///
/// This deserializer processes RDF literals with the xsd:decimal datatype by default.
/// It can be configured to accept other numeric datatypes such as xsd:double or xsd:float
/// by providing a custom datatype.
///
/// This deserializer is pre-registered in the default registry and is automatically
/// used for deserializing decimal literals in RDF data.
///
/// Note: By default, this deserializer expects the xsd:decimal datatype, but it can
/// be configured to handle other floating-point datatypes like xsd:double or xsd:float.
///
/// Example:
/// ```dart
/// // Default usage - accepts xsd:decimal
/// final decimalDeserializer = DoubleDeserializer();
///
/// // Accept xsd:double instead
/// final doubleDeserializer = DoubleDeserializer(datatype: Xsd.double);
/// ```
final class DoubleDeserializer extends BaseRdfLiteralTermDeserializer<double> {
  /// Creates a new double deserializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:decimal)
  DoubleDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? Xsd.decimal,
        convertFromLiteral: (term, _) => double.parse(term.value),
      );
}

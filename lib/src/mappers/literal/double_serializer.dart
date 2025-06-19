import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

/// Standard serializer for converting Dart double values to RDF decimal literals.
///
/// This serializer creates RDF literals with the xsd:decimal datatype by default.
/// It converts Dart double values to their string representation using the
/// built-in toString() method.
///
/// This serializer is pre-registered in the default registry and is automatically
/// used for serializing double values to RDF.
///
/// Note: The default XSD datatype used is xsd:decimal, not xsd:double, as decimal
/// is more commonly used in RDF data. Use the optional datatype parameter to
/// specify Xsd.double if that datatype is preferred.
///
/// Example:
/// ```dart
/// // Default usage with xsd:decimal datatype
/// final decimalSerializer = DoubleSerializer();
///
/// // Using xsd:double datatype instead
/// final doubleSerializer = DoubleSerializer(
///   datatype: Xsd.double
/// );
/// ```
final class DoubleSerializer extends BaseRdfLiteralTermSerializer<double> {
  /// Creates a new double serializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:decimal)
  const DoubleSerializer({IriTerm? datatype})
      : super(
          datatype: datatype ?? Xsd.decimal,
        );

  @override
  convertToString(d) => d.toString();
}

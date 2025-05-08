import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';
import 'package:rdf_vocabularies/xsd.dart';

/// Standard deserializer for converting RDF boolean literals to Dart boolean values.
///
/// This deserializer processes RDF literals with the xsd:boolean datatype by default.
/// It supports the standard boolean representations in XSD:
/// - 'true' or '1' for boolean true
/// - 'false' or '0' for boolean false
///
/// Values are processed case-insensitively, so 'TRUE', 'True', and 'true' are all
/// valid representations of the boolean value true.
///
/// This deserializer is pre-registered in the default registry and is automatically
/// used for deserializing boolean literals in RDF data.
///
/// Example:
/// ```dart
/// // Default usage - accepts xsd:boolean
/// final boolDeserializer = BoolDeserializer();
///
/// // Custom datatype
/// final customDeserializer = BoolDeserializer(
///   datatype: IriTerm('http://example.org/custom-boolean')
/// );
/// ```
final class BoolDeserializer extends BaseRdfLiteralTermDeserializer<bool> {
  /// Creates a new boolean deserializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:boolean)
  BoolDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? Xsd.boolean,
        convertFromLiteral: (term, _) {
          final value = term.value.toLowerCase();

          if (value == 'true' || value == '1') {
            return true;
          } else if (value == 'false' || value == '0') {
            return false;
          }

          throw DeserializationException(
            'Failed to parse boolean: ${term.value}',
          );
        },
      );
}

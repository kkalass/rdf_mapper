import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';

/// Standard deserializer for converting RDF integer literals to Dart integers.
///
/// This deserializer processes RDF literals with the xsd:integer datatype by default.
/// It can be configured to accept other numeric datatypes by providing a custom datatype.
///
/// This deserializer is pre-registered in the default registry and is automatically
/// used for deserializing integer literals in RDF data.
///
/// Example:
/// ```dart
/// // Default usage - accepts xsd:integer
/// final intDeserializer = IntDeserializer();
///
/// // Custom datatype - accepts xsd:byte
/// final byteDeserializer = IntDeserializer(datatype: Xsd.byte);
/// ```
final class IntDeserializer extends BaseRdfLiteralTermDeserializer<int> {
  /// Creates a new integer deserializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:integer)
  IntDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? Xsd.integer,
        convertFromLiteral: (term, _) => int.parse(term.value),
      );
}

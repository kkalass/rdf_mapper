import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

/// Standard serializer for converting Dart integers to RDF integer literals.
///
/// This serializer creates RDF literals with the xsd:integer datatype by default.
/// It can be customized to use a different datatype IRI if needed, which is useful
/// for specialized integer formats like byte, short, or long.
///
/// This serializer is pre-registered in the default registry and is automatically
/// used for serializing int values to RDF.
///
/// Example:
/// ```dart
/// // Default usage with xsd:integer datatype
/// final intSerializer = IntSerializer();
///
/// // Custom datatype for specialized integers
/// final byteSerializer = IntSerializer(
///   datatype: XsdTypes.byte
/// );
/// ```
final class IntSerializer extends BaseRdfLiteralTermSerializer<int> {
  /// Creates a new integer serializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:integer)
  IntSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.integer,
        convertToString: (i) => i.toString(),
      );
}

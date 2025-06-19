import 'package:rdf_core/rdf_core.dart';

import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';
import 'package:rdf_vocabularies/xsd.dart';

/// Standard serializer for converting Dart boolean values to RDF boolean literals.
///
/// This serializer creates RDF literals with the xsd:boolean datatype by default.
/// It converts Dart bool values to their string representation ('true' or 'false').
///
/// This serializer is pre-registered in the default registry and is automatically
/// used for serializing boolean values to RDF.
///
/// Example:
/// ```dart
/// // Default usage with xsd:boolean datatype
/// final boolSerializer = BoolSerializer();
///
/// // Custom boolean datatype
/// final customBoolSerializer = BoolSerializer(
///   datatype: IriTerm('http://example.org/custom-boolean')
/// );
/// ```
final class BoolSerializer extends BaseRdfLiteralTermSerializer<bool> {
  /// Creates a new boolean serializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:boolean)
  const BoolSerializer({IriTerm? datatype})
      : super(
          datatype: datatype ?? Xsd.boolean,
        );

  @override
  convertToString(b) => b.toString();
}

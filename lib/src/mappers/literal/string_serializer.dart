import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

/// Standard serializer for converting Dart strings to RDF string literals.
///
/// This serializer creates RDF literals with the xsd:string datatype by default.
/// It can be customized to use a different datatype IRI if needed, which is useful
/// for specialized string formats like language tags or custom string types.
///
/// Note: This serializer converts to a literal term, which can only exist as an
/// object in an RDF triple (subject-predicate-object). Strings alone cannot be
/// serialized as complete RDF documents. This serializer is typically used within
/// node mappers to handle string property values.
///
/// This serializer is pre-registered in the default registry and is automatically
/// used for serializing String values to RDF.
///
/// Example:
/// ```dart
/// // Default usage with xsd:string datatype
/// final stringSerializer = StringSerializer();
///
/// // Custom datatype for specialized strings
/// final customSerializer = StringSerializer(
///   datatype: IriTerm('http://example.org/custom-string-format')
/// );
/// ```
final class StringSerializer extends BaseRdfLiteralTermSerializer<String> {
  /// Creates a new string serializer with an optional custom datatype.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:string)
  StringSerializer({IriTerm? datatype})
    : super(datatype: datatype ?? Xsd.string, convertToString: (s) => s);
}

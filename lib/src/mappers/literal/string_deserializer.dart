import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

/// Standard deserializer for converting RDF string literals to Dart strings.
///
/// This deserializer processes RDF literals with the xsd:string datatype by default.
/// It can be configured to also accept literals with language tags (rdf:langString),
/// or to use a completely different datatype IRI.
///
/// This deserializer is pre-registered in the default registry and is automatically
/// used for deserializing string literals in RDF data.
///
/// Example:
/// ```dart
/// // Default usage - accepts only xsd:string
/// final stringDeserializer = StringDeserializer();
///
/// // Accept both plain strings and language-tagged strings
/// final flexibleDeserializer = StringDeserializer(acceptLangString: true);
///
/// // Custom datatype
/// final customDeserializer = StringDeserializer(
///   datatype: IriTerm('http://example.org/custom-string-format')
/// );
/// ```
final class StringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm _datatype;
  final bool _acceptLangString;

  /// Creates a StringDeserializer with customizable behavior.
  ///
  /// @param datatype Optional custom datatype IRI (defaults to xsd:string)
  /// @param acceptLangString When true, also accepts literals with rdf:langString datatype
  StringDeserializer({IriTerm? datatype, bool acceptLangString = false})
    : _datatype = datatype ?? XsdTypes.string,
      _acceptLangString = acceptLangString;

  /// Converts an RDF literal term to a Dart string.
  ///
  /// This implementation checks that the literal has an acceptable datatype
  /// (either the configured datatype or rdf:langString if acceptLangString is true),
  /// then returns the literal's lexical value.
  ///
  /// @param term The literal term to convert
  /// @param context The deserialization context (unused in this implementation)
  /// @return The string value of the literal
  /// @throws Exception if the literal has an incompatible datatype
  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    final isExpectedDatatype = term.datatype == _datatype;
    final isLangString =
        _acceptLangString && term.datatype == RdfTypes.langString;

    if (!isExpectedDatatype && !isLangString) {
      throw Exception(
        'Expected datatype ${_datatype.iri} but got ${term.datatype.iri}',
      );
    }

    return term.value;
  }
}

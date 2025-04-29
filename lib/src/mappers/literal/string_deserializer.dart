import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/deserializers/literal_term_deserializer.dart';

/// Deserializer for string literals in RDF.
///
/// By default, it only accepts literals with xsd:string datatype.
/// When [acceptLangString] is true, it will also accept literals with rdf:langString datatype.
final class StringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm _datatype;
  final bool _acceptLangString;

  /// Creates a StringDeserializer with optional datatype override
  ///
  /// When [acceptLangString] is true, both xsd:string and rdf:langString will be accepted.
  /// If [datatype] is provided, it overrides the default xsd:string datatype.
  StringDeserializer({IriTerm? datatype, bool acceptLangString = false})
    : _datatype = datatype ?? XsdTypes.string,
      _acceptLangString = acceptLangString;

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

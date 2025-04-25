import 'package:rdf_core/constants/rdf_constants.dart';
import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:solid_task/ext/rdf_orm/deserialization_context.dart';
import 'package:solid_task/ext/rdf_orm/rdf_literal_term_deserializer.dart';

/// Deserializer for string literals in RDF.
///
/// By default, it only accepts literals with xsd:string datatype.
/// When [acceptLangString] is true, it will also accept literals with rdf:langString datatype.
final class StringDeserializer implements RdfLiteralTermDeserializer<String> {
  final IriTerm _datatype;
  final bool _acceptLangString;

  /// Creates a StringDeserializer with optional datatype override
  ///
  /// When [acceptLangString] is true, both xsd:string and rdf:langString will be accepted.
  /// If [datatype] is provided, it overrides the default xsd:string datatype.
  StringDeserializer({IriTerm? datatype, bool acceptLangString = false})
    : _datatype = datatype ?? XsdConstants.stringIri,
      _acceptLangString = acceptLangString;

  @override
  String fromLiteralTerm(LiteralTerm term, DeserializationContext context) {
    final isExpectedDatatype = term.datatype == _datatype;
    final isLangString =
        _acceptLangString && term.datatype == RdfConstants.langStringIri;

    if (!isExpectedDatatype && !isLangString) {
      throw Exception(
        'Expected datatype ${_datatype.iri} but got ${term.datatype.iri}',
      );
    }

    return term.value;
  }
}

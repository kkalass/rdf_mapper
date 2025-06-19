import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/rdf.dart';
import 'package:rdf_vocabularies/xsd.dart';

final class StringMapper extends BaseRdfLiteralTermMapper<String> {
  final bool _acceptLangString;

  const StringMapper([IriTerm? datatype, bool acceptLangString = false])
      : _acceptLangString = acceptLangString,
        super(datatype: datatype ?? Xsd.string);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    final isExpectedDatatype = term.datatype == datatype;
    final isLangString = _acceptLangString && term.datatype == Rdf.langString;

    if (!isExpectedDatatype && !isLangString) {
      throw Exception(
        'Expected datatype ${datatype.iri} but got ${term.datatype.iri}',
      );
    }

    return convertFromLiteral(term, context);
  }

  @override
  String convertFromLiteral(LiteralTerm term, DeserializationContext context) {
    return term.value;
  }

  @override
  convertToString(s) => s;
}

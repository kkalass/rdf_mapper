import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

final class StringMapper extends BaseRdfLiteralTermMapper<String> {
  final bool _acceptLangString;

  const StringMapper([IriTerm? datatype, bool acceptLangString = false])
      : _acceptLangString = acceptLangString,
        super(datatype: datatype ?? Xsd.string);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    final isExpectedDatatype = term.datatype == datatype;
    final isLangString = _acceptLangString && term.datatype == Rdf.langString;

    if (!bypassDatatypeCheck && !isExpectedDatatype && !isLangString) {
      if (!isExpectedDatatype) {
        throw DeserializerDatatypeMismatchException(
            'Failed to parse: ${term.value}. ',
            actual: term.datatype,
            expected: datatype,
            targetType: String);
      }
      throw Exception(
        'Expected datatype ${datatype.value} but got ${term.datatype.value}',
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

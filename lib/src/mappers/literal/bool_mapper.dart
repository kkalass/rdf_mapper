import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/xsd.dart';

class BoolMapper extends BaseRdfLiteralTermMapper<bool> {
  const BoolMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.boolean,
        );

  @override
  convertFromLiteral(term, _) {
    final value = term.value.toLowerCase();

    if (value == 'true' || value == '1') {
      return true;
    } else if (value == 'false' || value == '0') {
      return false;
    }

    throw DeserializationException(
      'Failed to parse boolean: ${term.value}',
    );
  }

  @override
  convertToString(b) => b.toString();
}

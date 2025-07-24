import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

final class IntMapper extends BaseRdfLiteralTermMapper<int> {
  const IntMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.integer,
        );

  @override
  convertFromLiteral(term, _) => int.parse(term.value);

  @override
  convertToString(i) => i.toString();
}

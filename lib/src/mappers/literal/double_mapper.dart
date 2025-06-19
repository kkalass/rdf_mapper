import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/xsd.dart';

final class DoubleMapper extends BaseRdfLiteralTermMapper<double> {
  const DoubleMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.decimal,
        );

  @override
  convertFromLiteral(term, context) => double.parse(term.value);

  @override
  convertToString(d) => d.toString();
}

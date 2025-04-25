import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_deserializer.dart';

final class DoubleDeserializer extends BaseRdfLiteralTermDeserializer<double> {
  DoubleDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdConstants.decimalIri,
        convertFromLiteral: (term, _) => double.parse(term.value),
      );
}

import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_serializer.dart';

final class StringSerializer extends BaseRdfLiteralTermSerializer<String> {
  StringSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdConstants.stringIri,
        convertToString: (s) => s,
      );
}

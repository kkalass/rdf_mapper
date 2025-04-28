import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_serializer.dart';

final class IntSerializer extends BaseRdfLiteralTermSerializer<int> {
  IntSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.integer,
        convertToString: (i) => i.toString(),
      );
}

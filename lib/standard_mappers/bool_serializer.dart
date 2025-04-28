import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_serializer.dart';

final class BoolSerializer extends BaseRdfLiteralTermSerializer<bool> {
  BoolSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.boolean,
        convertToString: (b) => b.toString(),
      );
}

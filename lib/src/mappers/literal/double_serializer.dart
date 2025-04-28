import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

final class DoubleSerializer extends BaseRdfLiteralTermSerializer<double> {
  DoubleSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.decimal,
        convertToString: (d) => d.toString(),
      );
}

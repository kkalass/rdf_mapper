import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';

final class DoubleDeserializer extends BaseRdfLiteralTermDeserializer<double> {
  DoubleDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.decimal,
        convertFromLiteral: (term, _) => double.parse(term.value),
      );
}

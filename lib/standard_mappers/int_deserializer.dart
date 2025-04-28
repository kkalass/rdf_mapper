import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_deserializer.dart';

final class IntDeserializer extends BaseRdfLiteralTermDeserializer<int> {
  IntDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.integer,
        convertFromLiteral: (term, _) => int.parse(term.value),
      );
}

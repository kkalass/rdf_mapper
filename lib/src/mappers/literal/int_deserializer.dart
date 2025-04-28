import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';

final class IntDeserializer extends BaseRdfLiteralTermDeserializer<int> {
  IntDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.integer,
        convertFromLiteral: (term, _) => int.parse(term.value),
      );
}

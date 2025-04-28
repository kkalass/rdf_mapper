import 'package:rdf_core/vocab/vocab.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_deserializer.dart';

final class BoolDeserializer extends BaseRdfLiteralTermDeserializer<bool> {
  BoolDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.boolean,
        convertFromLiteral: (term, _) {
          final value = term.value.toLowerCase();

          if (value == 'true' || value == '1') {
            return true;
          } else if (value == 'false' || value == '0') {
            return false;
          }

          throw DeserializationException(
            'Failed to parse boolean: ${term.value}',
          );
        },
      );
}

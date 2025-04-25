import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:solid_task/ext/rdf_orm/exceptions/deserialization_exception.dart';
import 'package:solid_task/ext/rdf_orm/standard_mappers/base_rdf_literal_term_deserializer.dart';

final class BoolDeserializer extends BaseRdfLiteralTermDeserializer<bool> {
  BoolDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdConstants.booleanIri,
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

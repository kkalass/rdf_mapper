import 'package:rdf_core/constants/xsd_constants.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/standard_mappers/base_rdf_literal_term_deserializer.dart';

final class DateTimeDeserializer
    extends BaseRdfLiteralTermDeserializer<DateTime> {
  DateTimeDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdConstants.dateTimeIri,
        convertFromLiteral: (term, _) => DateTime.parse(term.value).toUtc(),
      );
}

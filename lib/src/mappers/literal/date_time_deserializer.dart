import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';

final class DateTimeDeserializer
    extends BaseRdfLiteralTermDeserializer<DateTime> {
  DateTimeDeserializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.dateTime,
        convertFromLiteral: (term, _) => DateTime.parse(term.value).toUtc(),
      );
}

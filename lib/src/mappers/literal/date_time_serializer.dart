import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

final class DateTimeSerializer extends BaseRdfLiteralTermSerializer<DateTime> {
  DateTimeSerializer({IriTerm? datatype})
    : super(
        datatype: datatype ?? XsdTypes.dateTime,
        convertToString: (dateTime) => dateTime.toUtc().toIso8601String(),
      );
}

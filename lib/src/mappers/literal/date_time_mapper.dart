import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

final class DateTimeMapper extends BaseRdfLiteralTermMapper<DateTime> {
  const DateTimeMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.dateTime,
        );

  @override
  convertFromLiteral(term, _) => DateTime.parse(term.value).toUtc();

  @override
  convertToString(dateTime) => dateTime.toUtc().toIso8601String();
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';

final class StringSerializer extends BaseRdfLiteralTermSerializer<String> {
  StringSerializer({IriTerm? datatype})
    : super(datatype: datatype ?? XsdTypes.string, convertToString: (s) => s);
}

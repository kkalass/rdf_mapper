import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';

final class IriFullDeserializer implements RdfIriTermDeserializer<String> {
  @override
  fromIriTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
  }
}

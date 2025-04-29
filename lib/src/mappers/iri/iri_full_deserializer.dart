import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/deserializers/iri_term_deserializer.dart';

final class IriFullDeserializer implements IriTermDeserializer<String> {
  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
  }
}

import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/serialization_context.dart';

final class IriFullSerializer implements RdfIriTermSerializer<String> {
  @override
  toIriTerm(String iri, SerializationContext context) {
    return IriTerm(iri);
  }
}

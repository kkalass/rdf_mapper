import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

final class IriFullSerializer implements IriTermSerializer<String> {
  @override
  toRdfTerm(String iri, SerializationContext context) {
    return IriTerm(iri);
  }
}

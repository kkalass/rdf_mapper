import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

abstract interface class RdfIriTermDeserializer<T> {
  T fromIriTerm(IriTerm term, DeserializationContext context);
}

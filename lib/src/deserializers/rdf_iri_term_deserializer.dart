import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

abstract interface class RdfIriTermDeserializer<T> {
  T fromIriTerm(IriTerm term, DeserializationContext context);
}

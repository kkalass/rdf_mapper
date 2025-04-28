import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

abstract interface class RdfSubjectDeserializer<T> {
  IriTerm get typeIri;
  T fromIriTerm(IriTerm term, DeserializationContext context);
}

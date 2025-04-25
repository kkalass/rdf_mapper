import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';

abstract interface class RdfSubjectDeserializer<T> {
  IriTerm get typeIri;
  T fromIriTerm(IriTerm term, DeserializationContext context);
}

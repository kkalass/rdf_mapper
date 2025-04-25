import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/serialization_context.dart';

abstract interface class RdfSubjectSerializer<T> {
  IriTerm get typeIri;
  (RdfSubject, List<Triple>) toRdfSubject(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

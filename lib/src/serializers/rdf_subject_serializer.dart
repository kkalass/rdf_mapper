import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_core/graph/triple.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

abstract interface class RdfSubjectSerializer<T> {
  /// The IRI of the type of the subject.
  /// This is used to determine the type of the subject when serializing it to RDF.
  /// If you want to not associate a type with the subject, return null - you
  /// can choose to do so both for BlankNodeTerm and IriTerm.
  ///
  /// But it is considered a good practice to always provide a type IRI.
  IriTerm? get typeIri;

  (RdfSubject, List<Triple>) toRdfSubject(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

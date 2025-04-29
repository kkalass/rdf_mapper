import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

abstract interface class SubjectDeserializer<T> implements Deserializer<T> {
  /// The IRI of the RDF type this deserializer can handle.
  /// This is used for type-based lookup of deserializers.
  IriTerm get typeIri;

  /// Converts an IRI term to an object of type T.
  /// @param term The IRI term to convert
  /// @param context The deserialization context providing access to the graph
  /// @return The resulting object
  T fromRdfTerm(IriTerm term, DeserializationContext context);
}

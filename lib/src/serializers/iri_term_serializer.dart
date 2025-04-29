import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Serializes a Dart object to an RDF IRI term.
///
/// Implementations convert specific Dart types to IRI terms,
/// which are used to represent resources in RDF graphs.
abstract interface class IriTermSerializer<T> implements Serializer<T> {
  /// Converts a value to an IRI term.
  ///
  /// @param value The value to convert
  /// @return The resulting IRI term
  IriTerm toRdfTerm(T value, SerializationContext context);
}

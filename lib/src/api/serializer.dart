import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

/// Base marker interface for all RDF serializers.
///
/// This serves as a semantic marker to group all serializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
///
/// This allows for type-safety when managing collections of serializers.
sealed class Serializer<T> {}

/// Groups those serializers that serialize a Dart object to an RDF term
/// (i.e. IriTerm or LiteralTerm) and not to a list of Triples.
sealed class TermSerializer<T> extends Serializer<T> {}

/// Serializes a Dart object to an RDF IRI term.
///
/// Implementations convert specific Dart types to IRI terms,
/// which are used to represent resources in RDF graphs.
abstract interface class IriTermSerializer<T> implements TermSerializer<T> {
  /// Converts a value to an IRI term.
  ///
  /// @param value The value to convert
  /// @return The resulting IRI term
  IriTerm toRdfTerm(T value, SerializationContext context);
}

/// Serializes a Dart object to an RDF literal term.
///
/// Implementations convert specific Dart types to literal terms,
/// which are used to represent literal values in RDF graphs.
abstract interface class LiteralTermSerializer<T> implements TermSerializer<T> {
  /// Converts a value to a literal term.
  ///
  /// @param value The value to convert
  /// @return The resulting literal term
  LiteralTerm toRdfTerm(T value, SerializationContext context);
}

sealed class NodeSerializer<T> extends Serializer<T> {
  /// The IRI of the type of the subject.
  /// This is used to determine the type of the subject when serializing it to RDF.
  /// If you want to not associate a type with the subject, return null - you
  /// can choose to do so both for BlankNodeTerm and IriTerm.
  ///
  /// But it is considered a good practice to always provide a type IRI.
  IriTerm? get typeIri;

  (RdfSubject, List<Triple>) toRdfNode(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

abstract interface class BlankNodeSerializer<T> implements NodeSerializer<T> {
  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

abstract interface class IriNodeSerializer<T> implements NodeSerializer<T> {
  @override
  (IriTerm, List<Triple>) toRdfNode(
    T value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

/// Base marker interface for all RDF deserializers.
///
/// This serves as a semantic marker to group all deserializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
///
/// This allows for type-safety when managing collections of deserializers.
sealed class Deserializer<T> {}

/// Deserializes an RDF blank node term to a Dart object.
///
/// Implementations convert blank node terms to specific Dart types,
/// enabling the transformation of anonymous RDF resources into domain objects.
abstract interface class BlankNodeTermDeserializer<T>
    implements Deserializer<T> {
  /// Converts a blank node term to a value.
  ///
  /// @param term The blank node term to convert
  /// @param context The deserialization context, providing access to the graph
  /// @return The resulting value
  T fromRdfTerm(BlankNodeTerm term, DeserializationContext context);
}

/// Deserializes an RDF IRI term to a Dart object.
///
/// Implementations convert IRI terms to specific Dart types,
/// enabling the transformation of RDF resources into domain objects.
abstract interface class IriTermDeserializer<T> implements Deserializer<T> {
  /// Converts an IRI term to a value.
  ///
  /// @param term The IRI term to convert
  /// @return The resulting value
  T fromRdfTerm(IriTerm term, DeserializationContext context);
}

/// Deserializes an RDF literal term to a Dart object.
///
/// Implementations convert literal terms to specific Dart types,
/// enabling the transformation of RDF literal values into domain objects.
abstract interface class LiteralTermDeserializer<T> implements Deserializer<T> {
  /// Converts a literal term to a value.
  ///
  /// @param term The literal term to convert
  /// @return The resulting value
  T fromRdfTerm(LiteralTerm term, DeserializationContext context);
}

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

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Base marker interface for all RDF deserializers.
///
/// This serves as a semantic marker to group all deserializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
///
/// This allows for type-safety when managing collections of deserializers.
sealed class Deserializer<T> {}

sealed class TermDeserializer<T> extends Deserializer<T> {}

/// Deserializes an RDF IRI term to a Dart object.
///
/// Implementations convert IRI terms to specific Dart types,
/// enabling the transformation of RDF resources into domain objects.
abstract interface class IriTermDeserializer<T> implements TermDeserializer<T> {
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
abstract interface class LiteralTermDeserializer<T>
    implements TermDeserializer<T> {
  /// Converts a literal term to a value.
  ///
  /// @param term The literal term to convert
  /// @return The resulting value
  T fromRdfTerm(LiteralTerm term, DeserializationContext context);
}

sealed class NodeDeserializer<T> extends Deserializer<T> {
  /// The IRI of the RDF type this deserializer can handle.
  /// This is used for type-based lookup of deserializers.
  /// Note that this is optional since it is legal (but not adviced)
  /// to not associate a RDF type with a IriTerm or BlankNodeTerm.
  ///
  /// Beware though, that deserialization from a graph without a type
  /// will only work if you deserialize explicitly a specific IriTerm or
  /// BlankNodeTerm to a specific dart type, not if you use the generic deserialization [RdfMapper.deserializeAll].
  IriTerm? get typeIri;
}

/// Deserializes an RDF blank node term to a Dart object, using that part of the graph where the blank node is the subject.
///
/// Implementations convert blank node terms to specific Dart types,
/// enabling the transformation of anonymous RDF resources into domain objects.
abstract interface class BlankNodeDeserializer<T>
    implements NodeDeserializer<T> {
  /// Converts a blank node term to a value.
  ///
  /// @param term The blank node term to convert
  /// @param context The deserialization context, providing access to the graph
  /// @return The resulting value
  T fromRdfNode(BlankNodeTerm term, DeserializationContext context);
}

abstract interface class IriNodeDeserializer<T> implements NodeDeserializer<T> {
  /// Converts an IRI term to an object of type T.
  /// @param term The IRI term to convert
  /// @param context The deserialization context providing access to the graph
  /// @return The resulting object
  T fromRdfNode(IriTerm term, DeserializationContext context);
}

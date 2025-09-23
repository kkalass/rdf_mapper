import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when no deserializer is registered for a specific type or RDF type IRI.
///
/// This exception occurs during deserialization when the system needs to convert an RDF node
/// to a Dart object, but no appropriate deserializer has been registered to handle the conversion.
///
/// There are two scenarios where this exception is thrown:
/// 1. When attempting to deserialize to a specific Dart type but no deserializer is registered for it
/// 2. When encountering an RDF type IRI (from an rdf:type predicate) that has no registered deserializer
///
/// The exception contains information about which deserializer type was sought (e.g., GlobalResourceDeserializer)
/// and the target type that couldn't be handled.
class DeserializerNotFoundException extends RdfMappingException {
  final String _t;
  final String _serializerType;

  /// Creates a new exception for when a deserializer for a Dart type is not found.
  ///
  /// @param serializerType The type of deserializer that was being looked up
  /// @param type The Dart type for which no deserializer was found
  DeserializerNotFoundException(this._serializerType, Type type)
      : _t = type.toString();

  /// Creates a new exception for when a deserializer for an RDF type IRI is not found.
  ///
  /// @param serializerType The type of deserializer that was being looked up
  /// @param type The RDF type IRI for which no deserializer was found
  DeserializerNotFoundException.forTypeIri(this._serializerType, IriTerm type)
      : _t = type.value;

  @override
  String toString() =>
      'DeserializerNotFoundException: (No $_serializerType Deserializer found for $_t)';
}

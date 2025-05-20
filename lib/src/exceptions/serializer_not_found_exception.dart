import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when no serializer is registered for a specific Dart type.
///
/// This exception occurs during serialization when the system needs to convert a Dart object
/// to an RDF representation, but no appropriate serializer has been registered to handle
/// the conversion for the object's type.
///
/// The exception contains information about which serializer type was sought (e.g., IriTermSerializer,
/// ResourceSerializer) and the Dart type that couldn't be handled.
class SerializerNotFoundException extends RdfMappingException {
  final Type _t;
  final String _serializerType;

  /// Creates a new exception for when a serializer for a Dart type is not found.
  ///
  /// @param serializerType The type of serializer that was being looked up
  /// @param type The Dart type for which no serializer was found
  SerializerNotFoundException(this._serializerType, this._t);

  @override
  String toString() =>
      'SerializerNotFoundException: (No $_serializerType Serializer found for ${_t.toString()})';
}

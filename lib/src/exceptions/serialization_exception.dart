import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when errors occur during the RDF serialization process.
///
/// This exception represents general serialization failures that don't fit into more
/// specific exception categories. It can indicate issues such as invalid object structures,
/// circular references that can't be resolved, or other problems preventing proper
/// conversion to RDF.
///
/// For more specific serialization errors, see:
/// - [SerializerNotFoundException]: When no serializer is registered for a type
class SerializationException extends RdfMappingException {
  /// Creates a new serialization exception with an optional error message.
  ///
  /// @param message Text describing the serialization error
  SerializationException([super.message]);
}

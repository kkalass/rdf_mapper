import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when errors occur during the RDF deserialization process.
///
/// This exception represents general deserialization failures that don't fit into more
/// specific exception categories. It can indicate issues such as invalid RDF structure,
/// data type conversion problems, or inconsistencies between the RDF data and
/// expected object model.
///
/// For more specific deserialization errors, see:
/// - [DeserializerNotFoundException]: When no deserializer is registered for a type
/// - [PropertyValueNotFoundException]: When a required property is missing
/// - [TooManyPropertyValuesException]: When too many values exist for a single-valued property
class DeserializationException extends RdfMappingException {
  /// Creates a new deserialization exception with an optional error message.
  ///
  /// @param message Text describing the deserialization error
  DeserializationException([super.message]);
}

import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

/// Exception thrown when no deserializable subjects of the required type are found.
class NoDeserializableSubjectsException extends DeserializationException {
  NoDeserializableSubjectsException(String message) : super(message);
}

/// Exception thrown when multiple deserializable subjects are found but only one is expected.
class TooManyDeserializableSubjectsException extends DeserializationException {
  TooManyDeserializableSubjectsException(String message) : super(message);
}

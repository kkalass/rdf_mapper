import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

/// A flexible IRI term deserializer that uses a custom extraction function.
///
/// This deserializer provides a convenient way to create custom IRI term deserializers
/// without implementing the full interface. It takes an extraction function that defines
/// how to convert from an IRI term to the target type.
///
/// This is particularly useful for types that can be constructed from an IRI but require
/// custom parsing logic beyond simply using the IRI string.
///
/// Example usage:
/// ```dart
/// final customUriDeserializer = ExtractingIriTermDeserializer<Uri>(
///   extract: (term, _) => Uri.parse(term.value),
/// );
/// ```
class ExtractingIriTermDeserializer<T> implements IriTermDeserializer<T> {
  final T Function(IriTerm, DeserializationContext) _extract;

  /// Creates a new IRI term deserializer with a custom extraction function.
  ///
  /// The extraction function receives the IRI term and deserialization context,
  /// and should return an instance of type T. Any exceptions thrown during extraction
  /// will be wrapped in a DeserializationException.
  ///
  /// @param extract The function that converts an IRI term to an instance of T
  ExtractingIriTermDeserializer({
    required T Function(IriTerm, DeserializationContext) extract,
  }) : _extract = extract;

  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    try {
      return _extract(term, context);
    } on DeserializationException {
      rethrow;
    } catch (e) {
      throw DeserializationException(
        'Failed to parse Iri Id from ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }
}

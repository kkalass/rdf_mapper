import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/exceptions/serialization_exception.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

/// Serializer that converts a local identifier to a complete IRI term.
///
/// This serializer is designed for scenarios where objects store only the local part
/// of an identifier (e.g., "1234" or "item42") rather than full IRIs. It uses an
/// expansion function to convert these local identifiers into complete IRIs.
///
/// The serializer verifies that the input is truly a local identifier by ensuring
/// it doesn't contain slashes, which would indicate it's already a path or full IRI.
///
/// Example usage:
/// ```dart
/// // Create a serializer that expands IDs to a specific namespace
/// final personIdSerializer = IriIdSerializer(
///   expand: (id, _) => const IriTerm('http://example.org/people/$id'),
/// );
///
/// // Using the serializer to convert "1234" to "http://example.org/people/1234"
/// final iriTerm = personIdSerializer.toRdfTerm("1234", context);
/// ```
class IriIdSerializer implements IriTermSerializer<String> {
  final IriTerm Function(String, SerializationContext context) _expand;

  /// Creates a new IRI ID serializer with the specified expansion function.
  ///
  /// The expansion function receives a local identifier string and the serialization context,
  /// and should return a complete IRI term.
  ///
  /// @param expand Function that expands a local ID to a complete IRI term
  IriIdSerializer({
    required IriTerm Function(String, SerializationContext context) expand,
  }) : _expand = expand;

  /// Converts a local identifier to an IRI term.
  ///
  /// @param id The local identifier string
  /// @param context The serialization context
  /// @return An IRI term created by applying the expansion function to the identifier
  /// @throws SerializationException if the identifier contains slashes, suggesting it's not a local ID
  @override
  toRdfTerm(String id, SerializationContext context) {
    assert(!id.contains("/"));
    if (id.contains("/")) {
      throw SerializationException('Expected an Id, not a full IRI: $id ');
    }
    return _expand(id, context);
  }
}

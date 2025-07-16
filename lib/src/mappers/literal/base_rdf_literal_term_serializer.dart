import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

/// Base implementation for literal term serializers that simplifies the creation of custom serializers.
///
/// This class provides a reusable implementation of the [LiteralTermSerializer] interface
/// for converting Dart values to RDF literal terms. It handles the common pattern of:
/// 1. Converting a value to its string representation
/// 2. Creating a literal term with the appropriate datatype
///
/// To create a serializer for a specific type:
/// 1. Extend this class and provide the appropriate XSD datatype
/// 2. Optionally, provide a custom conversion function if toString() is not sufficient
///
/// Example implementation for a Date serializer:
/// ```dart
/// final class DateSerializer extends BaseRdfLiteralTermSerializer<DateTime> {
///   DateSerializer()
///     : super(
///         datatype: Xsd.date,
///         convertToString: (date) => date.toIso8601String().split('T')[0],
///       );
/// }
/// ```
///
/// This abstraction significantly reduces the boilerplate required for implementing
/// serializers for simple value types.
abstract class BaseRdfLiteralTermSerializer<T>
    implements LiteralTermSerializer<T> {
  final IriTerm _datatype;

  /// Creates a new base literal term serializer.
  ///
  /// @param datatype The XSD or custom datatype IRI for the serialized literals
  const BaseRdfLiteralTermSerializer({required IriTerm datatype})
      : _datatype = datatype;

  String convertToString(T value);

  /// Converts a value to an RDF literal term.
  ///
  /// This implementation:
  /// 1. Converts the value to a string using the provided conversion function
  /// 2. Creates a literal term with that string value and the configured datatype
  ///
  /// @param value The value to convert
  /// @param context The serialization context (unused in this implementation)
  /// @return A literal term representing the value
  @override
  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    return LiteralTerm(convertToString(value), datatype: _datatype);
  }
}

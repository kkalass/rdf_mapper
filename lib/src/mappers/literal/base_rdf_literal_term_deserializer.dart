import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

/// Base implementation for literal term deserializers that simplifies the creation of custom deserializers.
///
/// This class provides a reusable implementation of the [LiteralTermDeserializer] interface
/// for converting RDF literal terms to Dart values. It handles the common pattern of:
/// 1. Validating that the literal has the expected datatype
/// 2. Converting the literal value to the target Dart type
/// 3. Providing proper error handling with descriptive messages
///
/// To create a deserializer for a specific type:
/// 1. Extend this class and provide the appropriate XSD datatype
/// 2. Provide a conversion function that transforms the literal into your target type
///
/// Example implementation for an Integer deserializer:
/// ```dart
/// final class IntDeserializer extends BaseRdfLiteralTermDeserializer<int> {
///   IntDeserializer()
///     : super(
///         datatype: Xsd.integer,
///         convertFromLiteral: (term, _) => int.parse(term.value),
///       );
/// }
/// ```
///
/// This abstraction significantly reduces the boilerplate required for implementing
/// deserializers for simple value types while providing consistent error handling.
abstract class BaseRdfLiteralTermDeserializer<T>
    implements LiteralTermDeserializer<T> {
  final IriTerm _datatype;
  final T Function(LiteralTerm term, DeserializationContext context)
      _convertFromLiteral;

  /// Creates a new base literal term deserializer.
  ///
  /// @param datatype The XSD or custom datatype IRI that this deserializer handles
  /// @param convertFromLiteral Function to convert from a literal term to the target type.
  ///        This function should throw an exception if the conversion fails.
  BaseRdfLiteralTermDeserializer({
    required IriTerm datatype,
    required T Function(LiteralTerm term, DeserializationContext context)
        convertFromLiteral,
  })  : _datatype = datatype,
        _convertFromLiteral = convertFromLiteral;

  /// Converts an RDF literal term to a value of type T.
  ///
  /// This implementation:
  /// 1. Verifies that the literal's datatype matches the expected datatype
  /// 2. Attempts to convert the literal value using the provided conversion function
  /// 3. Wraps any conversion errors in a descriptive DeserializationException
  ///
  /// @param term The literal term to convert
  /// @param context The deserialization context
  /// @return The converted value of type T
  /// @throws DeserializationException if the datatype doesn't match or conversion fails
  @override
  T fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    if (term.datatype != _datatype) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: The expected datatype is ${_datatype.iri} but the actual datatype in the Literal was ${term.datatype.iri}',
      );
    }
    try {
      return _convertFromLiteral(term, context);
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }
}

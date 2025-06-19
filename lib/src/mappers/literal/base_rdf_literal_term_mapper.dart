import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

abstract class BaseRdfLiteralTermMapper<T> implements LiteralTermMapper<T> {
  final IriTerm datatype;

  const BaseRdfLiteralTermMapper({
    required IriTerm datatype,
  }) : datatype = datatype;

  T convertFromLiteral(LiteralTerm term, DeserializationContext context);

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
    if (term.datatype != datatype) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: The expected datatype is ${datatype.iri} but the actual datatype in the Literal was ${term.datatype.iri}',
      );
    }
    try {
      return convertFromLiteral(term, context);
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }

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
    return LiteralTerm(convertToString(value), datatype: datatype);
  }
}

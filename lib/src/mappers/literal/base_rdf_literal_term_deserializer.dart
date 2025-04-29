import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

abstract class BaseRdfLiteralTermDeserializer<T>
    implements LiteralTermDeserializer<T> {
  final IriTerm _datatype;
  final T Function(LiteralTerm term, DeserializationContext context)
  _convertFromLiteral;

  BaseRdfLiteralTermDeserializer({
    required IriTerm datatype,
    required T Function(LiteralTerm term, DeserializationContext context)
    convertFromLiteral,
  }) : _datatype = datatype,
       _convertFromLiteral = convertFromLiteral;

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

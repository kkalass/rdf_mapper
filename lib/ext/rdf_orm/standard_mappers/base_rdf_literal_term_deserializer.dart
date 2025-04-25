import 'package:rdf_core/graph/rdf_term.dart';
import 'package:solid_task/ext/rdf_orm/deserialization_context.dart';
import 'package:solid_task/ext/rdf_orm/exceptions/deserialization_exception.dart';
import 'package:solid_task/ext/rdf_orm/rdf_literal_term_deserializer.dart';

abstract class BaseRdfLiteralTermDeserializer<T>
    implements RdfLiteralTermDeserializer<T> {
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
  T fromLiteralTerm(LiteralTerm term, DeserializationContext context) {
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

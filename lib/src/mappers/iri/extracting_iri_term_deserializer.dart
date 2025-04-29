import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';

class ExtractingIriTermDeserializer<T> implements IriTermDeserializer<T> {
  final T Function(IriTerm, DeserializationContext) _extract;

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
        'Failed to parse Iri Id from ${T.toString()}: ${term.iri}. Error: $e',
      );
    }
  }
}

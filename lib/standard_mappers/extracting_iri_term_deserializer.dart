import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';

class ExtractingIriTermDeserializer<T> implements RdfIriTermDeserializer<T> {
  final T Function(IriTerm, DeserializationContext) _extract;

  ExtractingIriTermDeserializer({
    required T Function(IriTerm, DeserializationContext) extract,
  }) : _extract = extract;

  @override
  fromIriTerm(IriTerm term, DeserializationContext context) {
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

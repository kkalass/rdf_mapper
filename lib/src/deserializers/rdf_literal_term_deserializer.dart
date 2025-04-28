import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

abstract class RdfLiteralTermDeserializer<T> {
  T fromLiteralTerm(LiteralTerm term, DeserializationContext context);
}

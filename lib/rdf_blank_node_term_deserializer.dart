import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';

abstract class RdfBlankNodeTermDeserializer<T> {
  T fromBlankNodeTerm(BlankNodeTerm term, DeserializationContext context);
}

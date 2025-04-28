import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';

abstract class RdfBlankNodeTermDeserializer<T> {
  T fromBlankNodeTerm(BlankNodeTerm term, DeserializationContext context);
}

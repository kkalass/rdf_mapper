import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/serialization_context.dart';

abstract class RdfLiteralTermSerializer<T> {
  LiteralTerm toLiteralTerm(T value, SerializationContext context);
}

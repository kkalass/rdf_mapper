import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

abstract class RdfLiteralTermSerializer<T> {
  LiteralTerm toLiteralTerm(T value, SerializationContext context);
}

import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/serialization_context.dart';

abstract interface class RdfIriTermSerializer<T> {
  IriTerm toIriTerm(T value, SerializationContext context);
}
